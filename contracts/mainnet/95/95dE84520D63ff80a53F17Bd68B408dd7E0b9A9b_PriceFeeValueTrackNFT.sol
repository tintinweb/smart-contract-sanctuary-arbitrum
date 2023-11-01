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
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

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
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

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

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AbstractNFT is ERC721, Ownable {
    // State variables
    address internal token;
    address internal dev;
    uint256 internal mintFee;
    uint16 internal acquisitionTaxBasisPoints;

    mapping(uint256 => uint24) internal pixelColor;

    mapping(uint256 => uint256) internal prices;

    // maps an index to a tokenId. Enables enumerating tokens.
    mapping(uint256 => uint256) internal idmap;
    uint256 internal idcount;

    constructor(
        string memory __name,
        address _token,
        address _dev,
        uint256 _mintFee,
        uint16 _acquisitionTaxBasisPoints
    ) public ERC721(__name, "PX") {
        token = _token;
        dev = _dev;
        mintFee = _mintFee;
        acquisitionTaxBasisPoints = _acquisitionTaxBasisPoints;
    }

    function getToken() public view returns (address) {
        return token;
    }

    function getDevAddress() public view returns (address) {
        return dev;
    }

    function getMintFee() public view returns (uint256) {
        return mintFee;
    }

    function getAcquisitionTaxBasisPoints() public view returns (uint16) {
        return acquisitionTaxBasisPoints;
    }

    // Changers

    function changeToken(address _newToken) public onlyOwner {
        token = _newToken;
    }

    function changeDevAddress(address _newDev) public onlyOwner {
        dev = _newDev;
    }

    function changeMintFee(uint256 _newFee) public onlyOwner {
        mintFee = _newFee;
    }

    function changeAcquisitionTaxBasisPoints(uint16 _newbp) public onlyOwner {
        acquisitionTaxBasisPoints = _newbp;
    }

    function getIdCount() public view returns (uint256) {
        return idcount;
    }

    function getTokenIdsBulk(
        uint256[] calldata indices
    ) public view returns (uint256[] memory) {
        uint256[] memory rv = new uint256[](indices.length);

        // WARN: This unbounded for loop is an anti-pattern
        for (uint i = 0; i < indices.length; i++) {
            rv[i] = idmap[indices[i]];
        }

        return rv;
    }

    function getTokenIdsRange(
        uint256 from,
        uint256 to
    ) public view returns (uint256[] memory) {
        uint256[] memory rv = new uint256[](to - from);
        uint16 k = 0;

        // WARN: This unbounded for loop is an anti-pattern
        for (uint256 i = from; i < to; i++) {
            rv[k] = idmap[i];
            k++;
        }

        return rv;
    }

    function unsafeTransferPixel(uint256 tokenId, address to) public virtual {
        // Virtual function
    }

    /**
     * Minting functions
     */
    function mintPixel(uint256 id, uint24 c) public virtual {
        // Virtual function
    }

    function mintPixelBulk(
        uint256[] calldata tokenIds,
        uint24[] calldata c
    ) public virtual {
        // Virtual function
    }

    /**
     * Getters
     */
    function getPixelColor(uint256 tokenId) public view returns (uint24) {
        return pixelColor[tokenId];
    }

    function getPixelColorBulk(
        uint256[] calldata tokenIds
    ) public view returns (uint24[] memory) {
        uint24[] memory rv = new uint24[](tokenIds.length);

        // WARN: This unbounded for loop is an anti-pattern
        for (uint i = 0; i < tokenIds.length; i++) {
            rv[i] = pixelColor[tokenIds[i]];
        }

        return rv;
    }

    function getPixelColorBulkRange(
        uint256 from,
        uint256 to
    ) public view returns (uint24[] memory) {
        uint24[] memory rv = new uint24[](to - from);
        uint16 k = 0;
        // WARN: This unbounded for loop is an anti-pattern
        for (uint256 i = from; i < to; i++) {
            rv[k] = pixelColor[idmap[i]];
            k++;
        }

        return rv;
    }

    function getTokenIdsAndPixelColorsBulkRange(
        uint256 from,
        uint256 to
    ) public view returns (uint256[] memory, uint24[] memory) {
        uint256[] memory rv_ids = new uint256[](to - from);
        uint24[] memory rv_cols = new uint24[](to - from);

        uint16 k = 0;

        // WARN: This unbounded for loop is an anti-pattern
        for (uint256 i = from; i < to; i++) {
            rv_ids[k] = idmap[i];
            rv_cols[k] = pixelColor[idmap[i]];
            k++;
        }

        return (rv_ids, rv_cols);
    }

    function getTokenIdsAndPixelColorsAndUserIndicesBulkRange(
        uint256 from,
        uint256 to,
        address user
    ) public view returns (uint256[] memory, uint24[] memory,  bool[] memory) {
        uint256[] memory rv_ids = new uint256[](to - from);
        uint24[] memory rv_cols = new uint24[](to - from);
        bool[] memory ownedByUser = new bool[](to - from);

        uint16 k = 0;

        // WARN: This unbounded for loop is an anti-pattern
        for (uint256 i = from; i < to; i++) {
            rv_ids[k] = idmap[i];
            rv_cols[k] = pixelColor[idmap[i]];

            if (_ownerOf(idmap[i]) == user) {
                ownedByUser[k] = true;
            } else {
                ownedByUser[k] = false;
            }

            // last thing to do.
            k++;
        }

        return (rv_ids, rv_cols, ownedByUser);
    }

    /**
     * Price Getters
     */
    function getPixelPrice(uint256 tokenId) public view returns (uint256) {
        return prices[tokenId];
    }

    function getPixelPriceBulk(
        uint256[] calldata tokenIds
    ) public view returns (uint256[] memory) {
        uint256[] memory rv = new uint256[](tokenIds.length);

        // WARN: This unbounded for loop is an anti-pattern
        for (uint i = 0; i < tokenIds.length; i++) {
            rv[i] = prices[tokenIds[i]];
        }

        return rv;
    }

    function getPixelPriceBulkRange(
        uint256 from,
        uint256 to
    ) public view returns (uint256[] memory) {
        uint256[] memory rv = new uint256[](to - from);
        uint16 k = 0;
        for (uint256 i = from; i < to; i++) {
            rv[k] = prices[idmap[i]];
            k++;
        }
        return rv;
    }

    /**
     * Setters
     */
    function setPixelColor(uint256 tokenId, uint24 c) public {
        require(_ownerOf(tokenId) == msg.sender);
        pixelColor[tokenId] = c;
    }

    function setPixelColorBulk(
        uint256[] calldata tokenIds,
        uint24[] calldata c
    ) public {
        require(tokenIds.length == c.length);

        // WARN: This unbounded for loop is an anti-pattern
        for (uint i = 0; i < tokenIds.length; i++) {
            require(_ownerOf(tokenIds[i]) == msg.sender);
            pixelColor[tokenIds[i]] = c[i];
        }
    }

    /**
     * Acquisition
     */
    function acquirePixel(uint256 id) public virtual {
        // Virtual function
    }

    function acquirePixelWithChange(uint256 id, uint24 c) public virtual {
        // Virtual function
    }

    function acquirePixelBulk(uint256[] calldata tokenIds) public virtual {
        // Virtual function
    }

    function acquirePixelBulkWithChange(
        uint256[] calldata tokenIds,
        uint24[] calldata c
    ) public virtual {
        // Virtual function
    }

    /*
     * Full committers
     */
    function commit(
        uint256 tokenId,
        uint24 c,
        uint256 newPrice
    ) public virtual {
        // TODO: Implement in derived contract
    }

    /*
     * Full committers
     */
    function commitBulk(
        uint256[] calldata tokenIds,
        uint24[] calldata cs,
        uint256[] calldata newPrices
    ) public virtual {
        // TODO: Implement in derived contract
    }

    function getCommitFeeTaxPriceAndCounts(
        uint256 tokenId,
        uint256 newPrice,
        address beneficiary
    ) public view virtual returns (uint256[3] memory, uint16[2] memory) {
        // Returns: [fee, tax, total price], [mint count, overwrite count]
        // Fee + Tax + Price should be equal to the amount paid by the committer.
        // Fee + Tax is received by devs, and price is received by pixel owners.
        // TODO: Implement in derived contract
    }

    function getCommitBulkFeeTaxPriceAndCounts(
        uint256[] calldata tokenIds,
        uint256[] calldata newPrices,
        address beneficiary
    ) public view virtual returns (uint256[3] memory, uint16[2] memory) {
        // Returns: fee, tax, total price, mint count, overwrite count
        // Fee + Tax + Price should be equal to the amount paid by the committer.
        // Fee + Tax is received by devs, and price is received by pixel owners.
        // TODO: Implement in derived contract
    }

    /*
     * Full committers
     */
    function commitForBeneficiary(
        uint256 tokenId,
        uint24 c,
        uint256 newPrice,
        address beneficiary
    ) public virtual {
        // TODO: Implement in derived contract
    }

    /*
     * Full committers
     */
    function commitBulkForBeneficiary(
        uint256[] calldata tokenIds,
        uint24[] calldata cs,
        uint256[] calldata newPrices,
        address beneficiary
    ) public virtual {
        // TODO: Implement in derived contract
    }
}

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./AbstractNFT.sol";

