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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
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
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {WrappedERC721} from "../WrappedERC721.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {ITeleport} from "../interfaces/ITeleport.sol";
import {ITeleportDApp} from "../interfaces/ITeleportDApp.sol";
import {LibRouter} from "../libraries/LibRouter.sol";
import {ICommonErrors, IRouterErrors} from "../interfaces/IDiamondErrors.sol";

/**
 *  @notice Handles the bridging of ERC721 tokens
 */
contract RouterFacet is IRouter, ITeleportDApp {
    address private immutable _SELF = address(this);

    /**
     * @notice sets the state for the Router facet
     * @param data_ Abi encoded data - chain ID, teleport address and dAppId.
     * @dev This state method is never attached on the diamond
     */
    function state(bytes memory data_) external {
        if (address(this) == _SELF) {
            revert ICommonErrors.NoDirectCall();
        }

        LibRouter.Storage storage rs = LibRouter.routerStorage();
        (rs.chainId, rs.teleportAddress, rs.dAppId) = abi.decode(data_, (uint8, address, bytes32));

        emit TeleportAddressSet(rs.teleportAddress);
    }

    function _determineAction(
        uint8 targetChainId_,
        CollectionWithTokens[] calldata assets_,
        bytes calldata receiver_
    ) private returns (bytes[] memory) {
        bytes[] memory actions = new bytes[](assets_.length);

        for (uint256 i; i < assets_.length; ) {
            LibRouter.NativeCollectionWithChainId memory nativeCollection = wrappedToNativeCollection(
                assets_[i].collection
            );

            if (nativeCollection.chainId == 0) {
                emit LockMint(targetChainId_, assets_[i].collection, assets_[i].tokenIds, receiver_);

                actions[i] = abi.encode(
                    IRouter.TargetAction.Mint,
                    _addressToBytes(assets_[i].collection),
                    _lockMint(assets_[i].collection, assets_[i].tokenIds)
                );
            } else if (nativeCollection.chainId == targetChainId_) {
                emit BurnUnlock(targetChainId_, assets_[i].collection, assets_[i].tokenIds, receiver_);

                actions[i] = abi.encode(
                    IRouter.TargetAction.Unlock,
                    nativeCollection.contractAddress,
                    _burnUnlock(assets_[i].collection, assets_[i].tokenIds)
                );
            } else {
                emit BurnMint(targetChainId_, assets_[i].collection, assets_[i].tokenIds, receiver_);

                actions[i] = abi.encode(
                    IRouter.TargetAction.Mint,
                    nativeCollection.contractAddress,
                    _burnMint(nativeCollection.chainId, assets_[i].collection, assets_[i].tokenIds)
                );
            }
            unchecked {
                ++i;
            }
        }
        return actions;
    }

    /**
     *  @notice Send tokens to another chain via Teleport.
     *  @param targetChainId_ Our ID of the destination chain
     *  @param assets_ An array of structs, containing a collection address and an array of token IDs
     *  @param receiver_ Address who will receive the tokens on the destination chain
     *  @dev We determine the action for each ERC721 contract (collection) and build the appropriate payload
     */
    function _egress(
        uint8 targetChainId_,
        CollectionWithTokens[] calldata assets_,
        bytes calldata receiver_,
        bytes calldata extraOptionalArgs_
    ) internal returns (bytes storage, bytes memory) {
        LibRouter.Storage storage rs = LibRouter.routerStorage();

        bytes memory payload = abi.encode(
            uint256(0), // current message header
            abi.encode(_addressToBytes(msg.sender), receiver_, _determineAction(targetChainId_, assets_, receiver_)) // envelope
        );

        bytes storage bridgeAddress = rs.bridgeAddressByChainId[targetChainId_];
        if (bridgeAddress.length == 0) {
            revert IRouterErrors.UnknownDestination();
        }

        uint256 feeOwed = serviceFee(targetChainId_, bridgeAddress, rs.dAppId, payload, extraOptionalArgs_);

        if (msg.value != feeOwed) {
            revert IRouterErrors.WrongValue();
        }

        return (bridgeAddress, payload);
    }

    function egress(
        uint8 targetChainId_,
        CollectionWithTokens[] calldata assets_,
        bytes calldata receiver_,
        bytes calldata extraOptionalArgs_
    ) external payable override {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        (bytes storage bridgeAddress, bytes memory payload) = _egress(
            targetChainId_,
            assets_,
            receiver_,
            extraOptionalArgs_
        );

        ITeleport(rs.teleportAddress).transmitWithArgs{value: msg.value}(
            targetChainId_,
            bridgeAddress,
            rs.dAppId,
            payload,
            extraOptionalArgs_
        );
    }

    function egressWithProvider(
        uint8 targetChainId_,
        CollectionWithTokens[] calldata assets_,
        bytes calldata receiver_,
        address providerAddress_,
        bytes calldata extraOptionalArgs_
    ) external payable override {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        (bytes storage bridgeAddress, bytes memory payload) = _egress(
            targetChainId_,
            assets_,
            receiver_,
            extraOptionalArgs_
        );

        ITeleport(rs.teleportAddress).transmitWithProvider{value: msg.value}(
            targetChainId_,
            bridgeAddress,
            rs.dAppId,
            payload,
            providerAddress_,
            extraOptionalArgs_
        );
    }

    /**
     *  @param collectionAddress_ The ERC721 contract address
     *  @param tokenIds_ An array of token IDs to be locked and bridged
     *  @return Payload for sending native tokens to a non-native chain
     *  @dev If the ERC721 contract supports the metadata extension, we have to pass it too
     */
    function _lockMint(address collectionAddress_, uint256[] calldata tokenIds_) internal returns (bytes memory) {
        string[] memory tokenURIs = new string[](tokenIds_.length);
        string memory collectionName;
        string memory collectionSymbol;

        if (ERC721(collectionAddress_).supportsInterface(type(IERC721Metadata).interfaceId)) {
            for (uint256 i; i < tokenIds_.length; ) {
                tokenURIs[i] = ERC721(collectionAddress_).tokenURI(tokenIds_[i]);
                ERC721(collectionAddress_).transferFrom(msg.sender, address(this), tokenIds_[i]);
                unchecked {
                    ++i;
                }
            }

            collectionName = string(abi.encodePacked("Wrapped ", ERC721(collectionAddress_).name()));
            collectionSymbol = string(abi.encodePacked("W", ERC721(collectionAddress_).symbol()));
        } else {
            for (uint256 i; i < tokenIds_.length; ) {
                ERC721(collectionAddress_).transferFrom(msg.sender, address(this), tokenIds_[i]);
                unchecked {
                    ++i;
                }
            }
        }

        return abi.encode(tokenIds_, LibRouter.routerStorage().chainId, tokenURIs, collectionName, collectionSymbol);
    }

    /**
     *  @param collectionAddress_ The ERC721 contract address
     *  @param tokenIds_ An array of token IDs to be burned and bridged
     *  @return Payload for sending non-native tokens to their native chain
     */
    function _burnUnlock(address collectionAddress_, uint256[] calldata tokenIds_) internal returns (bytes memory) {
        // we need to check if msg.sender owns what he wants to transfer (burn)
        WrappedERC721(collectionAddress_).batchBurnFrom(msg.sender, tokenIds_);

        return abi.encode(tokenIds_);
    }

    /**
     *  @param collectionAddress_ The ERC721 contract address
     *  @param tokenIds_ An array of token IDs to be burned and bridged
     *  @return Payload for sending non-native tokens to a non-native chain
     */
    function _burnMint(
        uint8 nativeChainId_,
        address collectionAddress_,
        uint256[] calldata tokenIds_
    ) internal returns (bytes memory) {
        string[] memory tokenURIs = new string[](tokenIds_.length);

        for (uint256 i; i < tokenIds_.length; ) {
            tokenURIs[i] = ERC721(collectionAddress_).tokenURI(tokenIds_[i]);
            unchecked {
                ++i;
            }
        }
        WrappedERC721(collectionAddress_).batchBurnFrom(msg.sender, tokenIds_);

        return
            abi.encode(
                tokenIds_,
                nativeChainId_,
                tokenURIs,
                ERC721(collectionAddress_).name(),
                ERC721(collectionAddress_).symbol()
            );
    }

    /**
     *  @notice Receive tokens from another chain via Teleport.
     *  @param sourceChainId_ Chain ID the teleport message comes from
     *  @param transmissionSender_ Sender address of the teleport message
     *  @param dAppId_ dAppId for the teleport message
     *  @param payload_ Data payload of teleport message
     *  @dev header is a placeholder for future proofing
     */
    function onTeleportMessage(
        uint8 sourceChainId_,
        bytes calldata transmissionSender_,
        bytes32 dAppId_,
        bytes calldata payload_
    ) external override {
        // Check message validity
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        if (msg.sender != rs.teleportAddress) {
            revert IRouterErrors.UnknownTeleport();
        }
        if (dAppId_ != rs.dAppId) {
            revert IRouterErrors.UnknownDAppId();
        }
        if (keccak256(rs.bridgeAddressByChainId[sourceChainId_]) != keccak256(transmissionSender_)) {
            revert IRouterErrors.UnknownSender();
        }

        (uint256 header, bytes memory envelope) = abi.decode(payload_, (uint256, bytes));

        if (header != 0) {
            revert IRouterErrors.UnknownFormat();
        }

        (bytes memory sender, bytes memory receiver, bytes[] memory actions) = abi.decode(
            envelope,
            (bytes, bytes, bytes[])
        );

        if (sender.length == 0) {
            revert IRouterErrors.ShouldContainSender();
        }

        for (uint256 i; i < actions.length; ) {
            // Decode the common action data
            (IRouter.TargetAction actionType, bytes memory nativeAddress, bytes memory actionData) = abi.decode(
                actions[i],
                (IRouter.TargetAction, bytes, bytes)
            );

            // and call the corresponding receive function
            if (actionType == IRouter.TargetAction.Unlock) {
                // with its specific payload
                uint256[] memory tokenIds = abi.decode(actionData, (uint256[]));
                _unlock(_bytesToAddress(nativeAddress), tokenIds, _bytesToAddress(receiver));
            } else {
                (
                    uint256[] memory tokenIds,
                    uint8 nativeChainId,
                    string[] memory tokenURIs,
                    string memory collectionName,
                    string memory collectionSymbol
                ) = abi.decode(actionData, (uint256[], uint8, string[], string, string));

                _mint(
                    nativeAddress,
                    tokenIds,
                    _bytesToAddress(receiver),
                    nativeChainId,
                    tokenURIs,
                    collectionName,
                    collectionSymbol
                );
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     *  @notice Release previously locked native tokens.
     *  @param collectionAddress_ The ERC721 contract address
     *  @param tokenIds_ The token IDs to be unlocked
     *  @param receiver_ The address to receive the tokens
     */
    function _unlock(address collectionAddress_, uint256[] memory tokenIds_, address receiver_) internal {
        emit Unlock(collectionAddress_, tokenIds_, receiver_);
        for (uint256 i; i < tokenIds_.length; ) {
            // sends tokens to unknown user supplied address, so we are being safe
            ERC721(collectionAddress_).transferFrom(address(this), receiver_, tokenIds_[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     *  @notice Mint wrapped versions of non-native tokens. Deploys a new collection contract if necessary.
     *  @param nativeAddress_ The ERC721 contract address on the native chain
     *  @param tokenIds_ The token IDs to be minted
     *  @param receiver_ The address to receive the tokens
     *  @param nativeChainId_ Our chain ID for the native network
     *  @param tokenURIs_ Token URIs for the new tokens
     *  @param collectionName_ Name for the wrapped collection
     *  @param collectionSymbol_ Symbol for the wrapped collection
     */
    function _mint(
        bytes memory nativeAddress_,
        uint256[] memory tokenIds_,
        address receiver_,
        uint8 nativeChainId_,
        string[] memory tokenURIs_,
        string memory collectionName_,
        string memory collectionSymbol_
    ) internal {
        address wrappedCollection = nativeToWrappedCollection(nativeChainId_, nativeAddress_);
        if (wrappedCollection == address(0)) {
            wrappedCollection = deployWrappedCollection(
                nativeChainId_,
                nativeAddress_,
                collectionName_,
                collectionSymbol_
            );
        }

        emit Mint(wrappedCollection, tokenIds_, receiver_);
        WrappedERC721(wrappedCollection).batchMint(receiver_, tokenIds_, tokenURIs_);
    }

    /**
     *  @notice Deploys a wrapped version of a native collection to the current chain
     *  @param sourceChain_ Our chain ID for the native chain
     *  @param nativeCollection_ ERC721 contract address on the native chain
     *  @param collectionName_ Name for the wrapped collection
     *  @param collectionSymbol_ Symbol for the wrapped collection
     */
    function deployWrappedCollection(
        uint8 sourceChain_,
        bytes memory nativeCollection_,
        string memory collectionName_,
        string memory collectionSymbol_
    ) internal returns (address) {
        address createdContract;
        bytes32 salt = keccak256(abi.encode(sourceChain_, nativeCollection_));
        bytes memory initCode = abi.encodePacked(
            type(WrappedERC721).creationCode,
            abi.encode(collectionName_, collectionSymbol_)
        );
        // solhint-disable-next-line no-inline-assembly
        assembly {
            createdContract := create2(0, add(initCode, 0x20), mload(initCode), salt)
        }
        if (createdContract == address(0)) {
            revert IRouterErrors.AddressOccupied();
        }

        LibRouter.setCollectionMappings(sourceChain_, nativeCollection_, createdContract);
        emit WrappedCollectionDeployed(sourceChain_, nativeCollection_, createdContract);

        return createdContract;
    }

    /**
     *  @param chainId_ Our chain ID for the native chain
     *  @param nativeCollection_ ERC721 contract address on the native chain
     *  @return The address of the wrapped counterpart of `nativeToken` in the current chain
     */
    function nativeToWrappedCollection(
        uint8 chainId_,
        bytes memory nativeCollection_
    ) public view override returns (address) {
        return LibRouter.routerStorage().nativeToWrappedCollection[chainId_][nativeCollection_];
    }

    /**
     *  @param wrappedCollection_ ERC721 contract address of the wrapped collection
     *  @return The chainId and address of the original token
     */
    function wrappedToNativeCollection(
        address wrappedCollection_
    ) public view override returns (LibRouter.NativeCollectionWithChainId memory) {
        return LibRouter.routerStorage().wrappedToNativeCollection[wrappedCollection_];
    }

    /**
     *  @return Required fee amount for bridging
     */
    function serviceFee(
        uint8 targetChainId_,
        bytes memory transmissionReceiver_,
        bytes32 dAppId_,
        bytes memory payload_,
        bytes calldata extraOptionalArgs_
    ) public view override returns (uint256) {
        return
            ITeleport(LibRouter.routerStorage().teleportAddress).serviceFee(
                targetChainId_,
                transmissionReceiver_,
                dAppId_,
                payload_,
                extraOptionalArgs_
            );
    }

    /**
     *  @param addressAsBytes value of type bytes
     *  @return addr addressAsBytes value converted to type address
     */
    function _bytesToAddress(bytes memory addressAsBytes) internal pure returns (address addr) {
        if (addressAsBytes.length != 20) {
            revert IRouterErrors.WrongAddressLength();
        }
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := mload(add(addressAsBytes, 20))
        }
    }

    /**
     *  @param addr value of type address
     *  @return addr value converted to type bytes
     */
    function _addressToBytes(address addr) internal pure returns (bytes memory) {
        return abi.encodePacked(addr);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface ICommonErrors {
    error NoDirectCall();

    error TransferFailed(string message);

    error AccountIsAddressZero();

    error NoValueAllowed();
}

interface IRouterErrors {
    /**
     * @dev Used when the destination is not supported by the router
     */
    error UnknownDestination();

    /**
     * @dev Used when the value is not wrong
     */
    error WrongValue();

    /**
     * @dev Used when the delivery fee signature has expired
     */
    error DeliveryFeeSignatureExpired();

    /**
     * @dev Used when the delivery fee signer is invalid
     */
    error InvalidDeliveryFeeSigner();

    /**
     * @dev Used when an unsupported fee token is encountered
     */
    error UnsupportedFeToken();

    /**
     * @dev Used when the fee token collector address is not set
     */
    error FeeTokenCollectorAddressNotSet();

    /**
     * @dev Used when an unknown teleport is encountered
     */
    error UnknownTeleport();

    /**
     * @dev Used when an unknown DApp ID is encountered
     */
    error UnknownDAppId();

    /**
     * @dev Used when an unknown sender is encountered
     */
    error UnknownSender();

    /**
     * @dev Used when an unknown format is encountered
     */
    error UnknownFormat();

    /**
     * @dev Used to make sure a transaction should contain a sender
     */
    error ShouldContainSender();

    /**
     * @dev Used when an address has an incorrect length
     */
    error WrongAddressLength();

    /**
     * @dev Used when an incorrect target action is encountered
     */
    error IncorrectTargetAction();

    /**
     * @dev Used when a delivery fee fails with a specific message
     * @param message The error message
     */
    error DeliveryFeeFailed(string message);

    /**
     * @dev Used when an unlock fails with a specific message
     * @param message The error message
     */
    error UnlockFailed(string message);

    /**
     * @dev Used when an address is already occupied
     */
    error AddressOccupied();
}

interface IDiamondLoupeFacetErrors {
    error ExceededMaxFacets();
}

interface ILibDiamondErrors {
    // "Diamond: Function does not exist"
    error FunctionDoesNotExist();

    // LibDiamondCut: No selectors in facet to cut
    error NoSelectorsInFacetToCut();

    // LibDiamondCut: Can't add function that already exists
    error FunctionAlreadyExists();

    // LibDiamondCut: Can't replace immutable function
    error CantReplaceImmutableFn();

    // LibDiamondCut: Can't replace function with same function
    error CantReplaceWithSameFn();

    // LibDiamondCut: Can't replace function that doesn't exist
    error CantReplaceNonexistentFn();

    // LibDiamondCut: Remove facet address must be address(0)
    error RemoveFacetAddressMustBeZero();

    // LibDiamondCut: Can't remove function that doesn't exist
    error CantRemoveNonexistentFn();

    // LibDiamondCut: Can't remove immutable function
    error CantRemoveImmutableFn();

    // LibDiamondCut: Incorrect FacetCutAction
    error IncorrectFacetCutAction();

    // LibDiamondCut: _init is address(0) but_calldata is not empty
    error InitIsAddress0AndCalldataNotEmpty();

    // LibDiamondCut: _calldata is empty but _init is not address(0)
    error CalldataIsEmpty();

    // LibDiamondCut: _init function reverted
    error InitFunctionReverted();

    // either "LibDiamondCut: Add facet has no code" or "LibDiamondCut: Replace facet has no code" or "LibDiamondCut: _init address has no code"
    error ContractHasNoCode(string checkCase);

    error LibDiamond__InitIsNotFacet();
}

interface ITeleportFacetErrors {
    /**
     * @dev Used to make sure the function is only called by the teleport contract.
     */
    error OnlyValidProviderCalls();

    /**
     * @dev Used when there's not provider that supports the specified transmission.
     */
    error TransmissionNotSupportedByAnyProvider();

    /**
     * @dev Used when the provided provider address is the zero address.
     */
    error ProviderCannotBeZeroAddress();

    /**
     * @dev Used when the provided provider address is not supported by the provider selector.
     */
    error InvalidProvider();

    /**
     * @dev Thrown when a message is received from an unknown source chain.
     */
    error SourceChainNotSupported();

    /**
     * @dev Thrown when a message is received from an invalid teleport sender.
     */
    error InvalidTeleportSender();

    /**
     * @dev Thrown when a message is being send to an unknown target chain.
     */
    error TargetChainNotSupported();

    // LibTeleport: INVALID_CHAIN_ID
    error InvalidChainId();

    // LibTeleport: INVALID_SENDER_ADDRESS
    error InvalidSenderAddress();

    // LibTeleport: DUPLICATE_CHAIN_ID
    error DuplicateChainId();
}

interface IFeeCalculatorFacetErrors {
    // FeeCalculator: nothing to claim
    error NothingToClaim();

    // FeeCalculator: insufficient fee amount
    error InsufficientFeeAmount();
}

interface IGovernanceFacetErrors {
    // Governance: msg.sender is not a member
    error NotAValidMember();

    // Governance: member list empty
    error MemberListEmpty();

    // Governance: Account already added
    error AccountAlreadyAdded();

    // Governance: Would become memberless
    error WouldBecomeMemberless();

    // Governance: Invalid number of signatures
    error InvalidNumberOfSignatures();

    // Governance: invalid signer
    error InvalidSigner();

    // Governance: signers must be in ascending order and uniques
    error WrongSignersOrder();

    // Governance: message hash already used
    error HashAlreadyUsed();
}

interface IWrappedTokenErrors {
    error TokenTransferWhilePaused();
    error URIQueryForNonexistentToken();
    error WrongBatchMintParameters();
    error BurnNotApproved();
    error WrongOwner();
    error WrongBatchUpdateParameters();
}

interface ITeleportUpdaterFacetErrors {
    error InvalidNewTeleportAddress();
}

interface IUtilityFacetErros {
    error WrappedTokenAddressMustNeNonZero();
}

// solhint-disable no-empty-blocks
interface IDiamondErrors is
    ICommonErrors,
    IDiamondLoupeFacetErrors,
    ILibDiamondErrors,
    ITeleportFacetErrors,
    IFeeCalculatorFacetErrors,
    IGovernanceFacetErrors,
    IRouterErrors,
    IWrappedTokenErrors,
    ITeleportUpdaterFacetErrors
{
    // We just combine all the interfaces into one to simplify the import from the ITeleportDiamond and generate the ABI
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import {LibRouter} from "../libraries/LibRouter.sol";

interface IRouter {
    enum TargetAction {
        Unlock,
        Mint
    }

    struct CollectionWithTokens {
        address collection;
        uint256[] tokenIds;
    }

    /// @notice An event emitted once a Lock transaction is executed
    event LockMint(uint8 targetChain, address collection, uint256[] tokenIds, bytes receiver);
    /// @notice An event emitted once a Burn transaction is executed
    event BurnMint(uint8 targetChain, address collection, uint256[] tokenIds, bytes receiver);
    /// @notice An event emitted once a BurnAndTransfer transaction is executed
    event BurnUnlock(uint8 targetChain, address collection, uint256[] tokenIds, bytes receiver);
    /// @notice An event emitted once an Unlock transaction is executed
    event Unlock(address collection, uint256[] tokenIds, address receiver);
    /// @notice An even emitted once a Mint transaction is executed
    event Mint(address collection, uint256[] tokenIds, address receiver);
    /// @notice An event emitted once a new wrapped token is deployed by the contract
    event WrappedCollectionDeployed(uint8 sourceChain, bytes nativeColllection, address wrappedColllection);
    /// @notice An event emitted when setting the teleport address
    event TeleportAddressSet(address teleportAddress);

    function nativeToWrappedCollection(uint8 _chainId, bytes memory _nativeCollection) external view returns (address);

    function wrappedToNativeCollection(
        address _wrappedCollection
    ) external view returns (LibRouter.NativeCollectionWithChainId memory);

    function serviceFee(
        uint8 targetChainId_,
        bytes memory transmissionReceiver_,
        bytes32 dAppId_,
        bytes memory payload_,
        bytes calldata extraOptionalArgs_
    ) external view returns (uint256);

    function egress(
        uint8 targetChain_,
        CollectionWithTokens[] calldata assets,
        bytes calldata receiver_,
        bytes calldata extraOptionalArgs_
    ) external payable;

    function egressWithProvider(
        uint8 targetChain_,
        CollectionWithTokens[] calldata assets,
        bytes calldata receiver_,
        address providerAddress_,
        bytes calldata extraOptionalArgs_
    ) external payable;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

/**
 * @title ITeleport
 * @dev Interface for the Teleport contract, which allows for cross-chain communication and messages transfer using different providers.
 */
interface ITeleport {
    /**
     * @notice Emitted when collecting fees
     * @param serviceFee The amount of service fee collected
     */
    event TransmissionFees(uint256 serviceFee);

    /**
     * @dev Transmits a message to the specified target chain ID. The message will be delivered using the most suitable provider.
     * @param targetChainId The ID of the target chain
     * @param transmissionReceiver The address of the receiver on the target chain
     * @param dAppId The ID of the dApp on the target chain
     * @param payload The message payload
     */
    function transmit(
        uint8 targetChainId,
        bytes calldata transmissionReceiver,
        bytes32 dAppId,
        bytes calldata payload
    ) external payable;

    /**
     * @notice Selects a provider to bridge the message to the target chain
     * @param targetChainId_ The chainID where the message should be delivered to
     * @param transmissionReceiver_ The address of the contract in the target chain to receive the transmission
     * @param dAppId_ ID for the dApp that the message belongs to
     * @param payload_ The dApp-specific message data
     * @param extraOptionalArgs_ Extra optional arguments to be passed to the provider. This allow for specific provider configurations. Send bytes('') if not needed
     */
    function transmitWithArgs(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external payable;

    /**
     * @dev Transmits a message to the specified target chain ID. The message will be delivered using the specified provider.
     * @param targetChainId The ID of the target chain
     * @param transmissionReceiver The address of the receiver on the target chain
     * @param dAppId The ID of the dApp on the target chain
     * @param payload The message payload
     * @param providerAddress The address of the provider to use
     */
    function transmitWithProvider(
        uint8 targetChainId,
        bytes calldata transmissionReceiver,
        bytes32 dAppId,
        bytes calldata payload,
        address providerAddress,
        bytes memory extraOptionalArgs_
    ) external payable;

    /**
     * @dev Delivers a message to this chain.
     * @param args The message arguments, which depend on the provider. See the provider's documentation for more information.
     */
    function deliver(address providerAddress, bytes calldata args) external;

    /**
     * @dev Returns the currently set teleport fee.
     * @return The teleport fee amount
     */
    function teleportFee() external view returns (uint256);

    /**
     * @dev Returns the fee for the automatic selected provider.
     * @return The provider fee amount
     */
    function providerFee(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view returns (uint256);

    /**
     * @dev Returns the fee for the stated provider.
     * @return The provider fee amount
     */
    function providerFee(
        address providerAddress_,
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view returns (uint256);

    /**
     * @dev Returns the currently set service fee.
     * @return The service fee amount
     */
    function serviceFee(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view returns (uint256);

    /**
     * @dev Returns the currently set service fee.
     * @return The service fee amount
     */
    function serviceFee(
        address providerAddress_,
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view returns (uint256);

    struct DappTransmissionReceive {
        bytes teleportSender;
        uint8 sourceChainId;
        bytes dappTransmissionSender;
        address dappTransmissionReceiver;
        bytes32 dAppId;
        bytes payload;
    }

    /**
     * @dev Notifies the teleport that the provider has received a new message. Teleport should invoke the related dapps.
     * @param args The arguments of the message.
     */
    function onProviderReceive(DappTransmissionReceive calldata args) external;

    function configProviderSelector(bytes calldata configData, bytes[] calldata signatures_) external;

    function configProvider(bytes calldata configData, address providerAddress, bytes[] calldata signatures_) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface ITeleportDApp {
    /**
     * @notice Called by a Teleport contract to deliver a verified payload to a dApp
     * @param _sourceChainId The Abridge chainID where the transmission originated
     * @param _transmissionSender The address that invoked `transmit()` on the source chain
     * @param _dAppId an identifier for the dApp
     * @param _payload a dApp-specific byte array with the message data
     */
    function onTeleportMessage(
        uint8 _sourceChainId,
        bytes calldata _transmissionSender,
        bytes32 _dAppId,
        bytes calldata _payload
    ) external;
}

// solhint-disable no-inline-assembly
// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

library LibRouter {
    bytes32 private constant STORAGE_POSITION = keccak256("diamond.standard.router.storage");

    /// @notice Struct containing information about a token's address and its native chain
    struct NativeCollectionWithChainId {
        // Native Abridge chain id
        uint8 chainId;
        // Token contract native address
        bytes contractAddress;
    }

    struct Storage {
        // Maps Abridge chainId => (nativeToken => wrappedToken)
        mapping(uint8 => mapping(bytes => address)) nativeToWrappedCollection;
        // Maps wrapped tokens in the current chain to their native chain + token address
        mapping(address => NativeCollectionWithChainId) wrappedToNativeCollection;
        // Who is allowed to send us teleport messages by Abridge chain id
        mapping(uint8 => bytes) bridgeAddressByChainId;
        // The Abridge chainId of the current chain
        uint8 chainId;
        // Address of the teleport contract to send/receive transmissions to/from
        address teleportAddress;
        bytes32 dAppId;
    }

    /// @notice sets the wrapped to native token mapping
    function setCollectionMappings(
        uint8 sourceChain_,
        bytes memory nativeCollection_,
        address deployedCollection
    ) internal {
        Storage storage rs = routerStorage();
        rs.nativeToWrappedCollection[sourceChain_][nativeCollection_] = deployedCollection;
        NativeCollectionWithChainId storage wrappedToNativeCollection = rs.wrappedToNativeCollection[
            deployedCollection
        ];
        wrappedToNativeCollection.chainId = sourceChain_;
        wrappedToNativeCollection.contractAddress = nativeCollection_;
    }

    function routerStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {IWrappedTokenErrors} from "./interfaces/IDiamondErrors.sol";

/**
 * @notice Used for the wrapped versions of bridged ERC721 collections
 */
contract WrappedERC721 is ERC721Enumerable, Pausable, Ownable {
    /// @dev We can't use baseURI as it is non-standard, so we manage tokenURIs individually
    mapping(uint256 => string) private _tokenURIs;

    /**
     *  @notice Construct a new WrappedERC721 contract
     *  @param collectionName_ The collection name
     *  @param collectionSymbol_ The collection symbol
     */
    constructor(
        string memory collectionName_,
        string memory collectionSymbol_
    ) ERC721(collectionName_, collectionSymbol_) {}

    /**
     * @param tokenId_ ID of the token
     * @return The token URI
     */
    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        if (!_exists(tokenId_)) {
            revert IWrappedTokenErrors.URIQueryForNonexistentToken();
        }
        return _tokenURIs[tokenId_];
    }

    /**
     * @notice Mints a number of tokens at once
     * @param to_ Receiver address
     * @param tokenIds_ Array of token IDs
     * @param tokenURIs_ Array of corresponding token URIs
     */
    function batchMint(address to_, uint256[] calldata tokenIds_, string[] calldata tokenURIs_) external onlyOwner {
        if (tokenIds_.length != tokenURIs_.length) {
            revert IWrappedTokenErrors.WrongBatchMintParameters();
        }
        for (uint256 i; i < tokenIds_.length; ) {
            _tokenURIs[tokenIds_[i]] = tokenURIs_[i];
            super._mint(to_, tokenIds_[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Burns a number of tokens at once
     * @param owner_ Owner of the tokens
     * @param tokenIds_ Array of token IDs
     */
    function batchBurnFrom(address owner_, uint256[] calldata tokenIds_) external onlyOwner {
        for (uint256 i; i < tokenIds_.length; ) {
            if (!_isApprovedOrOwner(_msgSender(), tokenIds_[i])) {
                revert IWrappedTokenErrors.BurnNotApproved();
            }
            if (ownerOf(tokenIds_[i]) != owner_) {
                revert IWrappedTokenErrors.WrongOwner();
            }
            super._burn(tokenIds_[i]);
            delete _tokenURIs[tokenIds_[i]];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Updates the token URIs for existing tokens
     * @param tokenIds_ Array of token IDs
     * @param tokenURIs_ Array of corresponding token URIs
     */
    function batchUpdateTokenURI(uint256[] calldata tokenIds_, string[] calldata tokenURIs_) external onlyOwner {
        if (tokenIds_.length != tokenURIs_.length) {
            revert IWrappedTokenErrors.WrongBatchUpdateParameters();
        }
        for (uint256 i; i < tokenIds_.length; ) {
            if (!_exists(tokenIds_[i])) {
                revert IWrappedTokenErrors.URIQueryForNonexistentToken();
            }
            _tokenURIs[tokenIds_[i]] = tokenURIs_[i];
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Pauses the contract
    function pause() public onlyOwner {
        super._pause();
    }

    /// @notice Unpauses the contract
    function unpause() public onlyOwner {
        super._unpause();
    }

    /// @notice Prevent actions on a paused contract
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from_, to_, tokenId_, batchSize);

        if (paused()) {
            revert IWrappedTokenErrors.TokenTransferWhilePaused();
        }
    }
}