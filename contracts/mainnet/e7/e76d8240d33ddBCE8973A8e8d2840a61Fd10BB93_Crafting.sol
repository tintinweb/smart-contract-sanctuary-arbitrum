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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
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

// SPDX-License-Identifier: Unlicensed

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
uint256 constant ACTION_ADVENTURER_BATTLE_V3_OPPONENT = 1007;
uint256 constant ACTION_ADVENTURER_TRAINING = 1008;
uint256 constant ACTION_ADVENTURER_TRANSCENDENCE = 1009;
uint256 constant ACTION_ADVENTURER_MINT_MULTIPASS = 1010;

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

uint256 constant ACTION_ARMORY_STAKE_CITY = 2061;
uint256 constant ACTION_ARMORY_UNSTAKE_CITY = 2062;

uint256 constant ACTION_ARMORY_STAKE_MONUMENT = 2071;
uint256 constant ACTION_ARMORY_UNSTAKE_MONUMENT = 2072;

uint256 constant ACTION_ARMORY_STAKE_ANIMA_CHAMBER = 2081;
uint256 constant ACTION_ARMORY_UNSTAKE_ANIMA_CHAMBER = 2082;
uint256 constant ACTION_ANIMA_STAKING_COLLECT_STAKER_REWARDS = 2083;
uint256 constant ACTION_ANIMA_STAKING_COLLECT_REALMER_REWARDS = 2084;

uint256 constant ACTION_REALM_COLLECT_COLLECTIBLES = 4001;
uint256 constant ACTION_REALM_BUILD_LAB = 4011;
uint256 constant ACTION_REALM_BUILD_MONUMENT = 4012;
uint256 constant ACTION_REALM_BUILD_CITY = 4013;

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IActionDemandAverageStorage {
  function getDemandBatch(
    uint _action,
    uint[] calldata _subGroups
  ) external returns (uint256[] memory results);

  function getDemandViewBatch(
    uint _action,
    uint[] calldata _subGroups
  ) external view returns (uint256[] memory results);

  function getDemandPredictionBatch(
    uint _action,
    uint[] calldata _subGroups
  ) external view returns (uint256[] memory results);

  function increaseDemandBatch(
    uint _action,
    uint[] calldata _subGroups,
    uint[] calldata _deltas
  ) external;
}