// This contract inherits all functionality from AbstractNFT and implements arbitrary price for pixels.

contract PriceFeeValueTrackNFT is AbstractNFT {
    uint16 internal priceFeeBasisPoints;

    mapping(address => uint256) private userValues;

    constructor(
        string memory __name,
        address _token,
        address _dev,
        uint256 _mintFee,
        uint16 _priceFeeBasisPoints,
        uint16 _acquisitionTaxBasisPoints
    )
        public
        AbstractNFT(__name, _token, _dev, _mintFee, _acquisitionTaxBasisPoints)
    {
        priceFeeBasisPoints = _priceFeeBasisPoints;
    }

    function getPriceFeeBasisPoints() public view returns (uint16) {
        return priceFeeBasisPoints;
    }

    function changePriceFeeBasisPoints(uint16 _newbp) public onlyOwner {
        priceFeeBasisPoints = _newbp;
    }

    function valueOf(address user) public view returns (uint256) {
        return userValues[user];
    }

    function unsafeTransferPixel(uint256 tokenId, address to) public override {
        require(_ownerOf(tokenId) == msg.sender);

        // Change original owners value
        userValues[_ownerOf(tokenId)] -= prices[tokenId];

        // Change users value
        userValues[to] += prices[tokenId];

        // transfer
        _transfer(msg.sender, to, tokenId);
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

         // Change original owners value
        userValues[_ownerOf(tokenId)] -= prices[tokenId];

        // Change users value
        userValues[to] += prices[tokenId];

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
    ) internal override {

        // Change original owners value
        userValues[_ownerOf(tokenId)] -= prices[tokenId];

        // Change users value
        userValues[to] += prices[tokenId];

        _transfer(from, to, tokenId);
        require(__checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function __checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length > 0) {
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
     * Minting functions
     */
    function mintPixel(uint256 id, uint24 c) public pure override {
        revert();
    }

    function mintPixelBulk(
        uint256[] calldata tokenIds,
        uint24[] calldata c
    ) public pure override {
        revert();
    }

    /*
     * Full committers
     */
    function commit(
        uint256 tokenId,
        uint24 c,
        uint256 newPrice
    ) public override {
        uint256 totalFee = 0;

        if (_exists(tokenId)) {
            if (_ownerOf(tokenId) == msg.sender) {
                pixelColor[tokenId] = c;

                // Change users value bases on price difference
                // Change can be negative
                if (newPrice > prices[tokenId]) {
                    userValues[msg.sender] += newPrice - prices[tokenId];

                    // Apply price based fee
                    totalFee +=
                        ((newPrice - prices[tokenId]) * priceFeeBasisPoints) /
                        10000;
                } else {
                    userValues[msg.sender] -= prices[tokenId] - newPrice;
                }

                prices[tokenId] = newPrice;
            } else {
                // Change original owners value
                userValues[_ownerOf(tokenId)] -= prices[tokenId];

                // Change users value
                userValues[msg.sender] += newPrice;

                if (newPrice > prices[tokenId]) {
                    // Apply price based fee
                    totalFee +=
                        ((newPrice - prices[tokenId]) * priceFeeBasisPoints) /
                        10000;
                }

                // Pay pixel owner BEFORE CALLING _transfer !!!!
                IERC20(token).transferFrom(
                    msg.sender,
                    _ownerOf(tokenId),
                    (prices[tokenId] * (10000 - acquisitionTaxBasisPoints)) /
                        10000
                );

                // Acquire token
                _transfer(_ownerOf(tokenId), msg.sender, tokenId);

                // Transaction tax
                totalFee +=
                    (prices[tokenId] * (acquisitionTaxBasisPoints)) /
                    10000;

                // Set color
                pixelColor[tokenId] = c;

                // Set new price
                prices[tokenId] = newPrice;
            }
        } else {
            _mint(msg.sender, tokenId);

            idmap[idcount] = tokenId;
            idcount = idcount + 1;

            // Set color
            pixelColor[tokenId] = c;

            // Increase users value
            userValues[msg.sender] += newPrice;

            // Apply price based fee (price[tokenId] = 0)
            totalFee += mintFee + (newPrice * priceFeeBasisPoints) / 10000;

            // Set new price
            prices[tokenId] = newPrice;
        }

        IERC20(token).transferFrom(msg.sender, dev, totalFee);
    }

    /*
     * Full committers
     */
    function commitBulk(
        uint256[] calldata tokenIds,
        uint24[] calldata cs,
        uint256[] calldata newPrices
    ) public override {
        uint256 totalFee = 0;

        // WARN: This unbounded for loop is an anti-pattern
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_exists(tokenIds[i])) {
                if (_ownerOf(tokenIds[i]) == msg.sender) {
                    pixelColor[tokenIds[i]] = cs[i];

                    // Change users value bases on price difference
                    // Change can be negative
                    if (newPrices[i] > prices[tokenIds[i]]) {
                        userValues[msg.sender] +=
                            newPrices[i] -
                            prices[tokenIds[i]];

                        // Apply price based fee
                        totalFee +=
                            ((newPrices[i] - prices[tokenIds[i]]) *
                                priceFeeBasisPoints) /
                            10000;
                    } else {
                        userValues[msg.sender] -=
                            prices[tokenIds[i]] -
                            newPrices[i];
                    }

                    prices[tokenIds[i]] = newPrices[i];
                } else {
                    // Change original owners value
                    userValues[_ownerOf(tokenIds[i])] -= prices[tokenIds[i]];

                    // Change users value
                    userValues[msg.sender] += newPrices[i];

                    if (newPrices[i] > prices[tokenIds[i]]) {
                        // Apply price based fee
                        totalFee +=
                            ((newPrices[i] - prices[tokenIds[i]]) *
                                priceFeeBasisPoints) /
                            10000;
                    }

                    // Pay pixel owner BEFORE CALLING _transfer !!!!!!
                    IERC20(token).transferFrom(
                        msg.sender,
                        _ownerOf(tokenIds[i]),
                        (prices[tokenIds[i]] *
                            (10000 - acquisitionTaxBasisPoints)) / 10000
                    );

                    // Acquire token
                    _transfer(_ownerOf(tokenIds[i]), msg.sender, tokenIds[i]);

                    // Transaction fee
                    totalFee +=
                        (prices[tokenIds[i]] * (acquisitionTaxBasisPoints)) /
                        10000;

                    // repaint
                    pixelColor[tokenIds[i]] = cs[i];

                    // Set new price
                    prices[tokenIds[i]] = newPrices[i];
                }
            } else {
                _mint(msg.sender, tokenIds[i]);

                idmap[idcount] = tokenIds[i];
                idcount = idcount + 1;

                pixelColor[tokenIds[i]] = cs[i];

                // Apply price based fee (prices[tokenIds[i]] = 0)
                totalFee +=
                    mintFee +
                    (newPrices[i] * priceFeeBasisPoints) /
                    10000;

                // Change users value
                userValues[msg.sender] += newPrices[i];

                // Set new price
                prices[tokenIds[i]] = newPrices[i];
            }
        }

        IERC20(token).transferFrom(msg.sender, dev, totalFee);
    }

    function getCommitFeeTaxPriceAndCounts(
        uint256 tokenId,
        uint256 newPrice,
        address beneficiary
    ) public view override returns (uint256[3] memory, uint16[2] memory) {
        // Returns: fee, tax, total price, mint count, overwrite count
        // Fee + Tax + Price should be equal to the amount paid by the committer.
        // Fee + Tax is received by devs, and price is received by pixel owners.

        uint256[3] memory _feeTaxPrice;
        _feeTaxPrice[0] = 0;
        _feeTaxPrice[1] = 0;
        _feeTaxPrice[2] = 0;

        uint16[2] memory _mcoc;
        _mcoc[0] = 0;
        _mcoc[1] = 0;

        if (_exists(tokenId)) {
            if (_ownerOf(tokenId) == beneficiary) {
                // nothing

                if (newPrice > prices[tokenId]) {
                    _feeTaxPrice[0] +=
                        ((newPrice - prices[tokenId]) * priceFeeBasisPoints) /
                        10000;
                }
            } else {
                _feeTaxPrice[2] =
                    (prices[tokenId] * (10000 - acquisitionTaxBasisPoints)) /
                    10000;

                if (newPrice > prices[tokenId]) {
                    _feeTaxPrice[0] +=
                        ((newPrice - prices[tokenId]) * priceFeeBasisPoints) /
                        10000;
                }

                _feeTaxPrice[1] =
                    (prices[tokenId] * (acquisitionTaxBasisPoints)) /
                    10000;

                _mcoc[1]++;
            }
        } else {
            _feeTaxPrice[0] +=
                mintFee +
                (newPrice * priceFeeBasisPoints) /
                10000;
            _mcoc[0]++;
        }

        return (_feeTaxPrice, _mcoc);
    }

    function getCommitBulkFeeTaxPriceAndCounts(
        uint256[] calldata tokenIds,
        uint256[] calldata newPrices,
        address beneficiary
    ) public view override returns (uint256[3] memory, uint16[2] memory) {
        // Returns: fee, tax, total price, mint count, overwrite count
        // Fee + Tax + Price should be equal to the amount paid by the committer.
        // Fee + Tax is received by devs, and price is received by pixel owners.

        uint256[3] memory _feeTaxPrice;
        _feeTaxPrice[0] = 0;
        _feeTaxPrice[1] = 0;
        _feeTaxPrice[2] = 0;

        uint16[2] memory _mcoc;
        _mcoc[0] = 0;
        _mcoc[1] = 0;

        // WARN: This unbounded for loop is an anti-pattern
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_exists(tokenIds[i])) {
                if (_ownerOf(tokenIds[i]) == beneficiary) {
                    if (newPrices[i] > prices[tokenIds[i]]) {
                        _feeTaxPrice[0] +=
                            ((newPrices[i] - prices[tokenIds[i]]) *
                                priceFeeBasisPoints) /
                            10000;
                    }
                } else {
                    _feeTaxPrice[2] +=
                        (prices[tokenIds[i]] *
                            (10000 - acquisitionTaxBasisPoints)) /
                        10000;

                    if (newPrices[i] > prices[tokenIds[i]]) {
                        _feeTaxPrice[0] +=
                            ((newPrices[i] - prices[tokenIds[i]]) *
                                priceFeeBasisPoints) /
                            10000;
                    }

                    _feeTaxPrice[1] +=
                        (prices[tokenIds[i]] * (acquisitionTaxBasisPoints)) /
                        10000;

                    _mcoc[1]++;
                }
            } else {
                _feeTaxPrice[0] +=
                    mintFee +
                    (newPrices[i] * priceFeeBasisPoints) /
                    10000;
                _mcoc[0]++;
            }
        }

        return (_feeTaxPrice, _mcoc);
    }

    /*
     * Full committers
     */
    function commitForBeneficiary(
        uint256 tokenId,
        uint24 c,
        uint256 newPrice,
        address beneficiary
    ) public override {
        uint256 totalFee = 0;

        if (_exists(tokenId)) {
            if (_ownerOf(tokenId) == beneficiary) {
                pixelColor[tokenId] = c;

                // Change users value bases on price difference
                // Change can be negative
                if (newPrice > prices[tokenId]) {
                    userValues[beneficiary] += newPrice - prices[tokenId];

                    // Apply price based fee
                    totalFee +=
                        ((newPrice - prices[tokenId]) * priceFeeBasisPoints) /
                        10000;
                } else {
                    userValues[beneficiary] -= prices[tokenId] - newPrice;
                }

                prices[tokenId] = newPrice;
            } else {
                // Change original owners value
                userValues[_ownerOf(tokenId)] -= prices[tokenId];

                // Change users value
                userValues[beneficiary] += newPrice;

                if (newPrice > prices[tokenId]) {
                    // Apply price based fee
                    totalFee +=
                        ((newPrice - prices[tokenId]) * priceFeeBasisPoints) /
                        10000;
                }

                // Acquire token
                _transfer(_ownerOf(tokenId), beneficiary, tokenId);

                // Pay pixel owner
                IERC20(token).transferFrom(
                    beneficiary,
                    _ownerOf(tokenId),
                    (prices[tokenId] * (10000 - acquisitionTaxBasisPoints)) /
                        10000
                );

                // Transaction tax
                totalFee +=
                    (prices[tokenId] * (acquisitionTaxBasisPoints)) /
                    10000;

                // Set color
                pixelColor[tokenId] = c;

                // Set new price
                prices[tokenId] = newPrice;
            }
        } else {
            _mint(beneficiary, tokenId);

            idmap[idcount] = tokenId;
            idcount = idcount + 1;

            // Set color
            pixelColor[tokenId] = c;

            // Increase users value
            userValues[beneficiary] += newPrice;

            // Apply price based fee (price[tokenId] = 0)
            totalFee += (newPrice * priceFeeBasisPoints) / 10000;

            // Set new price
            prices[tokenId] = newPrice;
        }

        IERC20(token).transferFrom(beneficiary, dev, totalFee);
    }

    /*
     * Full committers
     */
    /*
     *  Does not compile; stack too deep
     */
    function commitBulkForBeneficiary(
        uint256[] calldata tokenIds,
        uint24[] calldata cs,
        uint256[] calldata newPrices,
        address beneficiary
    ) public override {
        // uint256 totalFee = 0;

        // // WARN: This unbounded for loop is an anti-pattern
        // for (uint i = 0; i < tokenIds.length; i++) {
        //     if (_exists(tokenIds[i])) {
        //         if (_ownerOf(tokenIds[i]) == msg.sender) {
        //             pixelColor[tokenIds[i]] = cs[i];

        //             // Apply price based fee
        //             if (newPrices[i] > prices[tokenIds[i]]) {
        //                 totalFee +=
        //                     ((newPrices[i] - prices[tokenIds[i]]) *
        //                         priceFeeBasisPoints) /
        //                     10000;
        //             }

        //             prices[tokenIds[i]] = newPrices[i];
        //         } else {
        //             // Acquire token
        //             _transfer(_ownerOf(tokenIds[i]), msg.sender, tokenIds[i]);

        //             // Pay pixel owner
        //             // New variable is needed to avoid 'stack too deep' error.
        //             uint256 transferprice = (prices[tokenIds[i]] *
        //                 (10000 - acquisitionTaxBasisPoints)) / 10000;

        //             IERC20(token).transferFrom(
        //                 beneficiary,
        //                 _ownerOf(tokenIds[i]),
        //                 transferprice
        //             );

        //             // Transaction fee
        //             totalFee +=
        //                 (prices[tokenIds[i]] * (acquisitionTaxBasisPoints)) /
        //                 10000;

        //             // repaint
        //             pixelColor[tokenIds[i]] = cs[i];

        //             // Apply price based fee
        //             if (newPrices[i] > prices[tokenIds[i]]) {
        //                 totalFee +=
        //                     ((newPrices[i] - prices[tokenIds[i]]) *
        //                         priceFeeBasisPoints) /
        //                     10000;
        //             }

        //             // Set new price
        //             prices[tokenIds[i]] = newPrices[i];
        //         }
        //     } else {
        //         _mint(msg.sender, tokenIds[i]);

        //         idmap[idcount] = tokenIds[i];
        //         idcount = idcount + 1;

        //         pixelColor[tokenIds[i]] = cs[i];

        //         // Apply price based fee (prices[tokenIds[i]] = 0)
        //         totalFee += (newPrices[i] * priceFeeBasisPoints) / 10000;

        //         // Set new price
        //         prices[tokenIds[i]] = newPrices[i];
        //     }
        // }

        // IERC20(token).transferFrom(msg.sender, dev, totalFee);
        uint256 totalFee = 0;

        // WARN: This unbounded for loop is an anti-pattern
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_exists(tokenIds[i])) {
                if (_ownerOf(tokenIds[i]) == beneficiary) {
                    pixelColor[tokenIds[i]] = cs[i];

                    // Change users value bases on price difference
                    // Change can be negative
                    if (newPrices[i] > prices[tokenIds[i]]) {
                        userValues[beneficiary] +=
                            newPrices[i] -
                            prices[tokenIds[i]];

                        // Apply price based fee
                        totalFee +=
                            ((newPrices[i] - prices[tokenIds[i]]) *
                                priceFeeBasisPoints) /
                            10000;
                    } else {
                        userValues[beneficiary] -=
                            prices[tokenIds[i]] -
                            newPrices[i];
                    }

                    prices[tokenIds[i]] = newPrices[i];
                } else {
                    // Change original owners value
                    userValues[_ownerOf(tokenIds[i])] -= prices[tokenIds[i]];

                    // Change users value
                    userValues[beneficiary] += newPrices[i];

                    if (newPrices[i] > prices[tokenIds[i]]) {
                        // Apply price based fee
                        totalFee +=
                            ((newPrices[i] - prices[tokenIds[i]]) *
                                priceFeeBasisPoints) /
                            10000;
                    }

                    // Acquire token
                    _transfer(_ownerOf(tokenIds[i]), beneficiary, tokenIds[i]);

                    // Pay pixel owner
                    // New variable is needed to avoid 'stack too deep' error.
                    uint256 transferprice = (prices[tokenIds[i]] *
                        (10000 - acquisitionTaxBasisPoints)) / 10000;

                    IERC20(token).transferFrom(
                        beneficiary,
                        _ownerOf(tokenIds[i]),
                        transferprice
                    );

                    // Transaction fee
                    totalFee +=
                        (prices[tokenIds[i]] * (acquisitionTaxBasisPoints)) /
                        10000;

                    // repaint
                    pixelColor[tokenIds[i]] = cs[i];

                    // Set new price
                    prices[tokenIds[i]] = newPrices[i];
                }
            } else {
                _mint(beneficiary, tokenIds[i]);

                idmap[idcount] = tokenIds[i];
                idcount = idcount + 1;

                pixelColor[tokenIds[i]] = cs[i];

                // Apply price based fee (prices[tokenIds[i]] = 0)
                totalFee += (newPrices[i] * priceFeeBasisPoints) / 10000;

                // Change users value
                userValues[beneficiary] += newPrices[i];

                // Set new price
                prices[tokenIds[i]] = newPrices[i];
            }
        }

        IERC20(token).transferFrom(beneficiary, dev, totalFee);
    }
}