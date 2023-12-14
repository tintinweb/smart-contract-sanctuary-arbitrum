// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.20;

import {IERC721} from "./IERC721.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";
import {IERC721Metadata} from "./extensions/IERC721Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {Strings} from "../../utils/Strings.sol";
import {IERC165, ERC165} from "../../utils/introspection/ERC165.sol";
import {IERC721Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Errors {
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    mapping(uint256 tokenId => address) private _owners;

    mapping(address owner => uint256) private _balances;

    mapping(uint256 tokenId => address) private _tokenApprovals;

    mapping(address owner => mapping(address operator => bool)) private _operatorApprovals;

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
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _requireOwned(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
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
    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId, _msgSender());
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireOwned(tokenId);

        return _getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     *
     * IMPORTANT: Any overrides to this function that add ownership of tokens not tracked by the
     * core ERC721 logic MUST be matched with the use of {_increaseBalance} to keep balances
     * consistent with ownership. The invariant to preserve is that for any address `a` the value returned by
     * `balanceOf(a)` must be equal to the number of tokens such that `_ownerOf(tokenId)` is `a`.
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns the approved address for `tokenId`. Returns 0 if `tokenId` is not minted.
     */
    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `owner`'s tokens, or `tokenId` in
     * particular (ignoring whether it is owned by `owner`).
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    /**
     * @dev Checks if `spender` can operate on `tokenId`, assuming the provided `owner` is the actual owner.
     * Reverts if `spender` does not have approval from the provided `owner` for the given token or for all its assets
     * the `spender` for the specific `tokenId`.
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view virtual {
        if (!_isAuthorized(owner, spender, tokenId)) {
            if (owner == address(0)) {
                revert ERC721NonexistentToken(tokenId);
            } else {
                revert ERC721InsufficientApproval(spender, tokenId);
            }
        }
    }

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * NOTE: the value is limited to type(uint128).max. This protect against _balance overflow. It is unrealistic that
     * a uint256 would ever overflow from increments when these increments are bounded to uint128 values.
     *
     * WARNING: Increasing an account's balance using this function tends to be paired with an override of the
     * {_ownerOf} function to resolve the ownership of the corresponding tokens so that balances and ownership
     * remain consistent with one another.
     */
    function _increaseBalance(address account, uint128 value) internal virtual {
        unchecked {
            _balances[account] += value;
        }
    }

    /**
     * @dev Transfers `tokenId` from its current owner to `to`, or alternatively mints (or burns) if the current owner
     * (or `to`) is the zero address. Returns the owner of the `tokenId` before the update.
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that
     * `auth` is either the owner of the token, or approved to operate on the token (by the owner).
     *
     * Emits a {Transfer} event.
     *
     * NOTE: If overriding this function in a way that tracks balances, see also {_increaseBalance}.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {
        address from = _ownerOf(tokenId);

        // Perform (optional) operator check
        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }

        // Execute the update
        if (from != address(0)) {
            // Clear approval. No need to re-authorize or emit the Approval event
            _approve(address(0), tokenId, address(0), false);

            unchecked {
                _balances[from] -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                _balances[to] += 1;
            }
        }

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        return from;
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
    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner != address(0)) {
            revert ERC721InvalidSender(address(0));
        }
    }

    /**
     * @dev Mints `tokenId`, transfers it to `to` and checks for `to` acceptance.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        _checkOnERC721Received(address(0), to, tokenId, data);
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
    function _burn(uint256 tokenId) internal {
        address previousOwner = _update(address(0), tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
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
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        } else if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking that contract recipients
     * are aware of the ERC721 standard to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is like {safeTransferFrom} in the sense that it invokes
     * {IERC721Receiver-onERC721Received} on the receiver, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `tokenId` token must exist and be owned by `from`.
     * - `to` cannot be the zero address.
     * - `from` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _safeTransfer(from, to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeTransfer-address-address-uint256-}[`_safeTransfer`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that `auth` is
     * either the owner of the token, or approved to operate on all tokens held by this owner.
     *
     * Emits an {Approval} event.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address to, uint256 tokenId, address auth) internal {
        _approve(to, tokenId, auth, true);
    }

    /**
     * @dev Variant of `_approve` with an optional flag to enable or disable the {Approval} event. The event is not
     * emitted in the context of transfers.
     */
    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
        // Avoid reading the owner unless necessary
        if (emitEvent || auth != address(0)) {
            address owner = _requireOwned(tokenId);

            // We do not use _isAuthorized because single-token approvals should not be able to call approve
            if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
                revert ERC721InvalidApprover(auth);
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
        }

        _tokenApprovals[tokenId] = to;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Requirements:
     * - operator can't be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (operator == address(0)) {
            revert ERC721InvalidOperator(operator);
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` doesn't have a current owner (it hasn't been minted, or it has been burned).
     * Returns the owner.
     *
     * Overrides to ownership logic should be done to {_ownerOf}.
     */
    function _requireOwned(uint256 tokenId) internal view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return owner;
    }

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address. This will revert if the
     * recipient doesn't accept the token transfer. The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.20;

import {IERC721} from "../IERC721.sol";

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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
     * - The `operator` cannot be the address zero.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

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
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Base64.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

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
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
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
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

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
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
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
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
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
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract Test is ERC721 {
    uint256 tokenId = 0;
    constructor() ERC721("Mock NFT", "VEMNFT") {}

    function mint(address to) public {
        ++tokenId;
        uint _tokenId = tokenId;
        _mint(to, _tokenId);
    }

    function fake() public view returns (string memory){
        string memory svgImage = '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 124 124" fill="none"><rect width="124" height="124" rx="24" fill="#F97316"/><path d="M19.375 36.782v63.843a4 4 0 0 0 4 4h63.843c3.564 0 5.348-4.309 2.829-6.828L26.203 33.953c-2.52-2.52-6.828-.735-6.828 2.829Z" fill="#fff"/><circle cx="63.211" cy="37.539" r="18.164" fill="#000"/><rect opacity=".4" x="81.133" y="80.72" width="17.569" height="17.388" rx="4" transform="rotate(-45 81.133 80.72)" fill="#FDBA74"/></svg>';
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "SVG NFT #',
            '",',
            '"description": "SVG NFT on Klaytn",',
            '"image": "',
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(bytes(svgImage))
            ),
            '"',
            "}"
        );

        return
            string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(dataURI)
            )
        );
    }


    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            "data:application/json;base64,eyJuYW1lIjogIlNWRyBORlQgIyIsImRlc2NyaXB0aW9uIjogIlNWRyBORlQgb24gS2xheXRuIiwiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpTWpBeUlpQm9aV2xuYUhROUlqSTNPQ0lnZG1sbGQwSnZlRDBpTUNBd0lEUXlNQ0ExTnpnaUlHWnBiR3c5SW01dmJtVWlJSGh0Ykc1elBTSm9kSFJ3T2k4dmQzZDNMbmN6TG05eVp5OHlNREF3TDNOMlp5SWdlRzFzYm5NNmVHeHBibXM5SW1oMGRIQTZMeTkzZDNjdWR6TXViM0puTHpFNU9Ua3ZlR3hwYm1zaUlENDhaeUJqYkdsd0xYQmhkR2c5SW5WeWJDZ2pZMnhwY0RCZk5USXpOVjgwTURneE9UVXBJajQ4Y0dGMGFDQmtQU0pOTXprMExqZ3dPU0F3U0RJekxqZ3dPRFpETVRBdU5UVXpPQ0F3SUMwd0xqRTVNVFF3TmlBeE1DNDNORFV5SUMwd0xqRTVNVFF3TmlBeU5GWTFOVFJETFRBdU1Ua3hOREEySURVMk55NHlOVFVnTVRBdU5UVXpPQ0ExTnpnZ01qTXVPREE0TmlBMU56aElNemswTGpnd09VTTBNRGd1TURZeklEVTNPQ0EwTVRndU9EQTVJRFUyTnk0eU5UVWdOREU0TGpnd09TQTFOVFJXTWpSRE5ERTRMamd3T1NBeE1DNDNORFV5SURRd09DNHdOak1nTUNBek9UUXVPREE1SURCYUlpQm1hV3hzUFNJak1UVTJOVVpGSWk4K1BHY2dabWxzZEdWeVBTSjFjbXdvSTJacGJIUmxjakJmWmw4MU1qTTFYelF3T0RFNU5Ta2lQanhqYVhKamJHVWdZM2c5SWpZMkxqVXlORFFpSUdONVBTSXpOeTR6TkRReUlpQnlQU0l4TURZaUlHWnBiR3c5SWlNME5EY3pSa1lpTHo0OEwyYytQR2NnWm1sc2RHVnlQU0oxY213b0kyWnBiSFJsY2pGZlpsODFNak0xWHpRd09ERTVOU2tpUGp4bGJHeHBjSE5sSUdONFBTSXpNVGd1TXprNUlpQmplVDBpTWprdU9ERTROeUlnY25nOUlqSXhPQzQ1TVRNaUlISjVQU0l4T0RBdU9UUTVJaUJtYVd4c1BTSWpOVFkzUWtaR0lpOCtQQzluUGp4bklHWnBiSFJsY2owaWRYSnNLQ05tYVd4MFpYSXlYMlpmTlRJek5WODBNRGd4T1RVcElqNDhZMmx5WTJ4bElHTjRQU0l5TnpNdU1qZzFJaUJqZVQwaU1qWXpMaklpSUhJOUlqRTBOUzQ0TlNJZ1ptbHNiRDBpSXpjeU9VSkZReUl2UGp3dlp6NDhaeUJtYVd4MFpYSTlJblZ5YkNnalptbHNkR1Z5TTE5bVh6VXlNelZmTkRBNE1UazFLU0krUEdOcGNtTnNaU0JqZUQwaU1qQTVMall6TlNJZ1kzazlJalV3TVM0M01USWlJSEk5SWpFeU5DNHdOVFVpSUdacGJHdzlJaU0zTWpsQ1JVTWlMejQ4TDJjK1BHY2diM0JoWTJsMGVUMGlNQzQySWlCbWFXeDBaWEk5SW5WeWJDZ2pabWxzZEdWeU5GOW1YelV5TXpWZk5EQTRNVGsxS1NJK1BHTnBjbU5zWlNCamVEMGlNVEkxTGpnMk5TSWdZM2s5SWpFNU1TNDFNVFVpSUhJOUlqZ3pMalEwTkRjaUlHWnBiR3c5SWlNM01qbENSVU1pTHo0OEwyYytQQzluUGp4d1lYUm9JR1E5SWsweE1UY2dNRWd6TURKV01qaERNekF5SURNMkxqZ3pOallnTWprMExqZ3pOeUEwTkNBeU9EWWdORFJJTVRNelF6RXlOQzR4TmpNZ05EUWdNVEUzSURNMkxqZ3pOallnTVRFM0lESTRWakJhSWlCbWFXeHNQU0ozYUdsMFpTSWdabWxzYkMxdmNHRmphWFI1UFNJd0xqRWlMejQ4ZEdWNGRDQm1hV3hzUFNJalJqaEdRVVpESWlCNGJXdzZjM0JoWTJVOUluQnlaWE5sY25abElpQnpkSGxzWlQwaWQyaHBkR1V0YzNCaFkyVTZJSEJ5WlNJZ1ptOXVkQzFtWVcxcGJIazlJa0Z5YVdGc0lpQm1iMjUwTFhOcGVtVTlJakU0SWlCbWIyNTBMWGRsYVdkb2REMGlZbTlzWkNJZ2JHVjBkR1Z5TFhOd1lXTnBibWM5SWpCbGJTSStQSFJ6Y0dGdUlIZzlJakUyTUM0MUlpQjVQU0l6TUM0eE5Ua3lJajUyWlZCdmMzUWdUa1pVUEM5MGMzQmhiajRnUEM5MFpYaDBQanh5WldOMElIZzlJakU1TGpZek5EZ2lJSGs5SWpVeU9DSWdkMmxrZEdnOUlqTTRNQ0lnYUdWcFoyaDBQU0l5T0NJZ2NuZzlJamdpSUdacGJHdzlJaU15T0RNNU56VWlJR1pwYkd3dGIzQmhZMmwwZVQwaU1DNHpJaTgrUEhSbGVIUWdabWxzYkQwaUkwWTRSa0ZHUXlJZ2VHMXNPbk53WVdObFBTSndjbVZ6WlhKMlpTSWdjM1I1YkdVOUluZG9hWFJsTFhOd1lXTmxPaUJ3Y21VaUlHWnZiblF0Wm1GdGFXeDVQU0pCY21saGJDSWdabTl1ZEMxemFYcGxQU0l4TkNJZ2JHVjBkR1Z5TFhOd1lXTnBibWM5SWpCbGJTSStQSFJ6Y0dGdUlIZzlJakUxTmk0eE16VWlJSGs5SWpVME5pNDROVFFpUGlZamVHRTVPM0J2YzNRdWRHVmphQ3dnTWpBeU16d3ZkSE53WVc0K1BDOTBaWGgwUGp4bklHOXdZV05wZEhrOUlqQXVNeUkrUEhCaGRHZ2daRDBpVFRNeE15NDVNemNnTWpreExqQXdNa016TVRBdU5qRTFJREk1TUM0Mk9TQXpNRGN1TXpRMUlESTRPUzQwTWpnZ016QTBMalUxT0NBeU9EY3VNVGN4VERnMkxqTXdORE1nTVRFeUxqTTVRemM0TGpjNE1UZ2dNVEEyTGpJNU5pQTNOeTQyTWpNeElEazFMakkxT0RZZ09ETXVOekUzTXlBNE55NDNNell4UXpnNUxqZ3hNRE1nT0RBdU1qRTBNU0F4TURBdU9EVWdOemt1TURVMU15QXhNRGd1TXpjeElEZzFMakUwT0RoTU16STJMall5TlNBeU5Ua3VPVEk1UXpNek5DNHhORGNnTWpZMkxqQXlNeUF6TXpVdU16QTJJREkzTnk0d05qRWdNekk1TGpJeE1pQXlPRFF1TlRnelF6TXlOUzR6TnpjZ01qZzVMak14T0NBek1Ua3VOVGd4SURJNU1TNDFNeklnTXpFekxqa3pOeUF5T1RFdU1EQXlXaUlnWm1sc2JEMGlkWEpzS0NOd1lXbHVkREJmYkdsdVpXRnlYelV5TXpWZk5EQTRNVGsxS1NJdlBqd3ZaejQ4Y0dGMGFDQmtQU0pOT1RZdU56UTNNU0E1T0M0eE16ZzNUREUxTWk0Mk5Ua2dNVFF5TGpnd05rd3lNRGd1TlRjeElERTROeTQwTnpSTU16SXdMak01TlNBeU56WXVPREE1SWlCemRISnZhMlU5SW5WeWJDZ2pjR0ZwYm5ReFgyeHBibVZoY2w4MU1qTTFYelF3T0RFNU5Ta2lJSE4wY205clpTMTNhV1IwYUQwaU5DSWdjM1J5YjJ0bExXeHBibVZqWVhBOUluSnZkVzVrSWlCemRISnZhMlV0YkdsdVpXcHZhVzQ5SW5KdmRXNWtJaTgrUEdOcGNtTnNaU0J2Y0dGamFYUjVQU0l3TGpFaUlHTjRQU0k1TXk0MUlpQmplVDBpTVRBd0xqUTJOQ0lnY2owaU16SWlJR1pwYkd3OUluZG9hWFJsSWk4K1BHTnBjbU5zWlNCdmNHRmphWFI1UFNJd0xqTWlJR040UFNJNU15NDFJaUJqZVQwaU1UQXdMalEyTkNJZ2NqMGlNVGdpSUdacGJHdzlJbmRvYVhSbElpOCtQR05wY21Oc1pTQmplRDBpT1RNdU5TSWdZM2s5SWpFd01DNDBOalFpSUhJOUlqRXdJaUJtYVd4c1BTSjNhR2wwWlNJdlBqeG5JR1pwYkhSbGNqMGlkWEpzS0NObWFXeDBaWEkxWDJKZk5UUTBYekl6TkRVMEtTSStJRHh5WldOMElIZzlJakl3SWlCNVBTSXpOekl1T0RnMElpQjNhV1IwYUQwaU16YzVJaUJvWldsbmFIUTlJakUwTUNJZ2NuZzlJakV5SWlCbWFXeHNQU0lqTWpnek9UYzFJaUJtYVd4c0xXOXdZV05wZEhrOUlqQXVOU0l2UGlBOFp5QmpiR2x3TFhCaGRHZzlJblZ5YkNnalkyeHBjREZmTlRRMFh6SXpORFUwS1NJK0lEeDBaWGgwSUdacGJHdzlJaU5GTWtVNFJqQWlJSGh0YkRwemNHRmpaVDBpY0hKbGMyVnlkbVVpSUhOMGVXeGxQU0ozYUdsMFpTMXpjR0ZqWlRvZ2NISmxJaUJtYjI1MExXWmhiV2xzZVQwaVFYSnBZV3dpSUdadmJuUXRjMmw2WlQwaU1qQWlJR3hsZEhSbGNpMXpjR0ZqYVc1blBTSXdaVzBpUGlBOGRITndZVzRnZUQwaU16WWlJSGs5SWpRd09DNDRNVGNpUGtsRU9pQThMM1J6Y0dGdVBpQThMM1JsZUhRK0lEeDBaWGgwSUdacGJHdzlJaU5HTVVZMVJqa2lJSGh0YkRwemNHRmpaVDBpY0hKbGMyVnlkbVVpSUhOMGVXeGxQU0ozYUdsMFpTMXpjR0ZqWlRvZ2NISmxJaUJtYjI1MExXWmhiV2xzZVQwaVFYSnBZV3dpSUdadmJuUXRjMmw2WlQwaU1qQWlJR1p2Ym5RdGQyVnBaMmgwUFNKaWIyeGtJaUJzWlhSMFpYSXRjM0JoWTJsdVp6MGlMVEF1TURBMVpXMGlJSFJsZUhRdFlXNWphRzl5UFNKbGJtUWlQaUE4ZEhOd1lXNGdlRDBpTXpnd0lpQjVQU0kwTURndU9UTTBJaUErSXpFd01EZzNQQzkwYzNCaGJqNDhMM1JsZUhRK1BDOW5QanhuSUdOc2FYQXRjR0YwYUQwaWRYSnNLQ05qYkdsd01sODFORFJmTWpNME5UUXBJajQ4ZEdWNGRDQm1hV3hzUFNJalJUSkZPRVl3SWlCNGJXdzZjM0JoWTJVOUluQnlaWE5sY25abElpQnpkSGxzWlQwaWQyaHBkR1V0YzNCaFkyVTZJSEJ5WlNJZ1ptOXVkQzFtWVcxcGJIazlJa0Z5YVdGc0lpQm1iMjUwTFhOcGVtVTlJakl3SWlCc1pYUjBaWEl0YzNCaFkybHVaejBpTUdWdElqNDhkSE53WVc0Z2VEMGlNellpSUhrOUlqUTBPUzQ0TVRjaVBrSnZiM04wT2lBOEwzUnpjR0Z1UGp3dmRHVjRkRDQ4ZEdWNGRDQm1hV3hzUFNJalJqRkdOVVk1SWlCNGJXdzZjM0JoWTJVOUluQnlaWE5sY25abElpQnpkSGxzWlQwaWQyaHBkR1V0YzNCaFkyVTZJSEJ5WlNJZ1ptOXVkQzFtWVcxcGJIazlJa0Z5YVdGc0lpQm1iMjUwTFhOcGVtVTlJakl3SWlCbWIyNTBMWGRsYVdkb2REMGlZbTlzWkNJZ2JHVjBkR1Z5TFhOd1lXTnBibWM5SWkwd0xqQXdOV1Z0SWlCMFpYaDBMV0Z1WTJodmNqMGlaVzVrSWo0OGRITndZVzRnZUQwaU16Z3dJaUI1UFNJME5Ea3VPREUzSWo0eE5DNDNPQ1U4TDNSemNHRnVQand2ZEdWNGRENDhMMmMrUEdjZ1kyeHBjQzF3WVhSb1BTSjFjbXdvSTJOc2FYQXpYelUwTkY4eU16UTFOQ2tpUGp4MFpYaDBJR1pwYkd3OUlpTkZNa1U0UmpBaUlIaHRiRHB6Y0dGalpUMGljSEpsYzJWeWRtVWlJSE4wZVd4bFBTSjNhR2wwWlMxemNHRmpaVG9nY0hKbElpQm1iMjUwTFdaaGJXbHNlVDBpUVhKcFlXd2lJR1p2Ym5RdGMybDZaVDBpTWpBaUlHeGxkSFJsY2kxemNHRmphVzVuUFNJd1pXMGlQangwYzNCaGJpQjRQU0l6TmlJZ2VUMGlORGc1TGpneE55SStRM1Z5Y21WdWRDQlFiM2RsY2pvZ1BDOTBjM0JoYmo0OEwzUmxlSFErUEhSbGVIUWdabWxzYkQwaUkwWXhSalZHT1NJZ2VHMXNPbk53WVdObFBTSndjbVZ6WlhKMlpTSWdjM1I1YkdVOUluZG9hWFJsTFhOd1lXTmxPaUJ3Y21VaUlHWnZiblF0Wm1GdGFXeDVQU0pCY21saGJDSWdabTl1ZEMxemFYcGxQU0l5TUNJZ1ptOXVkQzEzWldsbmFIUTlJbUp2YkdRaUlHeGxkSFJsY2kxemNHRmphVzVuUFNJdE1DNHdNRFZsYlNJZ2RHVjRkQzFoYm1Ob2IzSTlJbVZ1WkNJK1BIUnpjR0Z1SUhnOUlqTTRNQ0lnZVQwaU5EZzVMamd4TnlJK01DNHhORGM4TDNSemNHRnVQand2ZEdWNGRENDhMMmMrUEM5blBqeG5JR1pwYkhSbGNqMGlkWEpzS0NObWFXeDBaWEkyWDJaZk5USXpOVjgwTURneE9UVXBJajQ4Y0dGMGFDQmtQU0pOTXpNM0xqa3hNeUF5T0RZdU5qSTFURE15Tmk0Mk5UZ2dNalExTGpVNE0wZ3pNall1TmpVMlZqSTBOUzQxT0RGTU1qZzFMalkyTXlBeU5EQXVOVEF4UXpJNE15NDRPRElnTWpNM0xqYzJNaUF5T0RBdU1UY3hJREl6TXk0ME16RWdNamN6TGpFNU5TQXlNekF1TlRJM1F6STJOUzQ0TmprZ01qRTRMakF5T1NBeU5USXVPREkySURJeE5TNDJPVFFnTWpRekxqRXpOeUF5TVRVdU1Ea3pRekl5TkM0MU1qa2dNakUwTGprMU15QXlNVFV1TXpRMUlESXlOeTQzTlRrZ01qRXhMalF4TmlBeU16UXVOak00UXpJeE1pNDVPVFVnTWpNd0xqQTFNaUF5TVRNdU5EazVJREl5TXk0ME1URWdNakl6TGpjek1pQXlNVFF1T1RFeVF6SXpNeTR5TlRJZ01qQTJMams0TlNBeU5ETXVNemMxSURFNU5TNDJNRFVnTWpRd0xqUXlOQ0F4T0RNdU5UWTRRekl6TlM0M05ERWdNVFkwTGpNd015QXlNekF1TXpnMklERTBNaTQwT0NBeU5EY3VOVEkzSURFeE9TNDFPRU15TkRZdU5Ea3lJREV5TUM0eU5URWdNVGN5TGpZd05pQXhOREF1T0RjeUlERTNNeTQzTlRJZ01qSTJMalV4TlVNeE56TXVOelV5SURJeU5pNDVPVEVnTVRjeUxqTXlOaUF5TURRdU5qZzRJREUxTWk0Mk9UZ2dNVGt3TGpjNU5rTXhNelF1TURBNElERTNOaTQwTlRJZ01UQTVMamt3TlNBeE5qSXVOREF5SURFd055NDBORFVnTVRReUxqazVOME14TURjdU5EUTFJREUwTWk0NU9UY2dOak11T0RZM055QXlORFl1TXpneElERTBOUzQwTWprZ01qZ3pMak0wTlVNeE5UTXVOVEVnTWpnM0xqQXdPQ0F4TkRFdU56YzVJRE13TUM0Mk9DQXhNek11TnpReElETXdOQzQwTkRGRE1USTNMamd4T1NBek1EY3VNemsySURFeE1pNDNPVGtnTXpFMUxqVTRNeUF4TVRJdU56azVJRE14TlM0MU9ETkRPVFl1TXpJMU9DQXpNalF1TlRrNUlEZzNMalU1TWpnZ016UXhMak01TVNBNE1TNDFOVEkySURNME9DNHlOREZET0RFdU5ESTNOaUF6TkRndU16Z3hJRGd4TGpNMU56UWdNelE0TGpRMU1TQTRNUzR6TlRjMElETTBPQzQwTlRGRE9ERXVNemN3TlNBek5EZ3VORFV4SURFd05DNHdORFlnTXpNeUxqTTNNeUF4TkRVdU9UVTNJRE15Tmk0eE56ZERNVGt4TGprNU1pQXpNakV1T1RBeElESXhNQzR6TURVZ016QTNMamM1TWlBeU1URXVPRE0xSURNd05pNDRORFpETWpJMExqWTVOeUF5T1RndU9UQTFJREl6TVM0d05EWWdNamd5TGpNMk5TQXlOREV1TnpVM0lESTNNQzQ0TURsRE1qWXdMams1TXlBeU5UQXVNRFUzSURJM05DNHdPVGdnTWpRMExqVXlNeUF5T0RBdU56a2dNalF6TGpFME5rd3lPVFV1TWpVMUlESTROQzQxTmpkTU1qazFMakkxTnlBeU9EUXVOVFkyVERNek55NDVNVE1nTWpnMkxqWXlOVm9pSUdacGJHdzlJbmRvYVhSbElpQm1hV3hzTFc5d1lXTnBkSGs5SWpBdU1UVWlMejQ4TDJjK1BIQmhkR2dnWkQwaVRURXdPUzR3TlRZZ01UQXVOakV4TTBneU5TNHhOREkyUXpFMkxqTXdOaUF4TUM0Mk1URXpJRGt1TVRReU5UZ2dNVGN1TnpjME55QTVMakUwTWpVNElESTJMall4TVROV05UVXdMamsyUXprdU1UUXlOVGdnTlRVNUxqYzVOeUF4Tmk0ek1EWWdOVFkyTGprMklESTFMakUwTWpZZ05UWTJMamsyU0RNNU1pNDNPVGRETkRBeExqWXpOQ0ExTmpZdU9UWWdOREE0TGpjNU55QTFOVGt1TnprM0lEUXdPQzQzT1RjZ05UVXdMamsyVmpJMkxqWXhNVE5ETkRBNExqYzVOeUF4Tnk0M056UTRJRFF3TVM0Mk16UWdNVEF1TmpFeE15QXpPVEl1TnprM0lERXdMall4TVROSU16QTRMamc0TkNJZ2MzUnliMnRsUFNKM2FHbDBaU0lnYzNSeWIydGxMVzl3WVdOcGRIazlJakF1TkNJZ2MzUnliMnRsTFhkcFpIUm9QU0l5SWk4K1BHUmxabk0rUEdacGJIUmxjaUJwWkQwaVptbHNkR1Z5TUY5bVh6VXlNelZmTkRBNE1UazFJaUI0UFNJdE1USTVMalEzTmlJZ2VUMGlMVEUxT0M0Mk5UWWlJSGRwWkhSb1BTSXpPVElpSUdobGFXZG9kRDBpTXpreUlpQm1hV3gwWlhKVmJtbDBjejBpZFhObGNsTndZV05sVDI1VmMyVWlJR052Ykc5eUxXbHVkR1Z5Y0c5c1lYUnBiMjR0Wm1sc2RHVnljejBpYzFKSFFpSStQR1psUm14dmIyUWdabXh2YjJRdGIzQmhZMmwwZVQwaU1DSWdjbVZ6ZFd4MFBTSkNZV05yWjNKdmRXNWtTVzFoWjJWR2FYZ2lMejQ4Wm1WQ2JHVnVaQ0J0YjJSbFBTSnViM0p0WVd3aUlHbHVQU0pUYjNWeVkyVkhjbUZ3YUdsaklpQnBiakk5SWtKaFkydG5jbTkxYm1SSmJXRm5aVVpwZUNJZ2NtVnpkV3gwUFNKemFHRndaU0l2UGp4bVpVZGhkWE56YVdGdVFteDFjaUJ6ZEdSRVpYWnBZWFJwYjI0OUlqUTFJaUJ5WlhOMWJIUTlJbVZtWm1WamRERmZabTl5WldkeWIzVnVaRUpzZFhKZk5USXpOVjgwTURneE9UVWlMejQ4TDJacGJIUmxjajQ4Wm1sc2RHVnlJR2xrUFNKbWFXeDBaWEl4WDJaZk5USXpOVjgwTURneE9UVWlJSGc5SWprdU5EZzJNek1pSUhrOUlpMHlOREV1TVRNaUlIZHBaSFJvUFNJMk1UY3VPREkxSWlCb1pXbG5hSFE5SWpVME1TNDRPVGNpSUdacGJIUmxjbFZ1YVhSelBTSjFjMlZ5VTNCaFkyVlBibFZ6WlNJZ1kyOXNiM0l0YVc1MFpYSndiMnhoZEdsdmJpMW1hV3gwWlhKelBTSnpVa2RDSWo0OFptVkdiRzl2WkNCbWJHOXZaQzF2Y0dGamFYUjVQU0l3SWlCeVpYTjFiSFE5SWtKaFkydG5jbTkxYm1SSmJXRm5aVVpwZUNJdlBqeG1aVUpzWlc1a0lHMXZaR1U5SW01dmNtMWhiQ0lnYVc0OUlsTnZkWEpqWlVkeVlYQm9hV01pSUdsdU1qMGlRbUZqYTJkeWIzVnVaRWx0WVdkbFJtbDRJaUJ5WlhOMWJIUTlJbk5vWVhCbElpOCtQR1psUjJGMWMzTnBZVzVDYkhWeUlITjBaRVJsZG1saGRHbHZiajBpTkRVaUlISmxjM1ZzZEQwaVpXWm1aV04wTVY5bWIzSmxaM0p2ZFc1a1FteDFjbDgxTWpNMVh6UXdPREU1TlNJdlBqd3ZabWxzZEdWeVBqeG1hV3gwWlhJZ2FXUTlJbVpwYkhSbGNqSmZabDgxTWpNMVh6UXdPREU1TlNJZ2VEMGlNekF1TWpBNU5DSWdlVDBpTWpBdU1USTBJaUIzYVdSMGFEMGlORGcyTGpFMU1TSWdhR1ZwWjJoMFBTSTBPRFl1TVRVeUlpQm1hV3gwWlhKVmJtbDBjejBpZFhObGNsTndZV05sVDI1VmMyVWlJR052Ykc5eUxXbHVkR1Z5Y0c5c1lYUnBiMjR0Wm1sc2RHVnljejBpYzFKSFFpSStQR1psUm14dmIyUWdabXh2YjJRdGIzQmhZMmwwZVQwaU1DSWdjbVZ6ZFd4MFBTSkNZV05yWjNKdmRXNWtTVzFoWjJWR2FYZ2lMejQ4Wm1WQ2JHVnVaQ0J0YjJSbFBTSnViM0p0WVd3aUlHbHVQU0pUYjNWeVkyVkhjbUZ3YUdsaklpQnBiakk5SWtKaFkydG5jbTkxYm1SSmJXRm5aVVpwZUNJZ2NtVnpkV3gwUFNKemFHRndaU0l2UGp4bVpVZGhkWE56YVdGdVFteDFjaUJ6ZEdSRVpYWnBZWFJwYjI0OUlqUTRMall4TXpFaUlISmxjM1ZzZEQwaVpXWm1aV04wTVY5bWIzSmxaM0p2ZFc1a1FteDFjbDgxTWpNMVh6UXdPREU1TlNJdlBqd3ZabWxzZEdWeVBqeG1hV3gwWlhJZ2FXUTlJbVpwYkhSbGNqTmZabDgxTWpNMVh6UXdPREU1TlNJZ2VEMGlMVEU0TGpnNE9URWlJSGs5SWpJM015NHhPRGdpSUhkcFpIUm9QU0kwTlRjdU1EUTRJaUJvWldsbmFIUTlJalExTnk0d05EZ2lJR1pwYkhSbGNsVnVhWFJ6UFNKMWMyVnlVM0JoWTJWUGJsVnpaU0lnWTI5c2IzSXRhVzUwWlhKd2IyeGhkR2x2YmkxbWFXeDBaWEp6UFNKelVrZENJajQ4Wm1WR2JHOXZaQ0JtYkc5dlpDMXZjR0ZqYVhSNVBTSXdJaUJ5WlhOMWJIUTlJa0poWTJ0bmNtOTFibVJKYldGblpVWnBlQ0l2UGp4bVpVSnNaVzVrSUcxdlpHVTlJbTV2Y20xaGJDSWdhVzQ5SWxOdmRYSmpaVWR5WVhCb2FXTWlJR2x1TWowaVFtRmphMmR5YjNWdVpFbHRZV2RsUm1sNElpQnlaWE4xYkhROUluTm9ZWEJsSWk4K1BHWmxSMkYxYzNOcFlXNUNiSFZ5SUhOMFpFUmxkbWxoZEdsdmJqMGlOVEl1TWpNME5pSWdjbVZ6ZFd4MFBTSmxabVpsWTNReFgyWnZjbVZuY205MWJtUkNiSFZ5WHpVeU16VmZOREE0TVRrMUlpOCtQQzltYVd4MFpYSStQR1pwYkhSbGNpQnBaRDBpWm1sc2RHVnlORjltWHpVeU16VmZOREE0TVRrMUlpQjRQU0l0TlRRdU9EQTJNaUlnZVQwaU1UQXVPRFF6TnlJZ2QybGtkR2c5SWpNMk1TNHpORElpSUdobGFXZG9kRDBpTXpZeExqTTBNU0lnWm1sc2RHVnlWVzVwZEhNOUluVnpaWEpUY0dGalpVOXVWWE5sSWlCamIyeHZjaTFwYm5SbGNuQnZiR0YwYVc5dUxXWnBiSFJsY25NOUluTlNSMElpUGp4bVpVWnNiMjlrSUdac2IyOWtMVzl3WVdOcGRIazlJakFpSUhKbGMzVnNkRDBpUW1GamEyZHliM1Z1WkVsdFlXZGxSbWw0SWk4K1BHWmxRbXhsYm1RZ2JXOWtaVDBpYm05eWJXRnNJaUJwYmowaVUyOTFjbU5sUjNKaGNHaHBZeUlnYVc0eVBTSkNZV05yWjNKdmRXNWtTVzFoWjJWR2FYZ2lJSEpsYzNWc2REMGljMmhoY0dVaUx6NDhabVZIWVhWemMybGhia0pzZFhJZ2MzUmtSR1YyYVdGMGFXOXVQU0kwT0M0Mk1UTXhJaUJ5WlhOMWJIUTlJbVZtWm1WamRERmZabTl5WldkeWIzVnVaRUpzZFhKZk5USXpOVjgwTURneE9UVWlMejQ4TDJacGJIUmxjajQ4Wm1sc2RHVnlJR2xrUFNKbWFXeDBaWEkxWDJKZk5USXpOVjgwTURneE9UVWlJSGc5SWpFMUxqWXpORGdpSUhrOUlqUXdOQ0lnZDJsa2RHZzlJak00TnlJZ2FHVnBaMmgwUFNJeE1USWlJR1pwYkhSbGNsVnVhWFJ6UFNKMWMyVnlVM0JoWTJWUGJsVnpaU0lnWTI5c2IzSXRhVzUwWlhKd2IyeGhkR2x2YmkxbWFXeDBaWEp6UFNKelVrZENJajQ4Wm1WR2JHOXZaQ0JtYkc5dlpDMXZjR0ZqYVhSNVBTSXdJaUJ5WlhOMWJIUTlJa0poWTJ0bmNtOTFibVJKYldGblpVWnBlQ0l2UGp4bVpVZGhkWE56YVdGdVFteDFjaUJwYmowaVFtRmphMmR5YjNWdVpFbHRZV2RsUm1sNElpQnpkR1JFWlhacFlYUnBiMjQ5SWpJaUx6NDhabVZEYjIxd2IzTnBkR1VnYVc0eVBTSlRiM1Z5WTJWQmJIQm9ZU0lnYjNCbGNtRjBiM0k5SW1sdUlpQnlaWE4xYkhROUltVm1abVZqZERGZlltRmphMmR5YjNWdVpFSnNkWEpmTlRJek5WODBNRGd4T1RVaUx6NDhabVZDYkdWdVpDQnRiMlJsUFNKdWIzSnRZV3dpSUdsdVBTSlRiM1Z5WTJWSGNtRndhR2xqSWlCcGJqSTlJbVZtWm1WamRERmZZbUZqYTJkeWIzVnVaRUpzZFhKZk5USXpOVjgwTURneE9UVWlJSEpsYzNWc2REMGljMmhoY0dVaUx6NDhMMlpwYkhSbGNqNDhabWxzZEdWeUlHbGtQU0ptYVd4MFpYSTJYMlpmTlRJek5WODBNRGd4T1RVaUlIZzlJalk1TGpBeU1pSWdlVDBpTVRBM0xqSTBOU0lnZDJsa2RHZzlJakk0TVM0eU1qVWlJR2hsYVdkb2REMGlNalV6TGpVME1pSWdabWxzZEdWeVZXNXBkSE05SW5WelpYSlRjR0ZqWlU5dVZYTmxJaUJqYjJ4dmNpMXBiblJsY25CdmJHRjBhVzl1TFdacGJIUmxjbk05SW5OU1IwSWlQanhtWlVac2IyOWtJR1pzYjI5a0xXOXdZV05wZEhrOUlqQWlJSEpsYzNWc2REMGlRbUZqYTJkeWIzVnVaRWx0WVdkbFJtbDRJaTgrUEdabFFteGxibVFnYlc5a1pUMGlibTl5YldGc0lpQnBiajBpVTI5MWNtTmxSM0poY0docFl5SWdhVzR5UFNKQ1lXTnJaM0p2ZFc1a1NXMWhaMlZHYVhnaUlISmxjM1ZzZEQwaWMyaGhjR1VpTHo0OFptVkhZWFZ6YzJsaGJrSnNkWElnYzNSa1JHVjJhV0YwYVc5dVBTSTJMakUyTnpZNUlpQnlaWE4xYkhROUltVm1abVZqZERGZlptOXlaV2R5YjNWdVpFSnNkWEpmTlRJek5WODBNRGd4T1RVaUx6NDhMMlpwYkhSbGNqNDhiR2x1WldGeVIzSmhaR2xsYm5RZ2FXUTlJbkJoYVc1ME1GOXNhVzVsWVhKZk5USXpOVjgwTURneE9UVWlJSGd4UFNJeE56TXVPVEk0SWlCNU1UMGlNekF1TlRBME5TSWdlREk5SWpJMk9DNHdPRE1pSUhreVBTSXpNREl1TWpRNUlpQm5jbUZrYVdWdWRGVnVhWFJ6UFNKMWMyVnlVM0JoWTJWUGJsVnpaU0krUEhOMGIzQWdjM1J2Y0MxamIyeHZjajBpZDJocGRHVWlMejQ4YzNSdmNDQnZabVp6WlhROUlqRWlJSE4wYjNBdFkyOXNiM0k5SW5kb2FYUmxJaUJ6ZEc5d0xXOXdZV05wZEhrOUlqQWlMejQ4TDJ4cGJtVmhja2R5WVdScFpXNTBQanhzYVc1bFlYSkhjbUZrYVdWdWRDQnBaRDBpY0dGcGJuUXhYMnhwYm1WaGNsODFNak0xWHpRd09ERTVOU0lnZURFOUlqRTVOaTQ1TlRZaUlIa3hQU0l4TURjdU5UUXlJaUI0TWowaU1UZzFMamMwTnlJZ2VUSTlJakkyT1M0d01qWWlJR2R5WVdScFpXNTBWVzVwZEhNOUluVnpaWEpUY0dGalpVOXVWWE5sSWo0OGMzUnZjQ0J6ZEc5d0xXTnZiRzl5UFNKM2FHbDBaU0l2UGp4emRHOXdJRzltWm5ObGREMGlNU0lnYzNSdmNDMWpiMnh2Y2owaWQyaHBkR1VpSUhOMGIzQXRiM0JoWTJsMGVUMGlNQ0l2UGp3dmJHbHVaV0Z5UjNKaFpHbGxiblErUEhKaFpHbGhiRWR5WVdScFpXNTBJR2xrUFNKd1lXbHVkREpmY21Ga2FXRnNYelV5TXpWZk5EQTRNVGsxSWlCamVEMGlNQ0lnWTNrOUlqQWlJSEk5SWpFaUlHZHlZV1JwWlc1MFZXNXBkSE05SW5WelpYSlRjR0ZqWlU5dVZYTmxJaUJuY21Ga2FXVnVkRlJ5WVc1elptOXliVDBpZEhKaGJuTnNZWFJsS0RrM0xqRXpOVGNnT1RndU1EVTFNU2tnY205MFlYUmxLRGt3S1NCelkyRnNaU2d5TVM0NU5qWTVLU0krUEhOMGIzQWdiMlptYzJWMFBTSXdMakk0TkRFeE9TSWdjM1J2Y0MxamIyeHZjajBpZDJocGRHVWlJSE4wYjNBdGIzQmhZMmwwZVQwaU1DSXZQanh6ZEc5d0lHOW1abk5sZEQwaU1TSWdjM1J2Y0MxamIyeHZjajBpSXpRMVEwWkdSaUl2UGp3dmNtRmthV0ZzUjNKaFpHbGxiblErUEdOc2FYQlFZWFJvSUdsa1BTSmpiR2x3TUY4MU1qTTFYelF3T0RFNU5TSStQSEpsWTNRZ2VEMGlNQzR4TXpRM05qWWlJSGRwWkhSb1BTSTBNVGtpSUdobGFXZG9kRDBpTlRjNElpQnllRDBpTWpRaUlHWnBiR3c5SW5kb2FYUmxJaTgrUEM5amJHbHdVR0YwYUQ0OFkyeHBjRkJoZEdnZ2FXUTlJbU5zYVhBeFh6VXlNelZmTkRBNE1UazFJajQ4Y21WamRDQjRQU0l6TlM0Mk16UTRJaUI1UFNJME1qUWlJSGRwWkhSb1BTSXpORGNpSUdobGFXZG9kRDBpTXpBaUlISjRQU0kwSWlCbWFXeHNQU0ozYUdsMFpTSXZQand2WTJ4cGNGQmhkR2crUEdOc2FYQlFZWFJvSUdsa1BTSmpiR2x3TWw4MU1qTTFYelF3T0RFNU5TSStQSEpsWTNRZ2VEMGlNelV1TmpNME9DSWdlVDBpTkRZMklpQjNhV1IwYUQwaU16UTNJaUJvWldsbmFIUTlJak13SWlCeWVEMGlOQ0lnWm1sc2JEMGlkMmhwZEdVaUx6NDhMMk5zYVhCUVlYUm9Qand2WkdWbWN6NDhMM04yWno0PSJ9";
    }
}