// SPDX-License-Identifier: Unlicensed

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

  function checkAndMarkActionCompleteMany(
    address _sender,
    address[] calldata _tokenAddrs,
    uint256[] calldata _tokenIds,
    bytes32[][] calldata _proofs,
    uint256 _action,
    uint256[] calldata _minEpochs,
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

  function checkOwner(
    address _tokenAddr,
    uint256 _tokenId,
    bytes32[] calldata _proof
  ) external view returns (address);

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

  function checkOwnerBatch(
    address[] calldata _tokenAddrs,
    uint256[] calldata _tokenIds,
    bytes32[][] calldata _proofs
  ) external view returns (address[] memory);

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

  function checkIfEnoughEpochsElapsedBatch(
    address[] calldata _tokenAddrs,
    uint256[] calldata _tokenIds,
    uint256 _action,
    uint256[] calldata _minEpochs,
    uint128 _epochConfig
  ) external view;

  function getElapsedEpochs(
    address[] calldata _tokenAddrs,
    uint256[] calldata _tokenIds,
    uint256 _action,
    uint128 _epochConfig
  ) external view returns (uint[] memory result);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IGlobalActionIdStorage {
  function getAndIncrementNextId(uint256 action, uint increment) external returns (uint256);

  function getNextId(uint256 action) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";

interface ILastActionMarkerStorage {
  function setActionMarker(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _action,
    uint256 _marker
  ) external;

  function getActionMarker(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _action
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAdventurerData {
  function initData(
    address[] calldata _addresses,
    uint256[] calldata _ids,
    bytes32[][] calldata _proofs,
    uint256[] calldata _professions,
    uint256[][] calldata _points
  ) external;

  function baseProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function aovProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function extensionProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function createFor(
    address _addr,
    uint256 _id,
    uint256[] calldata _points
  ) external;

  function createFor(address _addr, uint256 _id, uint256 _archetype) external;

  function addToBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function addToAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function addToExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function base(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);

  function aov(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);

  function extension(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

uint constant ADVENTURER_DATA_BASE = 0;
uint constant ADVENTURER_DATA_AOV = 1;
uint constant ADVENTURER_DATA_EXTENSION = 2;

interface IBatchAdventurerData {
  function STORAGE(
    address _addr,
    uint256 _id,
    uint256 _type,
    uint256 _prop
  ) external view returns (uint24);

  function add(address _addr, uint256 _id, uint256 _type, uint256 _prop, uint256 _val) external;

  function addBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256[][] calldata _prop,
    uint256[][] calldata _val
  ) external;

  function addBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256 _val
  ) external;

  function addBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256[] calldata _val
  ) external;

  function update(address _addr, uint256 _id, uint256 _type, uint256 _prop, uint256 _val) external;

  function updateRaw(address _addr, uint256 _id, uint256 _type, uint24[10] calldata _val) external;

  function updateBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256[] calldata _val
  ) external;

  function updateBatchRaw(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint24[10][] calldata _val
  ) external;

  function remove(address _addr, uint256 _id, uint256 _type, uint256 _prop, uint256 _val) external;

  function removeBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256[][] calldata _prop,
    uint256[][] calldata _val
  ) external;

  function get(address _addr, uint256 _id, uint256 _type, uint256 _prop) external returns (uint256);

  function getRaw(address _addr, uint256 _id, uint256 _type) external returns (uint24[10] memory);

  function getMulti(
    address _addr,
    uint256 _id,
    uint256 _type,
    uint256[] calldata _prop
  ) external returns (uint256[] memory result);

  function getBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop
  ) external returns (uint256[] memory);

  function getBatchMulti(
    address[] calldata _addrs,
    uint256[] calldata _ids,
    uint256 _type,
    uint256[] calldata _props
  ) external returns (uint256[][] memory);

  function getRawBatch(
    address[] calldata _addrs,
    uint256[] calldata _ids,
    uint256 _type
  ) external returns (uint24[10][] memory result);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBatchAdventurerGateway {
  function checkAddress(address _addr, bytes32[] calldata _proof) external view;

  function checkAddressBatch(address[] calldata _addr, bytes32[][] calldata _proof) external view;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

library traits {
  uint256 public constant ADV_TRAIT_GROUP_BASE = 0;

  // Base, _type = 0
  uint256 public constant ADV_TRAIT_BASE_LEVEL = 0;
  uint256 public constant ADV_TRAIT_BASE_XP = 1;
  uint256 public constant ADV_TRAIT_BASE_STRENGTH = 2;
  uint256 public constant ADV_TRAIT_BASE_DEXTERITY = 3;
  uint256 public constant ADV_TRAIT_BASE_CONSTITUTION = 4;
  uint256 public constant ADV_TRAIT_BASE_INTELLIGENCE = 5;
  uint256 public constant ADV_TRAIT_BASE_WISDOM = 6;
  uint256 public constant ADV_TRAIT_BASE_CHARISMA = 7;
  uint256 public constant ADV_TRAIT_BASE_CLASS = 8;

  uint256 public constant ADV_TRAIT_GROUP_ADVANCED = 1;
  // Advanced, _type = 1
  uint256 public constant ADV_TRAIT_ADVANCED_ARCHETYPE = 0;
  uint256 public constant ADV_TRAIT_ADVANCED_PROFESSION = 1;
  uint256 public constant ADV_TRAIT_ADVANCED_TRAINING_POINTS = 2;

  // Base Ttraits
  // See AdventurerData.sol for details
  uint256 public constant LEGACY_ADV_BASE_TRAIT_XP = 0;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_XP_BROKEN = 1;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_STRENGTH = 2;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_DEXTERITY = 3;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_CONSTITUTION = 4;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_INTELLIGENCE = 5;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_WISDOM = 6;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_CHARISMA = 7;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_HP = 8;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_HP_USED = 9;

  // AoV Traits
  // See AdventurerData.sol for details
  uint256 public constant LEGACY_ADV_AOV_TRAIT_LEVEL = 0;
  uint256 public constant LEGACY_ADV_AOV_TRAIT_ARCHETYPE = 1;
  uint256 public constant LEGACY_ADV_AOV_TRAIT_CLASS = 2;
  uint256 public constant LEGACY_ADV_AOV_TRAIT_PROFESSION = 3;

  function baseTraitNames() public pure returns (string[10] memory) {
    return [
      "Level",
      "XP",
      "Strength",
      "Dexterity",
      "Constitution",
      "Intelligence",
      "Wisdom",
      "Charisma",
      "Class",
      ""
    ];
  }

  function advancedTraitNames() public pure returns (string[2] memory) {
    return ["Archetype", "Profession"];
  }

  function baseTraitName(uint256 traitId) public pure returns (string memory) {
    return baseTraitNames()[traitId];
  }

  function advancedTraitName(uint256 traitId) public pure returns (string memory) {
    return advancedTraitNames()[traitId];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Bound/IERC20Bound.sol";
import "./IAnima.sol";

import "../Manager/ManagerModifier.sol";

contract Anima is
  IAnima,
  ERC20,
  ERC20Burnable,
  ManagerModifier,
  ReentrancyGuard,
  Pausable
{
  //=======================================
  // Immutables
  //=======================================
  IERC20Bound public immutable BOUND;
  uint256 public immutable CAP;

  //=======================================
  // Constructor
  //=======================================
  constructor(
    address _manager,
    address _bound,
    uint256 _cap
  ) ERC20("Anima", "ANIMA") ManagerModifier(_manager) {
    BOUND = IERC20Bound(_bound);
    CAP = _cap;
  }

  //=======================================
  // External
  //=======================================
  function mintFor(
    address _for,
    uint256 _amount
  ) external override onlyTokenMinter {
    // Check amount doesn't exceed cap
    require(ERC20.totalSupply() + _amount <= CAP, "Anima: Cap exceeded");

    // Mint
    _mint(_for, _amount);
  }

  function burnFrom(
    address account,
    uint256 amount
  ) public override(IAnima, ERC20Burnable) {
    super.burnFrom(account, amount);
  }

  //=======================================
  // Admin
  //=======================================
  function pause() external onlyAdmin {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
  }

  //=======================================
  // Internal
  //=======================================
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    // Call super
    super._beforeTokenTransfer(from, to, amount);

    // Check if sender is manager
    if (!MANAGER.isManager(msg.sender, 0)) {
      // Check if minting or burning
      if (from != address(0) && to != address(0)) {
        // Check if token is unbound
        require(BOUND.isUnbound(address(this)), "Anima: Token not unbound");
      }
    }

    // Check if contract is paused
    require(!paused(), "Anima: Paused");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IAnima is IERC20, IERC20Metadata {
  function CAP() external view returns (uint256);

  function mintFor(address _for, uint256 _amount) external;

  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Manager/ManagerModifier.sol";
import "./IArmoryEntityStorageAdapter.sol";

struct MultiStakeRequest {
  address _staker;
  address[] _ownerAddresses;
  uint256[] _ownerTokenIds;
  bytes32[][] _proofs;
  address[] _entityAddresses;
  uint256[][][] _entityIds;
  uint256[][][] _entityAmounts;
}

interface IArmory {
  function adapters(
    address _entityAddress
  ) external view returns (IArmoryEntityStorageAdapter);

  function stake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    bytes32[] calldata _proof,
    uint256 _entityId,
    uint256 _entityAmount
  ) external;

  function stakeBatch(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external;

  function stakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function stakeBatchMulti(MultiStakeRequest calldata _request) external;

  function unstake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external;

  function unstakeBatch(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external;

  function unstakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function unstakeBatchMulti(MultiStakeRequest calldata _request) external;

  function burn(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external;

  function burnBatch(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external;

  function burnBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function burnBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address[] calldata _entityAddresses,
    uint256[][][] calldata _entityIds,
    uint256[][][] calldata _entityAmounts
  ) external;

  function mint(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external;

  function mintBatch(
    address _ownerAddresses,
    uint256 _ownerTokenIds,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external;

  function mintBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function checkMinimumAmounts(
    address _ownerAddresses,
    uint256 _ownerTokenIds,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external view;

  function checkMinimumAmounts(
    address _ownerAddresses,
    uint256 _ownerTokenIds,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256 _entityAmounts
  ) external view;

  function checkMinimumAmountsBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external view;

  function checkMinimumAmountsBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256 _entityAmount
  ) external view;

  function balanceOf(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint _entityTokenId
  ) external view returns (uint);

  function balanceOfBatch(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint[] memory _entityTokenIds
  ) external view returns (uint[] memory);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IArmoryEntityStorageAdapter {
  error Unauthorized(address _staker, address _ownerAddress, uint _ownerId);
  error UnsupportedOperation(address _entityAddress, string operation);
  error UnsupportedEntity(address _entityAddress);
  error AlreadyStaked(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint _entityId,
    uint _tokenAmounts
  );
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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import { IArmory } from "./IArmory.sol";

interface IDurabilityEnabledArmory is IArmory {
  function durabilitySupport(
    address _entityAddress
  ) external view returns (bool);

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
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress,
    uint256[][] calldata _entityIds
  ) external view returns (uint[][] memory);

  function currentDurabilityBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address[] calldata _entityAddress,
    uint256[][][] calldata _entityIds
  ) external view returns (uint[][][] memory);

  function currentDurabilityPercentage(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) external view returns (uint);

  function currentDurabilityPercentageBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityId
  ) external view returns (uint[] memory);

  function currentDurabilityPercentageBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress,
    uint256[][] calldata _entityIds
  ) external view returns (uint[][] memory);

  function currentDurabilityPercentageBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address[] calldata _entityAddress,
    uint256[][][] calldata _entityIds
  ) external view returns (uint[][][] memory);

  function reduceDurability(
    address _ownerAddress,
    uint _ownerTokenId,
    address _ownedTokenAddress,
    uint _ownedTokenId,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _ownedTokenAddress,
    uint[][] calldata _ownedTokenIds,
    uint durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint[][] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityMultiBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address[] calldata _ownedTokenAddresses,
    uint[][][] calldata _ownedTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityMultiBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address[] calldata _entityAddresses,
    uint[][][] calldata _entityTokenIds,
    uint[][][] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBatchBurnableStructure {
  function burnBatchFor(
    address _from,
    uint256[] calldata ids,
    uint256[] calldata amounts
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20Bound {
  function unbind(address _addresses) external;

  function isUnbound(address _addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "../Adventurer/TraitConstants.sol";

import "../Action/ILastActionMarkerStorage.sol";
import "../Action/Actions.sol";
import "../Action/IActionDemandAverageStorage.sol";
import "../Lab/ILab.sol";
import "../Adventurer/IAdventurerData.sol";
import "../Utils/Epoch.sol";
import "../Utils/Random.sol";
import "../lib/FloatingPointConstants.sol";

import "../Particle/Particle.sol";
import "../Manager/ManagerModifier.sol";
import "./ICrafting.sol";
import "../Action/IActionPermit.sol";
import "../Armory/IArmory.sol";
import "./IOwnerSpecificRewardsPool.sol";
import "../Anima/Anima.sol";
import "../Realm/Realm.sol";
import "../Action/IGlobalActionIdStorage.sol";
import "./ICraftingDynamicConfigProvider.sol";
import "../RandomPicker/RandomPicker.sol";
import "../Armory/IDurabilityEnabledArmory.sol";
import "../Utils/ArrayUtils.sol";
import "../Productivity/IProductivity.sol";
import "../Adventurer/IBatchAdventurerData.sol";
import "../Adventurer/IBatchAdventurerGateway.sol";
import "../ERC20/ITokenSpender.sol";
import "../Structure/IRandomStructureBurner.sol";
import "../Structure/IRandomStructureBurnerDurabilityLossHandler.sol";

struct CraftingContractCreationRequest {
  address MANAGER;
  address GATEWAY;
  address ACTION_PERMIT;
  address ACTION_ID_STORAGE;
  address ACTION_DEMAND_STORAGE;
  address ADVENTURER_DATA;
  address ADVENTURER_ARMORY;
  address REALM_ARMORY;
  address TOKEN_SPENDER;
  address REALM_ADDRESS;
  address LAB_ADDRESS;
  address CRAFTING_CONFIG_PROVIDER;
  address AOV;
  address RANDOM_STRUCTURE_BURNER;
  address PRODUCTIVITY;
}

enum RecipeRequirementType {
  MATERIAL_GROUP,
  EXACT_TOKEN
}

struct RecipeRequirement {
  address requirementAddress;
  RecipeRequirementType requirementType;
  bool enabled;
  uint32 tokenAmount;
  uint256 requirementArgument; // rarity value or the token id
}

struct LabCraftingConfig {
  bool enabled;
  uint64 minimumLevel;
  uint256 baseAnimaCost;
  uint256 animaCapacity;
  uint256 labIndex;
}

struct Recipe {
  bool enabled;
  RecipeRequirement[4] requirements;
  IOwnerSpecificRewardsPool rewardsPool;
  uint64 subPoolId;
  uint256 labId;
}

struct CraftingCost {
  uint realm;
  uint void;
}

contract Crafting is
  ICrafting,
  IRandomStructureBurnerDurabilityLossHandler,
  ManagerModifier,
  ReentrancyGuard,
  Pausable
{
  error AdventurerLevelTooLow(uint64 minimumLevel, uint currentLevel);

  error InsufficientLabs(uint labId);
  error InvalidLabId(uint labId);
  error InvalidMaterialTotal(
    uint materialAddressIndex,
    uint adventurerIndex,
    uint materialIdIndex,
    uint expectedAmount,
    uint actualAmount
  );
  error InvalidTotalRequestsCount();
  error InvalidRecipe(uint recipeId);
  error InvalidRecipeAmount(uint recipeId);
  error InvalidMaterial(
    uint recipeId,
    address materialAddress,
    uint materialId
  );
  error InvalidRequirementConfig(uint recipeId);
  error InsufficientMaterials(uint recipeId);
  error GasTooLow(uint gasAmount, uint gasRequired);

  //=======================================
  // Immutables
  //=======================================
  IBatchAdventurerGateway public GATEWAY;
  IActionPermit public ACTION_PERMIT;
  IGlobalActionIdStorage public immutable ACTION_ID_STORAGE;
  IActionDemandAverageStorage public immutable ACTION_DEMAND_STORAGE;
  IBatchAdventurerData public immutable ADVENTURER_DATA;
  IArmory public immutable ADVENTURER_ARMORY;
  IDurabilityEnabledArmory public immutable REALM_ARMORY;
  ITokenSpender public immutable TOKEN_SPENDER;
  address public immutable AOV;
  address public immutable REALM_ADDRESS;
  address public immutable LAB_ADDRESS;
  ICraftingDynamicConfigProvider public CRAFTING_CONFIG_PROVIDER;
  IRandomStructureBurner public RANDOM_STRUCTURE_BURNER;
  IProductivity public PRODUCTIVITY;

  //=======================================
  // Lab config
  //=======================================
  uint128 cacheEpochConfig;
  mapping(uint256 => LabCraftingConfig) public labConfig;
  uint256[] supportedLabIds;
  DynamicCraftingConfigCache _dynamicConfigCache;

  //=======================================
  // Uint256
  //=======================================
  uint256 minimumGasPerCraft;

  //=======================================
  // Recipes
  //=======================================
  uint256[] public availableRecipes;
  mapping(uint256 => Recipe) public recipes;

  // material address -> material id -> rarity
  mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
    public materialGroupConfig;

  //=======================================
  // Event
  //=======================================

  event CraftingStarted(
    uint actionId,
    uint craftId,
    address adventurerAddress,
    uint adventurerId,
    uint recipeId
  );

  event CraftedItem(
    uint actionId,
    uint craftId,
    address adventurerAddress,
    uint adventurerId,
    uint resultType,
    address resultAddress,
    uint resultTokenId,
    uint resultAmount
  );

  event CraftingCosts(
    uint actionId,
    uint labId,
    uint animaMultiplier,
    uint animaAmount,
    uint craftedTotal,
    uint craftingLevelsTotal
  );

  //=======================================
  // Struct
  //=======================================

  struct CraftingCostCurveConfig {
    uint64 labSoftCap;
    uint64 min;
    uint64 max;
    uint64 range;
  }

  struct TempMemoryStorage {
    address adventurerAddress;
    uint256 adventurerId;
    uint256 adventurerLevel;
    uint256[] recipeIds;
    uint256[] realmIds;
    address[] materialAddresses;
    uint256[][][] usedMaterials;
    uint256[][][] usedMaterialAmounts;
    // temp storage
    uint256 randomBase;
    uint256 currentRecipeId;
    uint256 currentRecipeAmount;
    uint256 currentRecipeLabsToBurn;
    uint256 currentRealmId;
    uint256 currentLabStakedCount;
    uint256 currentSuccessfulCrafts;
    uint256 craftingCost;
  }

  struct VerificationMemory {
    Recipe recipe;
    RecipeMaterialMapping craftingAttempt;
    MaterialRequirementMapping materialMapping;
    uint256[][][] totalTokenAmounts;
    uint[] craftAmounts;
    uint[] craftCostAdjustments;
    uint[] levels;
  }

  //=======================================
  // Constructor
  //=======================================
  constructor(
    CraftingContractCreationRequest memory _request
  ) ManagerModifier(_request.MANAGER) {
    ACTION_ID_STORAGE = IGlobalActionIdStorage(_request.ACTION_ID_STORAGE);
    ACTION_PERMIT = IActionPermit(_request.ACTION_PERMIT);
    GATEWAY = IBatchAdventurerGateway(_request.GATEWAY);
    ACTION_DEMAND_STORAGE = IActionDemandAverageStorage(
      _request.ACTION_DEMAND_STORAGE
    );
    LAB_ADDRESS = _request.LAB_ADDRESS;
    REALM_ADDRESS = _request.REALM_ADDRESS;
    REALM_ARMORY = IDurabilityEnabledArmory(_request.REALM_ARMORY);
    ADVENTURER_DATA = IBatchAdventurerData(_request.ADVENTURER_DATA);
    ADVENTURER_ARMORY = IArmory(_request.ADVENTURER_ARMORY);
    TOKEN_SPENDER = ITokenSpender(_request.TOKEN_SPENDER);
    CRAFTING_CONFIG_PROVIDER = ICraftingDynamicConfigProvider(
      _request.CRAFTING_CONFIG_PROVIDER
    );
    RANDOM_STRUCTURE_BURNER = IRandomStructureBurner(
      _request.RANDOM_STRUCTURE_BURNER
    );
    PRODUCTIVITY = IProductivity(_request.PRODUCTIVITY);
    AOV = _request.AOV;
    cacheEpochConfig = Epoch.toConfig(1 days, 0 hours);
    minimumGasPerCraft = 300000;
  }

  //=======================================
  // External
  //=======================================
  function craft(
    CraftingRequests calldata _realmRequests,
    CraftingRequests calldata _voidRequests,
    StakeRequest calldata _stakeRequest
  ) external nonReentrant whenNotPaused {
    require(
      msg.sender == tx.origin,
      "Crafting is not allowed through another contract"
    );
    if (
      gasleft() <
      (_realmRequests.totalCrafts + _voidRequests.totalCrafts) *
        minimumGasPerCraft
    ) {
      revert GasTooLow(
        gasleft(),
        (_realmRequests.totalCrafts + _voidRequests.totalCrafts) *
          minimumGasPerCraft
      );
    }

    if (_stakeRequest.adventurerAddresses.length > 0) {
      ADVENTURER_ARMORY.stakeBatchMulti(
        MultiStakeRequest(
          msg.sender,
          _stakeRequest.adventurerAddresses,
          _stakeRequest.adventurerIds,
          _stakeRequest.proofs,
          _stakeRequest.matsToStakeAddresses,
          _stakeRequest.matsToStakeIds,
          _stakeRequest.matsToStakeAmounts
        )
      );
    }

    DynamicCraftingConfigCache storage config = _getDynamicConfig();
    uint totalAnima;
    if (_realmRequests.totalCrafts > 0) {
      totalAnima += _handleRealmCrafting(_realmRequests, config);
    }
    if (_voidRequests.totalCrafts > 0) {
      totalAnima += _handleVoidCrafting(_voidRequests, config);
    }

    TOKEN_SPENDER.spend(msg.sender, totalAnima, SPENDER_ADVENTURER_BUCKET);
  }

  function dynamicConfigCache()
    public
    returns (DynamicCraftingConfigCache memory)
  {
    return _getDynamicConfig();
  }

  function getSupportedLabIds() public view returns (uint[] memory) {
    return supportedLabIds;
  }

  function maximumRealmCraftsAvailable() public returns (uint[] memory) {
    return _maximumCraftAmounts(_getDynamicConfig());
  }

  function maximumRealmCraftsAvailableView()
    public
    view
    returns (uint[] memory)
  {
    return _maximumCraftAmounts(_dynamicConfigCache);
  }

  function craftingCostsView()
    external
    view
    returns (CraftingCost[] memory result)
  {
    result = new CraftingCost[](supportedLabIds.length);

    for (uint i = 0; i < result.length; i++) {
      result[i].realm = labConfig[supportedLabIds[i]].baseAnimaCost;
      result[i].void =
        (result[i].realm *
          uint(_dynamicConfigCache.voidCraftingCostPercentage[i])) /
        ONE_HUNDRED;
    }
  }

  function craftingCosts() external returns (CraftingCost[] memory result) {
    result = new CraftingCost[](supportedLabIds.length);

    for (uint i = 0; i < result.length; i++) {
      result[i].realm = labConfig[supportedLabIds[i]].baseAnimaCost;
      result[i].void =
        (result[i].realm *
          uint(_getDynamicConfig().voidCraftingCostPercentage[i])) /
        ONE_HUNDRED;
    }
  }

  //=======================================
  // Internals
  //=======================================

  function _handleRealmCrafting(
    CraftingRequests calldata _requests,
    DynamicCraftingConfigCache storage _config
  ) internal returns (uint) {
    (uint anima, uint[] memory realmCrafts, uint randomBase) = _handleCrafting(
      _requests,
      _config.realmCraftingCostPercentage,
      ACTION_ADVENTURER_REALM_CRAFTING
    );

    _affectRealms(realmCrafts, randomBase);

    return anima;
  }

  function _affectRealms(uint[] memory realmCrafts, uint randomBase) internal {
    verifyCraftsAvailable(realmCrafts);
    uint[] memory lossPercentages = _convertLossPercentages(
      _dynamicConfigCache.durabilityLossPercentage
    );

    RANDOM_STRUCTURE_BURNER.randomReduceDurability(
      randomBase,
      LAB_ADDRESS,
      supportedLabIds,
      lossPercentages,
      realmCrafts,
      address(this)
    );
  }

  function _handleVoidCrafting(
    CraftingRequests calldata _requests,
    DynamicCraftingConfigCache storage _config
  ) internal returns (uint totalAnima) {
    (totalAnima, , ) = _handleCrafting(
      _requests,
      _config.voidCraftingCostPercentage,
      ACTION_ADVENTURER_VOID_CRAFTING
    );
  }

  function _handleCrafting(
    CraftingRequests calldata _requests,
    uint32[] storage animaMultipliers,
    uint _action
  )
    internal
    returns (uint256 totalAnima, uint[] memory totalCrafts, uint randomBase)
  {
    GATEWAY.checkAddressBatch(_requests.adventurerAddresses, _requests.proofs);
    ACTION_PERMIT.checkPermissionsMany(
      msg.sender,
      _requests.adventurerAddresses,
      _requests.adventurerIds,
      _requests.proofs,
      _action
    );
    ADVENTURER_ARMORY.burnBatchMulti(
      _requests.adventurerAddresses,
      _requests.adventurerIds,
      _requests.materialAddresses,
      _requests.materialIds,
      _requests.materialAmounts
    );

    uint[] memory levels = ADVENTURER_DATA.getBatch(
      _requests.adventurerAddresses,
      _requests.adventurerIds,
      traits.ADV_TRAIT_GROUP_BASE,
      traits.ADV_TRAIT_BASE_LEVEL
    );

    uint[] memory craftingCostAdjustments;
    (totalCrafts, craftingCostAdjustments) = _verifyMaterials(
      _requests,
      levels
    );
    uint craftsCount;
    (totalAnima, craftsCount) = _totals(
      _action,
      totalCrafts,
      craftingCostAdjustments,
      animaMultipliers
    );
    if (craftsCount != _requests.totalCrafts) {
      revert InvalidTotalRequestsCount();
    }

    randomBase = _dispense(_action, _requests);

    ACTION_DEMAND_STORAGE.increaseDemandBatch(
      _action,
      supportedLabIds,
      totalCrafts
    );
  }

  function _dispense(
    uint _action,
    CraftingRequests calldata _requests
  ) internal returns (uint) {
    uint craftId = ACTION_ID_STORAGE.getAndIncrementNextId(
      _action,
      _requests.totalCrafts
    );
    uint randomBase = Random.startRandomBase(_action, craftId);
    for (uint i = 0; i < _requests.recipes.length; i++) {
      for (uint j = 0; j < _requests.recipes[i].length; j++) {
        emit CraftingStarted(
          _action,
          craftId,
          _requests.adventurerAddresses[i],
          _requests.adventurerIds[i],
          _requests.recipes[i][j].recipeId
        );

        randomBase = _dispenseRewards(
          _action,
          randomBase,
          craftId,
          _requests.adventurerAddresses[i],
          _requests.adventurerIds[i],
          _requests.recipes[i][j].recipeId,
          _requests.recipes[i][j].recipeAmount
        );

        craftId++;
      }
    }
    return randomBase;
  }

  function _totals(
    uint _action,
    uint[] memory totalCrafts,
    uint[] memory craftingCostAdjustments,
    uint32[] memory animaMultipliers
  ) internal returns (uint256 totalAnima, uint256 craftsCount) {
    uint animaCosts = 0;
    for (uint i = 0; i < supportedLabIds.length; i++) {
      LabCraftingConfig storage config = labConfig[supportedLabIds[i]];
      if (!config.enabled) {
        revert InvalidLabId(supportedLabIds[i]);
      }
      animaCosts =
        (config.baseAnimaCost *
          (craftingCostAdjustments[i]) *
          uint(animaMultipliers[i])) /
        ONE_HUNDRED;

      emit CraftingCosts(
        _action,
        supportedLabIds[i],
        animaMultipliers[i],
        animaCosts,
        totalCrafts[i],
        craftingCostAdjustments[i]
      );

      totalAnima += animaCosts;
      craftsCount += totalCrafts[i];
    }
  }

  function _verifyMaterials(
    CraftingRequests calldata _requests,
    uint[] memory _levels
  ) internal view returns (uint[] memory, uint[] memory) {
    VerificationMemory memory mem;
    mem.craftAmounts = new uint[](supportedLabIds.length);
    mem.craftCostAdjustments = new uint[](supportedLabIds.length);
    mem.totalTokenAmounts = _createEmptyMaterialAmountsTotalsArray(_requests);
    mem.levels = _levels;
    // adventurer index
    for (uint ai = 0; ai < _requests.adventurerIds.length; ai++) {
      // recipe index
      for (uint ri = 0; ri < _requests.recipes[ai].length; ri++) {
        mem.craftingAttempt = _requests.recipes[ai][ri];
        mem.recipe = recipes[mem.craftingAttempt.recipeId];

        // Increment total crafted amounts
        _verifyLabRequirementsAndIncrementCounts(
          mem.recipe.labId,
          mem.craftingAttempt.recipeAmount,
          _requests.adventurerAddresses[ai],
          mem.levels[ai],
          mem.craftAmounts,
          mem.craftCostAdjustments
        );

        // recipe requirement id
        for (uint rri = 0; rri < mem.recipe.requirements.length; rri++) {
          if (!mem.recipe.requirements[rri].enabled) {
            break;
          }
          mem.materialMapping = mem.craftingAttempt.materialMappings[rri];
          _verifyMaterialsAreCorrectTypeAndAmount(
            mem.craftingAttempt.recipeId,
            ai,
            mem.recipe.requirements[rri],
            _requests.materialAddresses,
            _requests.materialIds,
            mem.materialMapping.materialAddressIndexes,
            mem.materialMapping.materialIndexes,
            mem.materialMapping.materialAmounts,
            mem.craftingAttempt.recipeAmount,
            mem.totalTokenAmounts
          );
        }
      }
    }

    _verifyTotals(_requests.materialAmounts, mem.totalTokenAmounts);
    return (mem.craftAmounts, mem.craftCostAdjustments);
  }

  function _verifyLabRequirementsAndIncrementCounts(
    uint labId,
    uint amount,
    address adventurerAddress,
    uint adventurerLevel,
    uint[] memory craftCounts,
    uint[] memory craftCostAdjustments
  ) internal view {
    if (!labConfig[labId].enabled) {
      revert InvalidLabId(labId);
    }

    if (labConfig[labId].minimumLevel > adventurerLevel) {
      revert AdventurerLevelTooLow(
        labConfig[labId].minimumLevel,
        adventurerLevel
      );
    }

    craftCounts[labConfig[labId].labIndex] += amount;
    // Crafting costs are baseCost * (1 + adventurerLevel). Aov costs are 5x higher (relative to anima gains).
    craftCostAdjustments[labConfig[labId].labIndex] +=
      amount *
      (adventurerLevel) *
      (adventurerAddress == AOV ? 5 : 1);
  }

  struct RequirementVerificationMemory {
    uint submittedMaterialsAmount;
    address materialAddress;
    uint materialId;
  }

  function _verifyMaterialsAreCorrectTypeAndAmount(
    uint _recipeId,
    uint _adventurerIndex,
    RecipeRequirement memory _requirement,
    address[] calldata _materialAddresses,
    uint256[][][] calldata _materialIds,
    uint[] memory _materialAddressIndexes,
    uint[] memory _materialIdIndexes,
    uint[] memory _materialAmounts,
    uint _recipeAmount,
    uint[][][] memory _totalAmounts
  ) internal view {
    RequirementVerificationMemory memory mem;
    for (uint i = 0; i < _materialIdIndexes.length; i++) {
      mem.materialAddress = _materialAddresses[_materialAddressIndexes[i]];
      mem.materialId = _materialIds[_materialAddressIndexes[i]][
        _adventurerIndex
      ][_materialIdIndexes[i]];
      uint amountMultiplier = 1;
      if (_requirement.requirementType == RecipeRequirementType.EXACT_TOKEN) {
        if (
          _requirement.requirementAddress != mem.materialAddress ||
          _requirement.requirementArgument != mem.materialId
        ) {
          revert InvalidMaterial(
            _recipeId,
            mem.materialAddress,
            mem.materialId
          );
        }
      } else if (
        _requirement.requirementType == RecipeRequirementType.MATERIAL_GROUP
      ) {
        amountMultiplier = materialGroupConfig[mem.materialAddress][
          mem.materialId
        ][_requirement.requirementArgument];

        if (amountMultiplier <= 0) {
          revert InvalidMaterial(
            _recipeId,
            mem.materialAddress,
            mem.materialId
          );
        }
      } else {
        revert InvalidRequirementConfig(_recipeId);
      }
      mem.submittedMaterialsAmount += _materialAmounts[i] * amountMultiplier;
      _totalAmounts[_materialAddressIndexes[i]][_adventurerIndex][
        _materialIdIndexes[i]
      ] += _materialAmounts[i] * amountMultiplier;
    }

    if (
      _requirement.tokenAmount * _recipeAmount != mem.submittedMaterialsAmount
    ) {
      revert InsufficientMaterials(_recipeId);
    }
  }

  function _dispenseRewards(
    uint _action,
    uint _randomBase,
    uint _craftId,
    address _adventurerAddress,
    uint _adventurerId,
    uint recipeId,
    uint recipeAmount
  ) internal returns (uint) {
    if (!recipes[recipeId].enabled) {
      revert InvalidRecipe(recipeId);
    }

    Recipe storage recipe = recipes[recipeId];
    DispensedRewards memory dispensed = recipe.rewardsPool.dispenseRewards(
      recipe.subPoolId,
      _randomBase,
      msg.sender,
      _adventurerAddress,
      _adventurerId,
      recipeAmount
    );

    DispensedReward memory reward;
    for (uint r = 0; r < dispensed.rewards.length; r++) {
      reward = dispensed.rewards[r];
      emit CraftedItem(
        _action,
        _craftId,
        _adventurerAddress,
        _adventurerId,
        reward.armoryTokenType,
        reward.rewardAddress,
        reward.rewardTokenId,
        reward.rewardAmount
      );
    }

    return dispensed.nextRandomBase;
  }

  function _createEmptyMaterialAmountsTotalsArray(
    CraftingRequests calldata _requests
  ) internal pure returns (uint[][][] memory result) {
    result = new uint[][][](_requests.materialAddresses.length);
    for (uint i = 0; i < _requests.materialAddresses.length; i++) {
      result[i] = new uint[][](_requests.adventurerIds.length);
      for (uint j = 0; j < _requests.adventurerIds.length; j++) {
        result[i][j] = new uint[](_requests.materialAmounts[i][j].length);
      }
    }
  }

  function _verifyTotals(
    uint256[][][] calldata requestedAmounts,
    uint256[][][] memory usedInCrafting
  ) internal pure {
    for (uint i = 0; i < usedInCrafting.length; i++) {
      for (uint j = 0; j < usedInCrafting[i].length; j++) {
        for (uint k = 0; k < usedInCrafting[i][j].length; k++) {
          if (requestedAmounts[i][j][k] < usedInCrafting[i][j][k]) {
            revert InvalidMaterialTotal(
              i,
              j,
              k,
              requestedAmounts[i][j][k],
              usedInCrafting[i][j][k]
            );
          }
        }
      }
    }
  }

  function verifyCraftsAvailable(uint[] memory requiredAmounts) internal {
    uint[] memory craftsAvailable = _maximumCraftAmounts(_getDynamicConfig());
    for (uint i = 0; i < supportedLabIds.length; i++) {
      if (craftsAvailable[i] < requiredAmounts[i]) {
        revert InsufficientLabs(supportedLabIds[i]);
      }
    }
  }

  function _maximumCraftAmounts(
    DynamicCraftingConfigCache storage config
  ) internal view returns (uint[] memory result) {
    uint[] memory lossPercentages = _convertLossPercentages(
      config.durabilityLossPercentage
    );
    return
      RANDOM_STRUCTURE_BURNER.availableUsageCounts(
        LAB_ADDRESS,
        supportedLabIds,
        lossPercentages
      );
  }

  function _getDynamicConfig()
    internal
    returns (DynamicCraftingConfigCache storage)
  {
    uint256 currentEpoch = Epoch.packTimestampToEpoch(
      block.timestamp,
      cacheEpochConfig
    );
    DynamicCraftingConfigCache storage cache = _dynamicConfigCache;

    // Only load the config once for the day, then return the cached one
    if (currentEpoch == cache.epoch) {
      return cache;
    }

    DynamicLabCraftingConfig[] memory newConfigs = CRAFTING_CONFIG_PROVIDER
      .getConfigBatch(supportedLabIds);

    // In case new labs appeared, should be usually skipped
    if (cache.durabilityLossPercentage.length != newConfigs.length) {
      cache.durabilityLossPercentage = new uint32[](newConfigs.length);
      cache.productivityPerCraft = new uint32[](newConfigs.length);
      cache.voidCraftingCostPercentage = new uint32[](newConfigs.length);
      cache.realmCraftingCostPercentage = new uint32[](newConfigs.length);
    }

    // Repack configs for preferred usage format
    for (uint i = 0; i < newConfigs.length; i++) {
      cache.durabilityLossPercentage[i] = uint32(
        newConfigs[i].durabilityLossPercentage
      );
      cache.productivityPerCraft[i] = uint32(
        newConfigs[i].productivityPerCraft
      );
      cache.voidCraftingCostPercentage[i] = uint32(
        newConfigs[i].voidCraftingCostPercentage
      );
      cache.realmCraftingCostPercentage[i] = uint32(
        newConfigs[i].realmCraftingCostPercentage
      );
    }

    // Save the epoch
    cache.epoch = currentEpoch;
    return cache;
  }

  function _calculateCraftingCost(
    uint baseCost,
    uint labCount,
    CraftingCostCurveConfig storage curveCostConfig
  ) internal view returns (uint result) {
    return
      ((((baseCost * curveCostConfig.labSoftCap) /
        (curveCostConfig.labSoftCap + labCount - 1)) * curveCostConfig.range) +
        curveCostConfig.min) / ONE_HUNDRED;
  }

  function _convertLossPercentages(
    uint32[] memory lossPercentages
  ) internal pure returns (uint[] memory result) {
    result = new uint[](lossPercentages.length);
    for (uint i = 0; i < lossPercentages.length; i++) {
      result[i] = lossPercentages[i];
    }
  }

  //=======================================
  // RandomStructureBurnerDurabilityLossHandler
  //=======================================

  function handleDurabilityLoss(
    uint[] calldata realmIds,
    uint[][] calldata structureIds,
    uint[][] calldata durabilityLoss
  ) external onlyManager {
    revert("Not implemented");
  }

  function handleDurabilityLoss(
    uint _realmId,
    uint _structureId,
    uint _durabilityLoss
  ) external onlyManager {
    DynamicCraftingConfigCache memory cache = _getDynamicConfig();
    int productivityChange = int(
      (uint(cache.productivityPerCraft[labConfig[_structureId].labIndex]) *
        _durabilityLoss) /
        uint(cache.durabilityLossPercentage[labConfig[_structureId].labIndex])
    );
    PRODUCTIVITY.change(_realmId, productivityChange, true);
  }

  //=======================================
  // Admin
  //=======================================

  function pause() external onlyAdmin {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
  }

  // Set minimum gas required
  function updateMinimumGas(uint256 _minimumGas) external onlyAdmin {
    minimumGasPerCraft = _minimumGas;
  }

  // Set minimum gas required
  function updateConfigProvider(address _configProvider) external onlyAdmin {
    CRAFTING_CONFIG_PROVIDER = ICraftingDynamicConfigProvider(_configProvider);
  }

  function configureStructures(
    uint256[] calldata _tokenIds,
    uint64[] calldata _minimumLevels,
    uint256[] calldata _animaCosts,
    uint256[] calldata _animaCapacity
  ) external onlyAdmin {
    require(_tokenIds.length == _minimumLevels.length);

    for (uint i = 0; i < supportedLabIds.length; i++) {
      labConfig[supportedLabIds[i]].enabled = false;
    }

    supportedLabIds = _tokenIds;
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      labConfig[_tokenIds[i]] = LabCraftingConfig(
        true,
        _minimumLevels[i],
        _animaCosts[i],
        _animaCapacity[i],
        i
      );
    }
  }

  function clearCache(bool _forceLoad) external onlyAdmin {
    _dynamicConfigCache.epoch = 0;
    if (_forceLoad) {
      _getDynamicConfig();
    }
  }

  function configureMaterialGroup(
    address _materialAddress,
    uint[] calldata _materialTokenIds,
    uint[] calldata _materialGroups,
    uint[] calldata _amounts
  ) external onlyAdmin {
    for (uint i = 0; i < _materialTokenIds.length; i++) {
      materialGroupConfig[_materialAddress][_materialTokenIds[i]][
        _materialGroups[i]
      ] = _amounts[i];
    }
  }

  function updateRecipes(
    uint[] calldata _recipeIndexes,
    Recipe[] calldata _recipes,
    bool replaceAll
  ) external onlyAdmin {
    if (replaceAll) {
      for (uint i = 0; i < availableRecipes.length; i++) {
        recipes[availableRecipes[i]].enabled = false;
      }
      availableRecipes = _recipeIndexes;
    } else {
      for (uint i = 0; i < _recipeIndexes.length; i++) {
        if (!recipes[_recipeIndexes[i]].enabled) {
          availableRecipes.push();
          availableRecipes[availableRecipes.length - 1] = _recipeIndexes[i];
        }
      }
    }
    for (uint i = 0; i < _recipeIndexes.length; i++) {
      recipes[_recipeIndexes[i]] = _recipes[i];
    }
  }

  function updatePermit(address _permit) external onlyAdmin {
    ACTION_PERMIT = IActionPermit(_permit);
  }

  function updateGateway(address _gateway) external onlyAdmin {
    GATEWAY = IBatchAdventurerGateway(_gateway);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

struct MaterialRequirementMapping {
  uint256[] materialAddressIndexes;
  uint256[] materialIndexes;
  uint256[] materialAmounts;
}

struct RecipeMaterialMapping {
  uint256 recipeId;
  uint256 recipeAmount;
  // (recipe requirement => material mapping)
  MaterialRequirementMapping[] materialMappings;
}

struct DynamicCraftingConfigCache {
  uint epoch;
  uint32[] realmCraftingCostPercentage;
  uint32[] voidCraftingCostPercentage;
  uint32[] durabilityLossPercentage;
  uint32[] productivityPerCraft;
}

struct CraftingRequests {
  // Adventurers
  address[] adventurerAddresses;
  uint256[] adventurerIds;
  // Material totals
  address[] materialAddresses;
  // material address -> adventurer index -> material ids
  uint256[][][] materialIds;
  // material address -> adventurer index -> material amounts
  uint256[][][] materialAmounts;
  bytes32[][] proofs;
  // Crafting requests
  // List per adventurer
  RecipeMaterialMapping[][] recipes;
  // Gas efficiency and kinda checksum
  uint totalCrafts;
}

struct StakeRequest {
  // Adventurers
  address[] adventurerAddresses;
  uint256[] adventurerIds;
  bytes32[][] proofs;
  // Materials to stake into Armory
  address[] matsToStakeAddresses;
  // material address -> adventurer index -> material ids
  uint256[][][] matsToStakeIds;
  // material address -> adventurer index -> material amounts
  uint256[][][] matsToStakeAmounts;
}

interface ICrafting {
  function dynamicConfigCache()
    external
    returns (DynamicCraftingConfigCache memory);

  function getSupportedLabIds() external view returns (uint[] memory);

  function craft(
    CraftingRequests calldata _realmRequests,
    CraftingRequests calldata _voidRequests,
    StakeRequest calldata _stakeRequest
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "../Lab/LabSupplyAverageStorage.sol";
import "../Action/Actions.sol";
import "../Utils/Epoch.sol";

struct DynamicLabCraftingConfig {
  uint256 realmCraftingCostPercentage;
  uint256 voidCraftingCostPercentage;
  uint256 durabilityLossPercentage;
  uint256 productivityPerCraft;
}

interface ICraftingDynamicConfigProvider {
  function getConfigBatch(
    uint256[] calldata labIds
  ) external returns (DynamicLabCraftingConfig[] memory result);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

//=======================================
// Structs
//=======================================
struct DispensedRewards {
  uint256 nextRandomBase;
  DispensedReward[] rewards;
}

struct DispensedReward {
  uint armoryTokenType;
  address rewardAddress;
  uint256 rewardTokenId;
  uint256 rewardAmount;
}

//=======================================================================================================================================================
// Dispenser contract for rewards. Each RewardPool is divided into subpools (in case of lootboxes: for different rarities, or realm specific pools, etc).
//=======================================================================================================================================================
interface IOwnerSpecificRewardsPool {
  //==============================================================================================================================
  // Dispenses random rewards from the pool
  //==============================================================================================================================
  function dispenseRewards(
    uint64 subPoolId,
    uint256 randomNumberBase,
    address receiver,
    address ownerAddress,
    uint ownerId,
    uint amount
  ) external returns (DispensedRewards memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Utils/IEpochConfigurable.sol";

uint constant SPENDER_ADVENTURER_BUCKET = 1;
uint constant SPENDER_REALM_BUCKET = 2;

interface ITokenSpender is IEpochConfigurable {
  function getEpochValue(uint _epoch) external view returns (uint);

  function getEpochValueBatch(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint[] memory result);

  function getBucketEpochValueBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint[] memory result);

  function getEpochValueBatchTotal(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint result);

  function getBucketEpochValueBatchTotal(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint result);

  function spend(address _owner, uint _amount, uint _bucket) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../BatchStaker/IBatchBurnableStructure.sol";

interface ILab is IBatchBurnableStructure {
  function totalSupply(uint _tokenId) external view returns (uint256);

  function mintFor(address _for, uint256 _id, uint256 _amount) external;

  function mintBatchFor(
    address _for,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) external;

  function mintBatchFor(
    address[] calldata _for,
    uint256[][] memory _ids,
    uint256[][] memory _amounts
  ) external;

  function burn(uint256 _id, uint256 _amount) external;

  function burnBatch(uint256[] calldata ids, uint256[] calldata amounts) external;

  function burnBatch(uint256[][] memory ids, uint256[][] memory amounts) external;

  function burnBatchFor(
    address _for,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) external;

  function burnFor(address _for, uint256 _id, uint256 _amount) external;

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[][] memory ids,
    uint256[][] memory amounts,
    bytes memory data
  ) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "../SupplyDemand/AbstractEpochAverageStorage.sol";
import "../Utils/Epoch.sol";
import "./ILab.sol";

contract LabSupplyAverageStorage is
  ManagerModifier,
  AbstractEpochAverageStorage
{
  using Epoch for uint256;

  uint constant LAB_GROUP = 0;

  uint128 public EPOCH_CONFIG;
  EpochAverageStorageConfig public AVERAGE_STORAGE_CONFIG;
  ILab public immutable LAB;

  constructor(address _manager, address _lab) ManagerModifier(_manager) {
    LAB = ILab(_lab);
    EPOCH_CONFIG = Epoch.toConfig(1 days, 0 hours);

    AVERAGE_STORAGE_CONFIG = EpochAverageStorageConfig(4, 1, 5); // EMA5
  }

  function getSupplyBatch(
    uint256[] calldata _labIds
  ) external returns (uint256[] memory) {
    return _getValueBatch(LAB_GROUP, _labIds);
  }

  function _getConfig(
    uint256 _group,
    uint256 _subGroup
  ) internal view override returns (EpochAverageStorageConfig memory) {
    return AVERAGE_STORAGE_CONFIG;
  }

  function _getCurrentValue(
    uint256 _group,
    uint256 _subGroup
  ) internal view override returns (uint256) {
    return LAB.totalSupply(_subGroup);
  }

  function _getPredictedNextValue(
    uint256 _group,
    uint256 _subGroup
  ) internal view override returns (uint256) {
    return LAB.totalSupply(_subGroup);
  }

  function _getCurrentEpoch(
    uint256 _group,
    uint256 _subGroup
  ) internal view override returns (uint256) {
    return Epoch.toEpochNumber(block.timestamp, EPOCH_CONFIG);
  }

  function forceUpdateBaseValue(
    uint _tokenId,
    uint newValue
  ) external onlyAdmin {
    _forceUpdateBaseValue(LAB_GROUP, _tokenId, newValue);
  }

  function updateConfig(
    uint _baseWeight,
    uint _epochWeight
  ) external onlyAdmin {
    AVERAGE_STORAGE_CONFIG.baseWeight = _baseWeight;
    AVERAGE_STORAGE_CONFIG.epochWeight = _epochWeight;
    AVERAGE_STORAGE_CONFIG.totalWeight = _baseWeight + _epochWeight;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
uint256 constant ROUNDING_ADJUSTER = DECIMAL_POINT - 1;

int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
uint256 constant ONE_HUNDRED_SQUARE = ONE_HUNDRED * ONE_HUNDRED;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED_SQUARE = SIGNED_ONE_HUNDRED * SIGNED_ONE_HUNDRED;

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

  modifier onlyConfigManager() {
    require(MANAGER.isManager(msg.sender, 4), "Manager: Not config manager");
    _;
  }

  modifier onlyTokenSpender() {
    require(MANAGER.isManager(msg.sender, 5), "Manager: Not token spender");
    _;
  }

  modifier onlyTokenEmitter() {
    require(MANAGER.isManager(msg.sender, 6), "Manager: Not token emitter");
    _;
  }

  modifier onlyPauser() {
    require(
      MANAGER.isAdmin(msg.sender) || MANAGER.isManager(msg.sender, 6),
      "Manager: Not pauser"
    );
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IParticle is IERC20 {
  function mintFor(address _for, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Bound/IERC20Bound.sol";
import "./IParticle.sol";

import "../Manager/ManagerModifier.sol";

contract Particle is
  IParticle,
  ERC20,
  ERC20Burnable,
  ManagerModifier,
  ReentrancyGuard,
  Pausable
{
  //=======================================
  // Immutables
  //=======================================
  IERC20Bound public immutable BOUND;
  uint256 public immutable CAP;

  //=======================================
  // Constructor
  //=======================================
  constructor(
    address _manager,
    address _bound,
    uint256 _cap
  ) ERC20("Particle", "PARTICLE") ManagerModifier(_manager) {
    BOUND = IERC20Bound(_bound);
    CAP = _cap;
  }

  //=======================================
  // External
  //=======================================
  function mintFor(
    address _for,
    uint256 _amount
  ) external override onlyTokenMinter {
    // Check amount doesn't exceed cap
    require(ERC20.totalSupply() + _amount <= CAP, "Particle: Cap exceeded");

    // Mint
    _mint(_for, _amount);
  }

  //=======================================
  // Admin
  //=======================================
  function pause() external onlyAdmin {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
  }

  //=======================================
  // Internal
  //=======================================
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    // Call super
    super._beforeTokenTransfer(from, to, amount);

    // Check if sender is manager
    if (!MANAGER.isManager(msg.sender, 0)) {
      // Check if minting or burning
      if (from != address(0) && to != address(0)) {
        // Check if token is unbound
        require(BOUND.isUnbound(address(this)), "Particle: Token not unbound");
      }
    }

    // Check if contract is paused
    require(!paused(), "Particle: Paused");
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Utils/IEpochConfigurable.sol";

interface IProductivity is IEpochConfigurable {
  // All time Productivity
  function currentProductivity(uint256 _realmId) external view returns (uint);

  function currentProductivityBatch(
    uint[] calldata _realmIds
  ) external view returns (uint[] memory result);

  function previousEpochsProductivityTotals(
    uint _realmId,
    uint _numberOfEpochs,
    bool _includeCurrentEpoch
  ) external view returns (uint gains, uint losses);

  function epochsProductivityTotals(
    uint _realmId,
    uint _startEpoch,
    uint _endEpoch
  ) external view returns (uint gains, uint losses);

  function previousEpochsProductivityTotalsBatch(
    uint[] calldata _realmIds,
    uint _numberOfEpochs,
    bool _includeCurrentEpoch
  ) external view returns (uint[] memory gains, uint[] memory spending);

  function epochsProductivityTotalsBatch(
    uint[] calldata _realmIds,
    uint _startEpoch,
    uint _endEpoch
  ) external view returns (uint[] memory gains, uint[] memory spending);

  function change(uint256 _realmId, int _delta, bool _includeInTotals) external;

  function changeBatch(
    uint256[] calldata _tokenIds,
    int[] calldata _deltas,
    bool _includeInTotals
  ) external;

  function changeBatch(
    uint256[] calldata _tokenIds,
    int _delta,
    bool _includeInTotals
  ) external;

  function increase(
    uint256 _realmId,
    uint _delta,
    bool _includeInTotals
  ) external;

  function increaseBatch(
    uint256[] calldata _tokenIds,
    uint[] calldata _delta,
    bool _includeInTotals
  ) external;

  function increaseBatch(
    uint256[] calldata _tokenIds,
    uint _delta,
    bool _includeInTotals
  ) external;

  function decrease(
    uint256 _realmId,
    uint _delta,
    bool _includeInTotals
  ) external;

  function decreaseBatch(
    uint256[] calldata _tokenIds,
    uint[] calldata _delta,
    bool _includeInTotals
  ) external;

  function decreaseBatch(
    uint256[] calldata _tokenIds,
    uint _delta,
    bool _includeInTotals
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRandomPicker {
  struct TicketPool {
    uint32 currentLength;
    TicketPoolPosition[] tickets;
  }

  struct TicketPoolPosition {
    uint16 ownerId;
    uint32 ownerPoolIndex;
  }

  struct OwnerTickets {
    uint32 currentLength;
    uint32[] positions;
  }

  function pools(
    uint256 poolType,
    uint256 subPoolId
  ) external view returns (TicketPool memory);

  function ownedTickets(
    uint256 poolType,
    uint256 subPoolId,
    uint16 ownerId
  ) external view returns (OwnerTickets memory);

  function addToPool(
    uint256 poolType,
    uint256 subPool,
    uint256 owner,
    uint256 number
  ) external;

  function addToPoolBatch(
    uint256 poolType,
    uint256 subPool,
    uint256[] calldata _ownerIds,
    uint256[] calldata _numbers
  ) external;

  function addToPoolBatch2(
    uint256 poolType,
    uint256[] calldata subPools,
    uint256 owner,
    uint256[] calldata numbers
  ) external;

  function addToPoolBatch3(
    uint256 poolType,
    uint256[][] calldata subPools,
    uint256[] calldata owners,
    uint256[][] calldata numbers
  ) external;

  function addToPoolBatch4(
    uint256 poolType,
    uint256[] calldata subPools,
    uint256[][] calldata owners,
    uint256[][] calldata numbers
  ) external;

  function removeFromPool(
    uint256 poolType,
    uint256 subPool,
    uint256 owner,
    uint256 number
  ) external;

  function removeFromPoolBatch(
    uint256 poolType,
    uint256 subPool,
    uint256[] calldata owner,
    uint256[] calldata number
  ) external;

  function removeFromPoolBatch2(
    uint256 poolType,
    uint256[] calldata subPools,
    uint256 owner,
    uint256[] calldata numbers
  ) external;

  function removeFromPoolBatch3(
    uint256 poolType,
    uint256[][] calldata subPools,
    uint256[] calldata owners,
    uint256[][] calldata numbers
  ) external;

  function removeFromPoolBatch4(
    uint256 poolType,
    uint256[] calldata subPools,
    uint256[][] calldata owners,
    uint256[][] calldata numbers
  ) external;

  function useRandomizer(
    uint256 poolType,
    uint256 subPool,
    uint256 number,
    uint256 randomBase
  ) external view returns (uint[] memory result, uint newRandomBase);

  function useRandomizerBatch(
    uint256 poolType,
    uint256[] calldata subPool,
    uint256[] calldata number,
    uint256 randomBase
  ) external view returns (uint[][] memory result, uint newRandomBase);

  function getPoolSizes(
    uint256 poolType,
    uint256[] calldata subPools
  ) external view returns (uint256[] memory result);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "../Utils/Random.sol";
import "./IRandomPicker.sol";

contract RandomPicker is IRandomPicker, ManagerModifier {
  constructor(address _manager) ManagerModifier(_manager) {}

  mapping(uint256 => mapping(uint256 => TicketPool)) private _pools;
  mapping(uint256 => mapping(uint256 => mapping(uint16 => OwnerTickets)))
    private _ownedTickets;

  function pools(
    uint256 poolType,
    uint256 subPoolId
  ) external view returns (TicketPool memory) {
    return _pools[poolType][subPoolId];
  }

  function ownedTickets(
    uint256 poolType,
    uint256 subPoolId,
    uint16 ownerId
  ) external view returns (OwnerTickets memory) {
    return _ownedTickets[poolType][subPoolId][ownerId];
  }

  function addToPool(
    uint256 poolType,
    uint256 subPool,
    uint256 owner,
    uint256 number
  ) external onlyManager {
    _addToPool(poolType, subPool, owner, number);
  }

  function addToPoolBatch(
    uint256 poolType,
    uint256 subPool,
    uint256[] calldata _ownerIds,
    uint256[] calldata _numbers
  ) external onlyManager {
    for (uint i = 0; i < _ownerIds.length; i++) {
      _addToPool(poolType, subPool, _ownerIds[i], _numbers[i]);
    }
  }

  function addToPoolBatch2(
    uint256 poolType,
    uint256[] calldata subPools,
    uint256 owner,
    uint256[] calldata numbers
  ) external onlyManager {
    for (uint i = 0; i < subPools.length; i++) {
      _addToPool(poolType, subPools[i], owner, numbers[i]);
    }
  }

  function addToPoolBatch3(
    uint256 poolType,
    uint256[][] calldata subPools,
    uint256[] calldata owners,
    uint256[][] calldata numbers
  ) external onlyManager {
    for (uint i = 0; i < owners.length; i++) {
      for (uint j = 0; j < subPools[i].length; j++) {
        _addToPool(poolType, subPools[i][j], owners[i], numbers[i][j]);
      }
    }
  }

  function addToPoolBatch4(
    uint256 poolType,
    uint256[] calldata subPools,
    uint256[][] calldata owners,
    uint256[][] calldata numbers
  ) external onlyManager {
    for (uint i = 0; i < subPools.length; i++) {
      for (uint j = 0; j < owners[i].length; j++) {
        _addToPool(poolType, subPools[i], owners[i][j], numbers[i][j]);
      }
    }
  }

  function removeFromPool(
    uint256 poolType,
    uint256 subPool,
    uint256 owner,
    uint256 number
  ) external onlyManager {
    _removeFromPool(poolType, subPool, owner, number);
  }

  function removeFromPoolBatch(
    uint256 poolType,
    uint256 subPool,
    uint256[] calldata owner,
    uint256[] calldata number
  ) external onlyManager {
    for (uint i = 0; i < owner.length; i++) {
      _removeFromPool(poolType, subPool, owner[i], number[i]);
    }
  }

  function removeFromPoolBatch2(
    uint256 poolType,
    uint256[] calldata subPools,
    uint256 owner,
    uint256[] calldata numbers
  ) external onlyManager {
    for (uint i = 0; i < subPools.length; i++) {
      _removeFromPool(poolType, subPools[i], owner, numbers[i]);
    }
  }

  function removeFromPoolBatch3(
    uint256 poolType,
    uint256[][] calldata subPools,
    uint256[] calldata owners,
    uint256[][] calldata numbers
  ) external onlyManager {
    for (uint i = 0; i < owners.length; i++) {
      for (uint j = 0; j < subPools[i].length; j++) {
        _removeFromPool(poolType, subPools[i][j], owners[i], numbers[i][j]);
      }
    }
  }

  function removeFromPoolBatch4(
    uint256 poolType,
    uint256[] calldata subPools,
    uint256[][] calldata owners,
    uint256[][] calldata numbers
  ) external onlyManager {
    for (uint i = 0; i < subPools.length; i++) {
      for (uint j = 0; j < owners[i].length; j++) {
        _removeFromPool(poolType, subPools[i], owners[i][j], numbers[i][j]);
      }
    }
  }

  function useRandomizer(
    uint256 poolType,
    uint256 subPool,
    uint256 number,
    uint256 randomBase
  ) external view returns (uint[] memory result, uint newRandomBase) {
    (result, newRandomBase) = _findRandom(
      poolType,
      subPool,
      number,
      randomBase
    );
  }

  function useRandomizerBatch(
    uint256 poolType,
    uint256[] calldata subPool,
    uint256[] calldata number,
    uint256 randomBase
  ) external view returns (uint[][] memory result, uint newRandomBase) {
    require(subPool.length == number.length);

    result = new uint[][](subPool.length);
    newRandomBase = randomBase;
    for (uint i = 0; i < subPool.length; i++) {
      (result[i], newRandomBase) = _findRandom(
        poolType,
        subPool[i],
        number[i],
        newRandomBase
      );
    }
  }

  function getPoolSizes(
    uint256 poolType,
    uint256[] calldata subPools
  ) external view returns (uint256[] memory result) {
    result = new uint256[](subPools.length);
    for (uint i = 0; i < subPools.length; i++) {
      result[i] = _pools[poolType][subPools[i]].currentLength;
    }
  }

  function _addToPool(
    uint256 poolType,
    uint256 subPool,
    uint256 owner,
    uint256 number
  ) internal {
    TicketPool storage ticketPool = _pools[poolType][subPool];
    OwnerTickets storage ownerTickets = _ownedTickets[poolType][subPool][
      uint16(owner)
    ];

    uint ownerTicketsLength = uint(ownerTickets.currentLength);
    uint targetOwnerTicketsLength = ownerTicketsLength + number;
    uint32[] storage ownerTicketsPositions = ownerTickets.positions;
    if (ownerTicketsPositions.length < targetOwnerTicketsLength) {
      // Expand tickets owned by the user array, this should be rare after the initial stake
      assembly {
        sstore(ownerTicketsPositions.slot, targetOwnerTicketsLength)
      }
    }

    uint ticketPoolLength = uint(ticketPool.currentLength);
    uint targetTicketPoolLength = ticketPoolLength + number;
    TicketPoolPosition[] storage positions = ticketPool.tickets;
    if (positions.length < targetTicketPoolLength) {
      // Expand the pool array if needed
      assembly {
        sstore(positions.slot, targetTicketPoolLength)
      }
    }

    for (uint i = 0; i < number; i++) {
      ticketPool.tickets[ticketPoolLength + i].ownerId = uint16(owner);
      ticketPool.tickets[ticketPoolLength + i].ownerPoolIndex = uint32(
        ownerTicketsLength + i
      );
      ownerTickets.positions[ownerTicketsLength + i] = uint32(
        ticketPoolLength + i
      );
    }

    ticketPool.currentLength += uint32(number);
    ownerTickets.currentLength += uint32(number);
  }

  function _removeFromPool(
    uint256 poolType,
    uint256 subPool,
    uint256 owner,
    uint256 number
  ) internal {
    TicketPool storage ticketPool = _pools[poolType][subPool];
    OwnerTickets storage ownerTickets = _ownedTickets[poolType][subPool][
      uint16(owner)
    ];
    uint ownerTicketsLength = uint(ownerTickets.currentLength);
    uint ticketPoolLength = uint(ticketPool.currentLength);

    require(ownerTicketsLength >= number);
    require(ticketPoolLength >= number);

    for (uint i = 0; i < number; i++) {
      uint replacedTicketIndex = ownerTickets.positions[
        ownerTicketsLength - i - 1
      ];

      // gas optimization, tickets at the end are discarded anyway
      if (replacedTicketIndex > ticketPoolLength - number) {
        continue;
      }

      TicketPoolPosition storage replacedTicket = ticketPool.tickets[
        replacedTicketIndex
      ];
      TicketPoolPosition storage lastTicket = ticketPool.tickets[
        ticketPoolLength - i - 1
      ];
      _ownedTickets[poolType][subPool][lastTicket.ownerId].positions[
        lastTicket.ownerPoolIndex
      ] = uint32(replacedTicketIndex);
      replacedTicket.ownerPoolIndex = lastTicket.ownerPoolIndex;
      replacedTicket.ownerId = lastTicket.ownerId;
    }

    ticketPool.currentLength -= uint32(number);
    ownerTickets.currentLength -= uint32(number);
  }

  function _findRandom(
    uint256 poolType,
    uint256 subType,
    uint256 number,
    uint256 randomBase
  ) internal view returns (uint[] memory result, uint256 nextRandomBase) {
    TicketPool storage pool = _pools[poolType][subType];

    require(pool.currentLength > 0 || number == 0);
    nextRandomBase = randomBase;

    uint randomNumber;
    result = new uint[](number);
    for (uint i = 0; i < number; i++) {
      (randomNumber, nextRandomBase) = Random.getNextRandom(
        nextRandomBase,
        pool.currentLength
      );
      result[i] = pool.tickets[randomNumber].ownerId;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IConnector {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Realm is ERC721Enumerable, ReentrancyGuard, Ownable {
  bytes internal constant TABLE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  uint256 private constant REALM_SIZE = 10 ** 6 * 3;
  uint256 private constant DEFAULT_WEALTH = 1000;
  uint256 private constant ACTION_HOURS = 12 hours;

  uint256 public price = 10000000000000000;
  uint256 public partnerPrice = 5000000000000000;
  uint256 public supply = 10000;

  uint256[35] private PROBABILITY = [
    2,
    3,
    5,
    7,
    11,
    13,
    17,
    19,
    23,
    25,
    29,
    31,
    37,
    39,
    41,
    43,
    47,
    51,
    53,
    57,
    59,
    61,
    65,
    67,
    71,
    75,
    77,
    79,
    83,
    85,
    89,
    92,
    94,
    96,
    100
  ];

  string[35] public features = [
    "Pond", // 0
    "Valley", // 1
    "Gulf", // 2
    "Basin", // 3
    "Butte", // 4
    "Canal", // 5
    "Cape", // 6
    "Prairie", // 7
    "Plateau", // 8
    "Mesa", // 9
    "Peninsula", // 10
    "River", // 11
    "Sea", // 12
    "Cove", // 13
    "Lake", // 14
    "Swamp", // 15
    "Tundra", // 16
    "Bay", // 17
    "Ice shelf", // 18
    "Dune", // 19
    "Fjord", // 20
    "Geyser", // 21
    "Glacier", // 22
    "Ocean", // 23
    "Desert", // 24
    "Biosphere", // 25
    "Lagoon", // 26
    "Mountain", // 27
    "Island", // 28
    "Canyon", // 29
    "Cave", // 30
    "Oasis", // 31
    "Waterfall", // 32
    "Reef", // 33
    "Volcano" // 34
  ];

  struct realm {
    string name;
    uint256 size;
    uint256 createdAt;
    bool partner;
  }

  struct Connector {
    address _contract;
    uint256 start;
    uint256 end;
    bool exists;
  }

  mapping(uint256 => realm) public realms;
  mapping(uint256 => uint256) public wealth;
  mapping(uint256 => uint256) public explorer;
  mapping(uint256 => uint256) public explorerTime;
  mapping(uint256 => uint256) public terraformTime;
  mapping(address => Connector) public connectors;
  mapping(uint256 => mapping(uint256 => uint256)) public realmFeatures;

  event RealmCreated(
    string name,
    uint256 size,
    bool partner,
    string feature1,
    string feature2,
    string feature3
  );
  event Explored(
    uint256 realmId,
    uint256 explored,
    uint256 wealthGained,
    uint256 totalExplored,
    uint256 totalWealth
  );
  event Terraform(
    uint256 realmId,
    string feature1,
    string feature2,
    string feature3
  );
  event ConnectorCreated(address _contract, uint256 start, uint256 end);
  event ConnectorRemoved(address _contract);
  event WealthSpent(uint256 realmId, uint256 WealthSpent, uint256 totalWealth);

  constructor() ERC721("Realm", "REALM") Ownable() {}

  function explore(uint256 _realmId) external {
    require(_isApprovedOrOwner(msg.sender, _realmId));
    require(
      block.timestamp > explorerTime[_realmId],
      "You are currently exploring"
    );
    require(
      explorer[_realmId] < realms[_realmId].size,
      "You've explored the whole map"
    );

    uint256 _wealthGained = _random(wealth[_realmId], DEFAULT_WEALTH) +
      DEFAULT_WEALTH;

    explorer[_realmId] += _wealthGained;
    wealth[_realmId] += _wealthGained;

    // You can explore every 12 hours
    explorerTime[_realmId] = block.timestamp + ACTION_HOURS;

    emit Explored(
      _realmId,
      _wealthGained,
      _wealthGained,
      explorer[_realmId],
      wealth[_realmId]
    );
  }

  function spendWealth(uint256 _realmId, uint256 _wealth) external {
    require(_wealth <= wealth[_realmId], "Not enough wealth");
    require(_isApprovedOrOwner(msg.sender, _realmId));

    wealth[_realmId] -= _wealth;

    emit WealthSpent(_realmId, _wealth, wealth[_realmId]);
  }

  function terraform(uint256 _realmId, uint256 _feature) external {
    require(_isApprovedOrOwner(msg.sender, _realmId));
    require(_feature <= 2, "Feature must be 0 to 2");
    require(block.timestamp > terraformTime[_realmId], "Allowed once a year");

    uint256 _newFeatureId = _random(realms[_realmId].size, features.length);

    // Update feature
    realmFeatures[_realmId][_feature] = _newFeatureId;

    // Allowed once a year
    terraformTime[_realmId] = block.timestamp + 365 days;

    emit Terraform(
      _realmId,
      features[realmFeatures[_realmId][0]],
      features[realmFeatures[_realmId][1]],
      features[realmFeatures[_realmId][2]]
    );
  }

  function claim(
    uint256 _realmId,
    string memory _name
  ) external payable nonReentrant {
    require(msg.value >= price, "Eth sent is not enough");
    require(_realmId > 5 && _realmId <= supply, "_realmId invalid");
    require(!_exists(_realmId), "_realmId invalid");

    _createRealm(_realmId, _name, false);
    _safeMint(_msgSender(), _realmId);
  }

  function claimAsPartner(
    address _contract,
    uint256 _partnerId,
    uint256 _realmId,
    string memory _name
  ) external payable nonReentrant {
    require(connectors[_contract].exists, "Contract not allowed");
    require(msg.value >= partnerPrice, "Eth sent is not enough");
    require(
      _realmId > connectors[_contract].start &&
        _realmId < connectors[_contract].end,
      "_realmId not in range"
    );
    require(!_exists(_realmId), "_realmId doesn't exist");

    IConnector connector = IConnector(_contract);

    require(
      connector.ownerOf(_partnerId) == msg.sender,
      "You do not own the _partnerId"
    );

    _createRealm(_realmId, _name, true);
    _safeMint(_msgSender(), _realmId);
  }

  function ownerClaim(
    uint256 _realmId,
    string memory _name
  ) external nonReentrant onlyOwner {
    require(_realmId <= 5, "_realmId invalid");
    require(!_exists(_realmId), "_realmId invalid");

    _createRealm(_realmId, _name, false);
    _safeMint(owner(), _realmId);
  }

  function setPrice(uint256 _newPrice, uint256 _type) external onlyOwner {
    if (_type == 0) {
      price = _newPrice;
    } else {
      partnerPrice = _newPrice;
    }
  }

  function setSupply(uint256 _supply) external onlyOwner {
    supply = _supply;
  }

  function setConnector(
    address _contract,
    uint256 _start,
    uint256 _end
  ) external onlyOwner {
    connectors[_contract]._contract = _contract;
    connectors[_contract].start = _start;
    connectors[_contract].end = _end;
    connectors[_contract].exists = true;

    emit ConnectorCreated(_contract, _start, _end);
  }

  function removeConnector(address _contract) external onlyOwner {
    delete connectors[_contract];

    emit ConnectorRemoved(_contract);
  }

  function getRealm(
    uint256 _realmId
  ) external view returns (string memory, uint256, uint256, bool) {
    return (
      realms[_realmId].name,
      realms[_realmId].size,
      realms[_realmId].createdAt,
      realms[_realmId].partner
    );
  }

  function hasConnector(address _contract) external view returns (bool) {
    return connectors[_contract].exists;
  }

  function ownerWithdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function tokenURI(
    uint256 _realmId
  ) public view override returns (string memory) {
    string[5] memory _parts;

    _parts[
      0
    ] = '<?xml version="1.0" encoding="UTF-8"?><svg width="350px" height="350px" viewBox="0 0 350 350" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><rect fill="#ffb300" x="0" y="0" width="350" height="350"></rect><text x="50%" y="40%" dominant-baseline="middle" text-anchor="middle" fill-opacity="50%" font-size="65px" fill="#fff" font-family="Georgia">Realm</text><text x="50%" y="62%" fill-opacity="100%" fill="#fff" dominant-baseline="middle" text-anchor="middle" font-size="24px" font-family="Georgia">';
    _parts[1] = realms[_realmId].name;
    _parts[
      2
    ] = '</text><text x="50%" y="69%" fill-opacity="100%" fill="#fff" dominant-baseline="middle" text-anchor="middle" font-size="12px" font-family="Georgia">';
    _parts[3] = _featureNames(_realmId);
    _parts[
      4
    ] = '</text><line class="line" stroke-width="5" x1="125" x2="137" y1="185" y2="185"></line> <line class="line" stroke-width="5" x1="147" x2="148" y1="185" y2="185"></line> <line class="line" stroke-width="5" x1="158" x2="170" y1="185" y2="185"></line> <line class="line" stroke-width="5" x1="180" x2="181" y1="185" y2="185"></line> <line class="line" stroke-width="5" x1="191" x2="192" y1="185" y2="185"></line> <line class="line" stroke-width="5" x1="202" x2="214" y1="185" y2="185"></line> <line class="line" stroke-width="5" x1="224" x2="225" y1="185" y2="185"></line><style type="text/css">.line{stroke:white;stroke-linecap:round;opacity:50%}</style></svg>';

    string memory _output = string(
      abi.encodePacked(_parts[0], _parts[1], _parts[2], _parts[3], _parts[4])
    );

    string memory _atrrOutput = _makeAttributeParts(_realmId);
    string memory _json = _encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Realm #',
            _toString(_realmId),
            '", "description": "Discover your Realm. Explore. Mine. Research. Build.", "image": "data:image/svg+xml;base64,',
            _encode(bytes(_output)),
            '"',
            ',"attributes":',
            _atrrOutput,
            "}"
          )
        )
      )
    );
    _output = string(abi.encodePacked("data:application/json;base64,", _json));

    return _output;
  }

  function _createRealm(
    uint256 _realmId,
    string memory _name,
    bool _partner
  ) internal {
    realms[_realmId].name = _name;
    realms[_realmId].size = _randomFromString(_name, REALM_SIZE) + REALM_SIZE;
    realms[_realmId].createdAt = block.timestamp;
    realms[_realmId].partner = _partner;

    realmFeatures[_realmId][0] = _randomFromString(
      realms[_realmId].name,
      features.length
    );
    realmFeatures[_realmId][1] = _random(
      realms[_realmId].size,
      features.length
    );
    realmFeatures[_realmId][2] = _random(
      realms[_realmId].createdAt,
      features.length
    );

    emit RealmCreated(
      realms[_realmId].name,
      realms[_realmId].size,
      _partner,
      features[realmFeatures[_realmId][0]],
      features[realmFeatures[_realmId][1]],
      features[realmFeatures[_realmId][2]]
    );
  }

  function _random(
    uint256 _salt,
    uint256 _limit
  ) internal view returns (uint256) {
    return
      uint256(
        keccak256(abi.encodePacked(block.number, block.timestamp, _salt))
      ) % _limit;
  }

  function _randomFromString(
    string memory _salt,
    uint256 _limit
  ) internal view returns (uint256) {
    return
      uint256(
        keccak256(abi.encodePacked(block.number, block.timestamp, _salt))
      ) % _limit;
  }

  function _rarity(
    uint256 _salt,
    uint256 _limit
  ) internal view returns (uint256) {
    uint256 _rand = _randomFromString(string(abi.encodePacked(_salt)), _limit);

    uint256 j = 0;
    for (; j < PROBABILITY.length; j++) {
      if (_rand <= PROBABILITY[j]) {
        break;
      }
    }
    return j;
  }

  function _makeAttributeParts(
    uint256 _realmId
  ) internal view returns (string memory) {
    string[9] memory _parts;

    _parts[0] = '[{ "trait_type": "Realm", "value": "';
    _parts[1] = realms[_realmId].name;
    _parts[2] = '" }, { "trait_type": "Geographical Feature 1", "value": "';
    _parts[3] = features[realmFeatures[_realmId][0]];
    _parts[4] = '" }, { "trait_type": "Geographical Feature 2", "value": "';
    _parts[5] = features[realmFeatures[_realmId][1]];
    _parts[6] = '" }, { "trait_type": "Geographical Feature 3", "value": "';
    _parts[7] = features[realmFeatures[_realmId][2]];
    _parts[8] = '" }]';

    string memory _output = string(
      abi.encodePacked(_parts[0], _parts[1], _parts[2], _parts[3], _parts[4])
    );
    _output = string(
      abi.encodePacked(_output, _parts[5], _parts[6], _parts[7], _parts[8])
    );

    return _output;
  }

  function _featureNames(
    uint256 _realmId
  ) internal view returns (string memory) {
    return
      string(
        abi.encodePacked(
          features[realmFeatures[_realmId][0]],
          " | ",
          features[realmFeatures[_realmId][1]],
          " | ",
          features[realmFeatures[_realmId][2]]
        )
      );
  }

  function _toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  function _encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }

  // TEST CODE
  function setFeatures(
    uint256 _realmId,
    uint256[] calldata _features
  ) external {
    realmFeatures[_realmId][0] = _features[0];
    realmFeatures[_realmId][1] = _features[1];
    realmFeatures[_realmId][2] = _features[2];
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRandomStructureBurner {
  function availableUsageCounts(
    address _structureAddress,
    uint[] calldata _structureIds,
    uint[] calldata _lossPerUsage
  ) external view returns (uint[] memory);

  function randomReduceDurability(
    uint _randomBase,
    address _structureAddress,
    uint[] calldata _structureIds,
    uint[] calldata _durabilityLoss,
    uint[] calldata _amounts,
    address _durabilityLossHandler
  ) external returns (uint nextRandomBase);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRandomStructureBurnerDurabilityLossHandler {
  function handleDurabilityLoss(
    uint[] calldata realmIds,
    uint[][] calldata structureIds,
    uint[][] calldata durabilityLoss
  ) external;

  function handleDurabilityLoss(
    uint realmId,
    uint structureId,
    uint durabilityLoss
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "../lib/FloatingPointConstants.sol";

struct EpochAverageStorageConfig {
  uint256 baseWeight;
  uint256 epochWeight;
  uint256 totalWeight;
}

abstract contract AbstractEpochAverageStorage {
  mapping(uint256 => EpochAverageStorageConfig) public config;
  mapping(uint256 => mapping(uint256 => uint256)) public baseValueEpoch;
  mapping(uint256 => mapping(uint256 => uint256)) public baseValue;

  function _getConfig(
    uint256 _group,
    uint256 _subGroup
  ) internal view virtual returns (EpochAverageStorageConfig memory);

  function _getCurrentValue(
    uint256 _group,
    uint256 _subGroup
  ) internal view virtual returns (uint256);

  function _getPredictedNextValue(
    uint256 _group,
    uint256 _subGroup
  ) internal view virtual returns (uint256);

  function _getCurrentEpoch(
    uint256 _group,
    uint256 _subGroup
  ) internal view virtual returns (uint256);

  function _predictNextValue(
    uint256 _group,
    uint256 _subGroup
  ) internal view returns (uint256 result) {
    EpochAverageStorageConfig memory cfg = _getConfig(_group, _subGroup);

    result = _getValueView(_group, _subGroup);
    uint256 predictedValue = _getPredictedNextValue(_group, _subGroup);
    result =
      (result * cfg.baseWeight + predictedValue * cfg.epochWeight) /
      cfg.totalWeight;
    if (result == 0 && predictedValue > 0) {
      result = 1;
    }
  }

  function _getValue(
    uint256 _group,
    uint256 _subGroup
  ) internal returns (uint256 result) {
    uint currentEpoch = _getCurrentEpoch(_group, _subGroup);
    if (currentEpoch == baseValueEpoch[_group][_subGroup]) {
      return baseValue[_group][_subGroup];
    }
    result = _getValueView(_group, _subGroup);
    baseValue[_group][_subGroup] = result;
    baseValueEpoch[_group][_subGroup] = currentEpoch;
  }

  function _getValueView(
    uint256 _group,
    uint256 _subGroup
  ) internal view returns (uint256 result) {
    result = baseValue[_group][_subGroup];
    uint256 currentEpoch = _getCurrentEpoch(_group, _subGroup);
    if (currentEpoch == baseValueEpoch[_group][_subGroup]) {
      return result;
    }

    uint currentVal = _getCurrentValue(_group, _subGroup);
    EpochAverageStorageConfig memory cfg = _getConfig(_group, _subGroup);
    result =
      (result * cfg.baseWeight + currentVal * cfg.epochWeight) /
      cfg.totalWeight;
    if (result == 0 && currentVal > 0) {
      result = 1;
    }
  }

  function _getValueBatch(
    uint256 _group,
    uint256[] calldata _subGroups
  ) internal returns (uint256[] memory results) {
    results = new uint256[](_subGroups.length);
    for (uint i = 0; i < _subGroups.length; i++) {
      results[i] = _getValue(_group, _subGroups[i]);
    }
  }

  function _getValueViewBatch(
    uint256 _group,
    uint256[] calldata _subGroups
  ) internal view returns (uint256[] memory results) {
    results = new uint256[](_subGroups.length);
    for (uint i = 0; i < _subGroups.length; i++) {
      results[i] = _getValueView(_group, _subGroups[i]);
    }
  }

  function _getPredictionBatch(
    uint256 _group,
    uint256[] calldata _subGroups
  ) internal view returns (uint256[] memory results) {
    results = new uint256[](_subGroups.length);
    for (uint i = 0; i < _subGroups.length; i++) {
      results[i] = _predictNextValue(_group, _subGroups[i]);
    }
  }

  function _forceUpdateBaseValue(
    uint _group,
    uint _subgroup,
    uint _newValue
  ) internal {
    baseValue[_group][_subgroup] = _newValue;
    baseValueEpoch[_group][_subgroup] = _getCurrentEpoch(_group, _subgroup);
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

library ArrayUtils {
  error ArrayLengthMismatch(uint _length1, uint _length2);
  error InvalidArrayOrder(uint index);

  function ensureSameLength(uint _l1, uint _l2) internal pure {
    if (_l1 != _l2) {
      revert ArrayLengthMismatch(_l1, _l2);
    }
  }

  function ensureSameLength(uint _l1, uint _l2, uint _l3) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
  }

  function ensureSameLength(
    uint _l1,
    uint _l2,
    uint _l3,
    uint _l4
  ) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
  }

  function ensureSameLength(
    uint _l1,
    uint _l2,
    uint _l3,
    uint _l4,
    uint _l5
  ) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
    ensureSameLength(_l1, _l5);
  }

  function checkAddressesForDuplicates(
    address[] memory _tokenAddrs
  ) internal pure {
    address lastAddress;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (lastAddress > _tokenAddrs[i]) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
    }
  }

  function checkForDuplicates(uint[] memory _ids) internal pure {
    uint lastId;
    for (uint i = 0; i < _ids.length; i++) {
      if (lastId > _ids[i]) {
        revert InvalidArrayOrder(i);
      }
      lastId = _ids[i];
    }
  }

  function checkForDuplicates(
    address[] memory _tokenAddrs,
    uint[] memory _tokenIds
  ) internal pure {
    address lastAddress;
    int256 lastTokenId = -1;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (_tokenAddrs[i] > lastAddress) {
        lastTokenId = -1;
      }

      if (_tokenAddrs[i] < lastAddress || int(_tokenIds[i]) <= lastTokenId) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
      lastTokenId = int(_tokenIds[i]);
    }
  }

  function toSingleValueDoubleArray(
    uint[] memory _vals
  ) internal pure returns (uint[][] memory result) {
    result = new uint[][](_vals.length);
    for (uint i = 0; i < _vals.length; i++) {
      result[i] = ArrayUtils.toMemoryArray(_vals[i], 1);
    }
  }

  function toMemoryArray(
    uint _value,
    uint _length
  ) internal pure returns (uint[] memory result) {
    result = new uint[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _value;
    }
  }

  function toMemoryArray(
    uint[] calldata _value
  ) internal pure returns (uint[] memory result) {
    result = new uint[](_value.length);
    for (uint i = 0; i < _value.length; i++) {
      result[i] = _value[i];
    }
  }

  function toMemoryArray(
    address _address,
    uint _length
  ) internal pure returns (address[] memory result) {
    result = new address[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _address;
    }
  }

  function toMemoryArray(
    address[] calldata _addresses
  ) internal pure returns (address[] memory result) {
    result = new address[](_addresses.length);
    for (uint i = 0; i < _addresses.length; i++) {
      result[i] = _addresses[i];
    }
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Unlicensed

import "../lib/FloatingPointConstants.sol";

uint256 constant MASK_128 = ((1 << 128) - 1);
uint128 constant MASK_64 = ((1 << 64) - 1);

library Epoch {
  // Converts a given timestamp to an epoch using the specified duration and offset.
  // Example for battle timers resetting at noon UTC is: _duration = 1 days; _offset = 12 hours;
  function toEpochNumber(
    uint256 _timestamp,
    uint256 _duration,
    uint256 _offset
  ) internal pure returns (uint256) {
    return (_timestamp + _offset) / _duration;
  }

  // Here we assume that _config is a packed _duration (left 64 bits) and _offset (right 64 bits)
  function toEpochNumber(uint256 _timestamp, uint128 _config) internal pure returns (uint256) {
    return (_timestamp + (_config & MASK_64)) / ((_config >> 64) & MASK_64);
  }

  // Returns a value between 0 and ONE_HUNDRED which is the percentage of "completeness" of the epoch
  // result variable is reused for memory efficiency
  function toEpochCompleteness(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256 result) {
    result = (_config >> 64) & MASK_64;
    result = (ONE_HUNDRED * ((_timestamp + (_config & MASK_64)) % result)) / result;
  }

  // Converts a given epoch to a timestamp at the start of the epoch
  function epochToTimestamp(
    uint256 _epoch,
    uint128 _config
  ) internal pure returns (uint256 result) {
    result = _epoch * ((_config >> 64) & MASK_64);
    if (result > 0) {
      result -= (_config & MASK_64);
    }
  }

  // Create a config for the function above
  function toConfig(uint64 _duration, uint64 _offset) internal pure returns (uint128) {
    return (uint128(_duration) << 64) | uint128(_offset);
  }

  // Pack the epoch number with the config into a single uint256 for mappings
  function packEpoch(uint256 _epochNumber, uint128 _config) internal pure returns (uint256) {
    return (uint256(_config) << 128) | uint128(_epochNumber);
  }

  // Convert timestamp to Epoch and pack it with the config into a single uint256 for mappings
  function packTimestampToEpoch(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256) {
    return packEpoch(toEpochNumber(_timestamp, _config), _config);
  }

  // Unpack packedEpoch to epochNumber and config
  function unpack(
    uint256 _packedEpoch
  ) internal pure returns (uint256 epochNumber, uint128 config) {
    config = uint128(_packedEpoch >> 128);
    epochNumber = _packedEpoch & MASK_128;
  }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
  /**
   * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
   * @return block number as int
   */
  function arbBlockNumber() external view returns (uint256);

  /**
   * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
   * @return block hash
   */
  function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

  /**
   * @notice Gets the rollup's unique chain identifier
   * @return Chain identifier as int
   */
  function arbChainID() external view returns (uint256);

  /**
   * @notice Get internal version number identifying an ArbOS build
   * @return version number as int
   */
  function arbOSVersion() external view returns (uint256);

  /**
   * @notice Returns 0 since Nitro has no concept of storage gas
   * @return uint 0
   */
  function getStorageGasAvailable() external view returns (uint256);

  /**
   * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
   * @dev this call has been deprecated and may be removed in a future release
   * @return true if current execution frame is not a call by another L2 contract
   */
  function isTopLevelCall() external view returns (bool);

  /**
   * @notice map L1 sender contract address to its L2 alias
   * @param sender sender address
   * @param unused argument no longer used
   * @return aliased sender address
   */
  function mapL1SenderContractAddressToL2Alias(
    address sender,
    address unused
  ) external pure returns (address);

  /**
   * @notice check if the caller (of this caller of this) is an aliased L1 contract address
   * @return true iff the caller's address is an alias for an L1 contract address
   */
  function wasMyCallersAddressAliased() external view returns (bool);

  /**
   * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
   * @return address of the caller's caller, without applying L1 contract address aliasing
   */
  function myCallersAddressWithoutAliasing() external view returns (address);

  /**
   * @notice Send given amount of Eth to dest from sender.
   * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
   * @param destination recipient address on L1
   * @return unique identifier for this L2-to-L1 transaction.
   */
  function withdrawEth(address destination) external payable returns (uint256);

  /**
   * @notice Send a transaction to L1
   * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
   * to a contract address without any code (as enforced by the Bridge contract).
   * @param destination recipient address on L1
   * @param data (optional) calldata for L1 contract call
   * @return a unique identifier for this L2-to-L1 transaction.
   */
  function sendTxToL1(address destination, bytes calldata data) external payable returns (uint256);

  /**
   * @notice Get send Merkle tree .state
   * @return size number of sends in the history
   * @return root root hash of the send history
   * @return partials hashes of partial subtrees in the send history tree
   */
  function sendMerkleTreeState()
    external
    view
    returns (uint256 size, bytes32 root, bytes32[] memory partials);

  /**
   * @notice creates a send txn from L2 to L1
   * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
   */
  event L2ToL1Tx(
    address caller,
    address indexed destination,
    uint256 indexed hash,
    uint256 indexed position,
    uint256 arbBlockNum,
    uint256 ethBlockNum,
    uint256 timestamp,
    uint256 callvalue,
    bytes data
  );

  /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
  event L2ToL1Transaction(
    address caller,
    address indexed destination,
    uint256 indexed uniqueId,
    uint256 indexed batchNumber,
    uint256 indexInBatch,
    uint256 arbBlockNum,
    uint256 ethBlockNum,
    uint256 timestamp,
    uint256 callvalue,
    bytes data
  );

  /**
   * @notice logs a merkle branch for proof synthesis
   * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
   * @param hash the merkle hash
   * @param position = (level << 192) + leaf
   */
  event SendMerkleUpdate(uint256 indexed reserved, bytes32 indexed hash, uint256 indexed position);

  error InvalidBlockNumber(uint256 requested, uint256 current);
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IEpochConfigurable {
  function currentEpoch() external view returns (uint);

  function epochAtTimestamp(uint _timestamp) external view returns (uint);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./IArbSys.sol";

//=========================================================================================================================================
// We're trying to normalize all chances close to 100%, which is 100 000 with decimal point 10^3. Assuming this, we can get more "random"
// numbers by dividing the "random" number by this prime. To be honest most primes larger than 100% should work, but to be safe we'll
// use an order of magnitude higher (10^3) relative to the decimal point
// We're using uint256 (2^256 ~= 10^77), which means we're safe to derive 8 consecutive random numbers from each hash.
// If we, by any chance, run out of random numbers (hash being lower than the range) we can in turn
// use the remainder of the hash to regenerate a new random number.
// Example: assuming our hash function result would be 1132134687911000 (shorter number picked for explanation) and we're using
// % 100000 range for our drop chance. The first "random" number is 11000. We then divide 1000000011000 by the 100000037 prime,
// leaving us at 11321342. The second derived random number would be 11321342 % 100000 = 21342. 11321342/100000037 is in turn less than
// 100000037, so we'll instead regenerate a new hash using 11321342.
// Primes are used for additional safety, but we could just deal with the "range".
//=========================================================================================================================================
uint256 constant MIN_SAFE_NEXT_NUMBER_PRIME = 200033;
uint256 constant HIGH_RANGE_PRIME_OFFSET = 13;

library Random {
  function startRandomBase(uint256 _highSalt, uint256 _lowSalt) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            _getPreviousBlockhash(),
            block.timestamp,
            msg.sender,
            _lowSalt,
            _highSalt
          )
        )
      );
  }

  function getNextRandom(
    uint256 _randomBase,
    uint256 _range
  ) internal view returns (uint256, uint256) {
    uint256 nextNumberSeparator = MIN_SAFE_NEXT_NUMBER_PRIME > _range
      ? MIN_SAFE_NEXT_NUMBER_PRIME
      : (_range + HIGH_RANGE_PRIME_OFFSET);
    uint256 nextBaseNumber = _randomBase / nextNumberSeparator;
    if (nextBaseNumber > nextNumberSeparator) {
      return (_randomBase % _range, nextBaseNumber);
    }
    nextBaseNumber = uint256(
      keccak256(abi.encodePacked(_getPreviousBlockhash(), msg.sender, _randomBase, _range))
    );
    return (nextBaseNumber % _range, nextBaseNumber / nextNumberSeparator);
  }

  function _getPreviousBlockhash() internal view returns (bytes32) {
    // Arbitrum One, Nova, Goerli, Sepolia, Stylus or Rinkeby
    if (
      block.chainid == 42161 ||
      block.chainid == 42170 ||
      block.chainid == 421613 ||
      block.chainid == 421614 ||
      block.chainid == 23011913 ||
      block.chainid == 421611
    ) {
      return ArbSys(address(0x64)).arbBlockHash(ArbSys(address(0x64)).arbBlockNumber() - 1);
    } else {
      // WARNING: THIS IS HIGHLY INSECURE ON ETH MAINNET, it is currently used mostly for testing
      return blockhash(block.number - 1);
    }
  }
}