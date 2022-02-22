// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
 * ```
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
 */
library EnumerableSetUpgradeable {
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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./UtilitiesUpgradeable.sol";

// Do not add state to this contract.
//
contract AdminableUpgradeable is UtilitiesUpgradeable {

    mapping(address => bool) private admins;

    function __Adminable_init() internal initializer {
        UtilitiesUpgradeable.__Utilities__init();
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = false;
        }
    }

    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if(_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns(bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UtilitiesUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {

    function __Utilities__init() internal initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        _pause();
    }

    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "0 address");
        _;
    }

    modifier nonZeroLength(uint[] memory _array) {
        require(_array.length > 0, "Empty array");
        _;
    }

    modifier lengthsAreEqual(uint[] memory _array1, uint[] memory _array2) {
        require(_array1.length == _array2.length, "Unequal lengths");
        _;
    }

    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BBase64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in BBase64
/// @notice NOT BUILT BY ETHERORCS (or Toadz) TEAM. Thanks Bretch Devos!
library BBase64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)

               // read 3 bytes
               let input := mload(dataPtr)

               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ToadTraitConstants {

    string constant public SVG_HEADER = '<svg id="toad" width="100%" height="100%" version="1.1" viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string constant public SVG_FOOTER = '<style>#toad{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>';

    string constant public RARITY = "Rarity";
    string constant public BACKGROUND = "Background";
    string constant public STOOL = "Stool";
    string constant public BODY = "Body";
    string constant public CLOTHES = "Clothes";
    string constant public MOUTH = "Mouth";
    string constant public EYES = "Eyes";
    string constant public ITEM = "Item";
    string constant public HEAD_GEAR = "Head Gear";
    string constant public EXTRA = "Extra";

    string constant public RARITY_COMMON = "Common";
    string constant public RARITY_1_OF_1 = "1 of 1";

    string constant public BACKGROUND_GREY = "Grey";
    string constant public BACKGROUND_PURPLE = "Purple";
    string constant public BACKGROUND_DARK_GREEN = "Dark Green";
    string constant public BACKGROUND_BROWN = "Brown";
    string constant public BACKGROUND_LEMON = "Lemon";
    string constant public BACKGROUND_LAVENDER = "Lavender";
    string constant public BACKGROUND_PINK = "Pink";
    string constant public BACKGROUND_SKY_BLUE = "Sky Blue";
    string constant public BACKGROUND_MINT = "Mint";
    string constant public BACKGROUND_ORANGE = "Orange";
    string constant public BACKGROUND_RED = "Red";
    string constant public BACKGROUND_SKY = "Sky";
    string constant public BACKGROUND_SUNRISE = "Sunrise";
    string constant public BACKGROUND_SPRING = "Spring";
    string constant public BACKGROUND_WATERMELON = "Watermelon";
    string constant public BACKGROUND_SPACE = "Space";
    string constant public BACKGROUND_CLOUDS = "Clouds";
    string constant public BACKGROUND_SWAMP = "Swamp";
    string constant public BACKGROUND_CITY = "City";

    string constant public STOOL_RED_SPOTS = "Red - Spots";
    string constant public STOOL_BROWN = "Brown";
    string constant public STOOL_DEFAULT_BROWN = "Default Brown";
    string constant public STOOL_GREEN = "Green";
    string constant public STOOL_BLUE = "Blue";
    string constant public STOOL_YELLOW = "Yellow";
    string constant public STOOL_GREY = "Grey";
    string constant public STOOL_ORANGE = "Orange";
    string constant public STOOL_ICE = "Ice";
    string constant public STOOL_GOLDEN = "Golden";
    string constant public STOOL_RADIOACTIVE = "Radioactive";

    string constant public BODY_OG_GREEN = "OG Green";
    string constant public BODY_DARK_GREEN = "Dark Green";
    string constant public BODY_ORANGE = "Orange";
    string constant public BODY_GREY = "Grey";
    string constant public BODY_BLUE = "Blue";
    string constant public BODY_BROWN = "Brown";
    string constant public BODY_PURPLE = "Purple";
    string constant public BODY_PINK = "Pink";
    string constant public BODY_RED = "Red";
    string constant public BODY_RAINBOW = "Rainbow";

    string constant public CLOTHES_TURTLENECK_BLUE = "Turtleneck - Blue";
    string constant public CLOTHES_TURTLENECK_GREY = "Turtleneck - Grey";
    string constant public CLOTHES_T_SHIRT_CAMO = "T-shirt - Camo";
    string constant public CLOTHES_T_SHIRT_ROCKET_GREY = "T-shirt - Rocket - Grey";
    string constant public CLOTHES_T_SHIRT_ROCKET_BLUE = "T-shirt - Rocket - Blue";
    string constant public CLOTHES_T_SHIRT_FLY_GREY = "T-shirt - Fly - Grey";
    string constant public CLOTHES_T_SHIRT_FLY_BLUE = "T-shirt - Fly - Blue";
    string constant public CLOTHES_T_SHIRT_FLY_RED = "T-shirt - Fly - Red";
    string constant public CLOTHES_T_SHIRT_HEART_BLACK = "T-shirt - Heart - Black";
    string constant public CLOTHES_T_SHIRT_HEART_PINK = "T-shirt - Heart - Pink";
    string constant public CLOTHES_T_SHIRT_RAINBOW = "T-shirt - Rainbow";
    string constant public CLOTHES_T_SHIRT_SKULL = "T-shirt - Skull";
    string constant public CLOTHES_HOODIE_CAMO = "Hoodie - Camo";
    string constant public CLOTHES_HOODIE_GREY = "Hoodie - Grey";
    string constant public CLOTHES_HOODIE_PINK = "Hoodie - Pink";
    string constant public CLOTHES_HOODIE_LIGHT_BLUE = "Hoodie - Light Blue";
    string constant public CLOTHES_HOODIE_DARK_BLUE = "Hoodie - Dark Blue";
    string constant public CLOTHES_HOODIE_WHITE = "Hoodie - White";
    string constant public CLOTHES_GOLD_CHAIN = "Gold Chain";
    string constant public CLOTHES_FARMER = "Farmer";
    string constant public CLOTHES_MARIO = "Mario";
    string constant public CLOTHES_LUIGI = "Luigi";
    string constant public CLOTHES_ZOMBIE = "Zombie";
    string constant public CLOTHES_WIZARD = "Wizard";
    string constant public CLOTHES_SAIAN = "Saian";
    string constant public CLOTHES_HAWAIIAN_SHIRT = "Hawaiian Shirt";
    string constant public CLOTHES_SUIT_BLACK = "Suit - Black";
    string constant public CLOTHES_SUIT_RED = "Suit - Red";
    string constant public CLOTHES_ROCKSTAR = "Rockstar";
    string constant public CLOTHES_PIRATE = "Pirate";
    string constant public CLOTHES_ASTRONAUT = "Astronaut";

    string constant public MOUTH_SMILE = "Smile";
    string constant public MOUTH_MEH = "Meh";
    string constant public MOUTH_UNIMPRESSED = "Unimpressed";
    string constant public MOUTH_O = "O";
    string constant public MOUTH_GASP = "Gasp";
    string constant public MOUTH_SMALL_GASP = "Small Gasp";
    string constant public MOUTH_LAUGH = "Laugh";
    string constant public MOUTH_LAUGH_TEETH = "Laugh - Teeth";
    string constant public MOUTH_SMILE_BIG = "Smile Big";
    string constant public MOUTH_TONGUE = "Tongue";
    string constant public MOUTH_RAINBOW_VOM = "Rainbow Vom";
    string constant public MOUTH_PIPE = "Pipe";
    string constant public MOUTH_CIGARETTE = "Cigarette";
    string constant public MOUTH_GUM = "Gum";
    string constant public MOUTH_BLUNT = "Blunt";
    string constant public MOUTH_FIRE = "Fire";

    string constant public EYES_LASERS = "Lasers";
    string constant public EYES_CROAKED = "Croaked";
    string constant public EYES_TIRED = "Tired";
    string constant public EYES_SUSPICIOUS = "Suspicious";
    string constant public EYES_EXCITED = "Excited";
    string constant public EYES_ANGRY = "Angry";
    string constant public EYES_ALIEN = "Alien";
    string constant public EYES_EYE_ROLL = "Eye Roll";
    string constant public EYES_WIDE_DOWN = "Wide Down";
    string constant public EYES_WIDE_UP = "Wide Up";
    string constant public EYES_BORED = "Bored";
    string constant public EYES_STONED = "Stoned";
    string constant public EYES_RIGHT_DOWN = "Right Down";
    string constant public EYES_RIGHT_UP = "Right Up";
    string constant public EYES_CLOSED = "Closed";
    string constant public EYES_HEARTS = "Hearts";
    string constant public EYES_WINK = "Wink";
    string constant public EYES_CONTENTFUL = "Contentful";
    string constant public EYES_VR_HEADSET = "VR Headset";
    string constant public EYES_GLASSES_HEART = "Glasses - Heart";
    string constant public EYES_GLASSES_3D = "Glasses - 3D";
    string constant public EYES_GLASSES_SUN = "Glasses - Sun";
    string constant public EYES_EYE_PATCH_LEFT = "Eye Patch - Left";
    string constant public EYES_EYE_PATCH_RIGHT = "Eye Patch - Right";
    string constant public EYES_EYE_PATCH_BORED_LEFT = "Eye Patch Bored - Left";
    string constant public EYES_EYE_PATCH_BORED_RIGHT = "Eye Patch Bored - Right";

    string constant public ITEM_NONE = "None";
    string constant public ITEM_LIGHTSABER_RED = "Lightsaber - Red";
    string constant public ITEM_LIGHTSABER_GREEN = "Lightsaber - Green";
    string constant public ITEM_LIGHTSABER_BLUE = "Lightsaber - Blue";
    string constant public ITEM_SWORD = "Sword";
    string constant public ITEM_WAND = "Wand";
    string constant public ITEM_SHIELD = "Shield";
    string constant public ITEM_FIRE_SWORD = "Fire Sword";
    string constant public ITEM_ICE_SWORD = "Ice Sword";
    string constant public ITEM_AXE = "Axe";
    string constant public ITEM_MACHETE = "Machete";
    string constant public ITEM_HAMMER = "Hammer";
    string constant public ITEM_DOUBLE_AXE = "Double Axe";

    string constant public HEAD_GEAR_NONE = "None";
    string constant public HEAD_GEAR_GUPPI_CAP = "Guppi Cap";
    string constant public HEAD_GEAR_NIKE_CAP = "Nike Cap";
    string constant public HEAD_GEAR_ASH_CAP = "Ash Cap";
    string constant public HEAD_GEAR_PINK_CAP = "Pink Cap";
    string constant public HEAD_GEAR_MUSHROOM_CAP = "Mushroom Cap";
    string constant public HEAD_GEAR_ASTRO_HELMET = "Astro Helmet";
    string constant public HEAD_GEAR_STRAW_HAT = "Straw Hat";
    string constant public HEAD_GEAR_SAILOR_HAT = "Sailor Hat";
    string constant public HEAD_GEAR_PIRATE_HAT = "Pirate Hat";
    string constant public HEAD_GEAR_WIZARD_PURPLE = "Wizard - Purple";
    string constant public HEAD_GEAR_WIZARD_BROWN = "Wizard - Brown";
    string constant public HEAD_GEAR_KIDS_CAP = "Kids Cap";
    string constant public HEAD_GEAR_TOP_HAT = "Top Hat";
    string constant public HEAD_GEAR_PARTY_HAT = "Party Hat";
    string constant public HEAD_GEAR_CROWN = "Crown";
    string constant public HEAD_GEAR_BRAIN = "Brain";
    string constant public HEAD_GEAR_MOHAWK_PURPLE = "Mohawk - Purple";
    string constant public HEAD_GEAR_MOHAWK_GREEN = "Mohawk - Green";
    string constant public HEAD_GEAR_MOHAWK_PINK = "Mohawk - Pink";
    string constant public HEAD_GEAR_AFRO = "Afro";
    string constant public HEAD_GEAR_BASEBALL_CAP_WHITE = "Baseball Cap - White";
    string constant public HEAD_GEAR_BASEBALL_CAP_RED = "Baseball Cap - Red";
    string constant public HEAD_GEAR_BASEBALL_CAP_BLUE = "Baseball Cap - Blue";
    string constant public HEAD_GEAR_BANDANA_PURPLE = "Bandana - Purple";
    string constant public HEAD_GEAR_BANDANA_RED = "Bandana - Red";
    string constant public HEAD_GEAR_BANDANA_BLUE = "Bandana - Blue";
    string constant public HEAD_GEAR_BEANIE_GREY = "Beanie - Grey";
    string constant public HEAD_GEAR_BEANIE_BLUE = "Beanie - Blue";
    string constant public HEAD_GEAR_BEANIE_YELLOW = "Beanie - Yellow";
    string constant public HEAD_GEAR_HALO = "Halo";

    string constant public EXTRA_NONE = "None";
    string constant public EXTRA_FLIES = "Flies";
    string constant public EXTRA_GOLD_CHAIN = "Gold Chain";
    string constant public EXTRA_NECKTIE_RED = "Necktie Red";
    string constant public EXTRA_NECKTIE_PINK = "Necktie Pink";
    string constant public EXTRA_NECKTIE_PURPLE = "Necktie Purple";
}

enum ToadRarity {
    COMMON,
    ONE_OF_ONE
}

enum ToadBackground {
    GREY,
    PURPLE,
    DARK_GREEN,
    BROWN,
    LEMON,
    LAVENDER,
    PINK,
    SKY_BLUE,
    MINT,
    ORANGE,
    RED,
    SKY,
    SUNRISE,
    SPRING,
    WATERMELON,
    SPACE,
    CLOUDS,
    SWAMP,
    CITY
}

enum ToadStool {
    RED_SPOTS,
    BROWN,
    DEFAULT_BROWN,
    GREEN,
    BLUE,
    YELLOW,
    GREY,
    ORANGE,
    ICE,
    GOLDEN,
    RADIOACTIVE
}

enum ToadBody {
    OG_GREEN,
    DARK_GREEN,
    ORANGE,
    GREY,
    BLUE,
    BROWN,
    PURPLE,
    PINK,
    RED,
    RAINBOW
}

enum ToadClothes {
    TURTLENECK_BLUE,
    TURTLENECK_GREY,
    T_SHIRT_CAMO,
    T_SHIRT_ROCKET_GREY,
    T_SHIRT_ROCKET_BLUE,
    T_SHIRT_FLY_GREY,
    T_SHIRT_FLY_BLUE,
    T_SHIRT_FLY_RED,
    T_SHIRT_HEART_BLACK,
    T_SHIRT_HEART_PINK,
    T_SHIRT_RAINBOW,
    T_SHIRT_SKULL,
    HOODIE_CAMO,
    HOODIE_GREY,
    HOODIE_PINK,
    HOODIE_LIGHT_BLUE,
    HOODIE_DARK_BLUE,
    HOODIE_WHITE,
    GOLD_CHAIN,
    FARMER,
    MARIO,
    LUIGI,
    ZOMBIE,
    WIZARD,
    SAIAN,
    HAWAIIAN_SHIRT,
    SUIT_BLACK,
    SUIT_RED,
    ROCKSTAR,
    PIRATE,
    ASTRONAUT
}

enum ToadMouth {
    SMILE,
    MEH,
    UNIMPRESSED,
    O,
    GASP,
    SMALL_GASP,
    LAUGH,
    LAUGH_TEETH,
    SMILE_BIG,
    TONGUE,
    RAINBOW_VOM,
    PIPE,
    CIGARETTE,
    GUM,
    BLUNT,
    FIRE
}

enum ToadEyes {
    LASERS,
    CROAKED,
    TIRED,
    SUSPICIOUS,
    EXCITED,
    ANGRY,
    ALIEN,
    EYE_ROLL,
    WIDE_DOWN,
    WIDE_UP,
    BORED,
    STONED,
    RIGHT_DOWN,
    RIGHT_UP,
    CLOSED,
    HEARTS,
    WINK,
    CONTENTFUL,
    VR_HEADSET,
    GLASSES_HEART,
    GLASSES_3D,
    GLASSES_SUN,
    EYE_PATCH_LEFT,
    EYE_PATCH_RIGHT,
    EYE_PATCH_BORED_LEFT,
    EYE_PATCH_BORED_RIGHT
}

enum ToadItem {
    NONE,
    LIGHTSABER_RED,
    LIGHTSABER_GREEN,
    LIGHTSABER_BLUE,
    SWORD,
    WAND,
    SHIELD,
    FIRE_SWORD,
    ICE_SWORD,
    AXE,
    MACHETE,
    HAMMER,
    DOUBLE_AXE
}

enum ToadHeadGear {
    NONE,
    GUPPI_CAP,
    NIKE_CAP,
    ASH_CAP,
    PINK_CAP,
    MUSHROOM_CAP,
    ASTRO_HELMET,
    STRAW_HAT,
    SAILOR_HAT,
    PIRATE_HAT,
    WIZARD_PURPLE,
    WIZARD_BROWN,
    KIDS_CAP,
    TOP_HAT,
    PARTY_HAT,
    CROWN,
    BRAIN,
    MOHAWK_PURPLE,
    MOHAWK_GREEN,
    MOHAWK_PINK,
    AFRO,
    BASEBALL_CAP_WHITE,
    BASEBALL_CAP_RED,
    BASEBALL_CAP_BLUE,
    BANDANA_PURPLE,
    BANDANA_RED,
    BANDANA_BLUE,
    BEANIE_GREY,
    BEANIE_BLUE,
    BEANIE_YELLOW,
    HALO
}

enum ToadExtra {
    NONE,
    FLIES,
    GOLD_CHAIN,
    NECKTIE_RED,
    NECKTIE_PINK,
    NECKTIE_PURPLE
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../libraries/ToadTraitConstants.sol";

interface IToadz is IERC721Upgradeable {

    function mint(address _to, ToadTraits calldata _traits) external;

    function adminSafeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

// Immutable Traits.
// Do not change.
struct ToadTraits {
    ToadRarity rarity;
    ToadBackground background;
    ToadStool stool;
    ToadBody body;
    ToadClothes clothes;
    ToadMouth mouth;
    ToadEyes eyes;
    ToadItem item;
    ToadHeadGear headGear;
    ToadExtra extra;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./ToadzMetadata.sol";

contract Toadz is Initializable, ToadzMetadata {
    function initialize() external initializer {
        ToadzMetadata.__ToadzMetadata_init();
    }

    function adminSafeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external onlyAdminOrOwner {
        _safeTransfer(_from, _to, _tokenId, "");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ToadzState.sol";

abstract contract ToadzContracts is Initializable, ToadzState {

    function __ToadzContracts_init() internal initializer {
        ToadzState.__ToadzState_init();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "../libraries/BBase64.sol";
import "./ToadzMintable.sol";

abstract contract ToadzMetadata is Initializable, ToadzMintable {

    using StringsUpgradeable for uint256;

    function __ToadzMetadata_init() internal initializer {
        ToadzMintable.__ToadzMintable_init();
    }

    function tokenURI(uint256 _tokenId) public view override returns(string memory) {
        require(_exists(_tokenId), "Toadz: Token does not exist");

        ToadTraits memory _traits = tokenIdToTraits[_tokenId];

        bytes memory _beginningJSON = _getBeginningJSON(_tokenId);
        string memory _svg = _getSVG(_traits);
        string memory _attributes = _getAttributes(_traits);

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                BBase64.encode(
                    bytes(
                        abi.encodePacked(
                            _beginningJSON,
                            BBase64.encode(bytes(_svg)),
                            '",',
                            _attributes,
                            '}'
                        )
                    )
                )
            )
        );
    }

    function _getBeginningJSON(uint256 _tokenId) private pure returns(bytes memory) {
        return abi.encodePacked(
            '{"name":"Toad #',
            _tokenId.toString(),
            '", "description":"Some description", "image": "',
            'data:image/svg+xml;base64,');
    }

    function _getAttributes(ToadTraits memory _traits) private view returns(string memory) {
        return string(abi.encodePacked(
            '"attributes": [',
                _getTopAttributes(_traits),
                _getBottomAttributes(_traits),
            ']'
        ));
    }

    function _getTopAttributes(ToadTraits memory _traits) private view returns(string memory) {
        return string(abi.encodePacked(
            _getRarityJSON(_traits.rarity), ',',
            _getBackgroundJSON(_traits.background), ',',
            _getStoolJSON(_traits.stool), ',',
            _getBodyJSON(_traits.body), ',',
            _getClothesJSON(_traits.clothes), ','
        ));
    }

    function _getBottomAttributes(ToadTraits memory _traits) private view returns(string memory) {
        return string(abi.encodePacked(
            _getMouthJSON(_traits.mouth), ',',
            _getEyesJSON(_traits.eyes), ',',
            _getItemJSON(_traits.item), ',',
            _getHeadGearJSON(_traits.headGear), ',',
            _getExtraJSON(_traits.extra)
        ));
    }

    function _getRarityJSON(ToadRarity _rarity) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.RARITY,
            '","value":"',
            rarityToString[_rarity],
            '"}'
        ));
    }

    function _getBackgroundJSON(ToadBackground _background) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.BACKGROUND,
            '","value":"',
            backgroundToString[_background],
            '"}'
        ));
    }

    function _getStoolJSON(ToadStool _stool) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.STOOL,
            '","value":"',
            stoolToString[_stool],
            '"}'
        ));
    }

    function _getBodyJSON(ToadBody _body) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.BODY,
            '","value":"',
            bodyToString[_body],
            '"}'
        ));
    }

    function _getClothesJSON(ToadClothes _clothes) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.CLOTHES,
            '","value":"',
            clothesToString[_clothes],
            '"}'
        ));
    }

    function _getMouthJSON(ToadMouth _mouth) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.MOUTH,
            '","value":"',
            mouthToString[_mouth],
            '"}'
        ));
    }

    function _getEyesJSON(ToadEyes _eyes) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.EYES,
            '","value":"',
            eyesToString[_eyes],
            '"}'
        ));
    }

    function _getItemJSON(ToadItem _item) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.ITEM,
            '","value":"',
            itemToString[_item],
            '"}'
        ));
    }

    function _getHeadGearJSON(ToadHeadGear _headGear) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.HEAD_GEAR,
            '","value":"',
            headGearToString[_headGear],
            '"}'
        ));
    }

    function _getExtraJSON(ToadExtra _extra) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.EXTRA,
            '","value":"',
            extraToString[_extra],
            '"}'
        ));
    }

    function _getSVG(ToadTraits memory _traits) private view returns(string memory) {
        return string(abi.encodePacked(
            ToadTraitConstants.SVG_HEADER,
            _getTopSVGParts(_traits),
            _getBottomSVGParts(_traits),
            ToadTraitConstants.SVG_FOOTER
        ));
    }

    function _getTopSVGParts(ToadTraits memory _traits) private view returns(string memory) {
        return string(abi.encodePacked(
            _getBackgroundSVGPart(_traits.background),
            _getStoolSVGPart(_traits.stool),
            _getBodySVGPart(_traits.body),
            _getClothesSVGPart(_traits.clothes),
            _getMouthSVGPart(_traits.mouth)
        ));
    }

    function _getBottomSVGParts(ToadTraits memory _traits) private view returns(string memory) {
        return string(abi.encodePacked(
            _getEyesSVGPart(_traits.eyes),
            _getItemSVGPart(_traits.item),
            _getHeadGearSVGPart(_traits.headGear),
            _getExtraSVGPart(_traits.extra)
        ));
    }

    function _getBackgroundSVGPart(ToadBackground _background) private view returns(string memory) {
        return wrapPNG(backgroundToPNG[_background]);
    }

    function _getStoolSVGPart(ToadStool _stool) private view returns(string memory) {
        return wrapPNG(stoolToPNG[_stool]);
    }

    function _getBodySVGPart(ToadBody _body) private view returns(string memory) {
        return wrapPNG(bodyToPNG[_body]);
    }

    function _getClothesSVGPart(ToadClothes _clothes) private view returns(string memory) {
        return wrapPNG(clothesToPNG[_clothes]);
    }

    function _getMouthSVGPart(ToadMouth _mouth) private view returns(string memory) {
        return wrapPNG(mouthToPNG[_mouth]);
    }

    function _getEyesSVGPart(ToadEyes _eyes) private view returns(string memory) {
        return wrapPNG(eyesToPNG[_eyes]);
    }

    function _getItemSVGPart(ToadItem _item) private view returns(string memory) {
        if(_item == ToadItem.NONE) {
            return "";
        }
        return wrapPNG(itemToPNG[_item]);
    }

    function _getHeadGearSVGPart(ToadHeadGear _headGear) private view returns(string memory) {
        if(_headGear == ToadHeadGear.NONE) {
            return "";
        }
        return wrapPNG(headGearToPNG[_headGear]);
    }

    function _getExtraSVGPart(ToadExtra _extra) private view returns(string memory) {
        if(_extra == ToadExtra.NONE) {
            return "";
        }
        return wrapPNG(extraToPNG[_extra]);
    }

    function wrapPNG(string memory _png) internal pure returns(string memory) {
        return string(abi.encodePacked(
            '<image x="0" y="0" width="60" height="60" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            _png,
            '"/>'
        ));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ToadzContracts.sol";

abstract contract ToadzMintable is Initializable, ToadzContracts {

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    function __ToadzMintable_init() internal initializer {
        ToadzContracts.__ToadzContracts_init();
    }

    function mint(address _to, ToadTraits calldata _traits) external whenNotPaused onlyMinter {
        uint256 _tokenId = tokenIdCounter.current();

        _safeMint(_to, _tokenId);
        tokenIdCounter.increment();

        tokenIdToTraits[_tokenId] = _traits;
    }

    function addMinter(address _minter) external onlyAdminOrOwner {
        minters.add(_minter);
    }

    function removeMinter(address _minter) external onlyAdminOrOwner {
        minters.remove(_minter);
    }

    function isMinter(address _minter) external view returns(bool) {
        return minters.contains(_minter);
    }

    modifier onlyMinter() {
        require(minters.contains(msg.sender), "Not a minter");

        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./IToadz.sol";
import "../../shared/AdminableUpgradeable.sol";

abstract contract ToadzState is Initializable, IToadz, ERC721Upgradeable, AdminableUpgradeable {

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    CountersUpgradeable.Counter internal tokenIdCounter;

    EnumerableSetUpgradeable.AddressSet internal minters;

    mapping(uint256 => ToadTraits) public tokenIdToTraits;

    mapping(ToadRarity => string) public rarityToString;
    mapping(ToadBackground => string) public backgroundToString;
    mapping(ToadStool => string) public stoolToString;
    mapping(ToadBody => string) public bodyToString;
    mapping(ToadClothes => string) public clothesToString;
    mapping(ToadMouth => string) public mouthToString;
    mapping(ToadEyes => string) public eyesToString;
    mapping(ToadItem => string) public itemToString;
    mapping(ToadHeadGear => string) public headGearToString;
    mapping(ToadExtra => string) public extraToString;

    mapping(ToadBackground => string) public backgroundToPNG;
    mapping(ToadStool => string) public stoolToPNG;
    mapping(ToadBody => string) public bodyToPNG;
    mapping(ToadClothes => string) public clothesToPNG;
    mapping(ToadMouth => string) public mouthToPNG;
    mapping(ToadEyes => string) public eyesToPNG;
    mapping(ToadItem => string) public itemToPNG;
    mapping(ToadHeadGear => string) public headGearToPNG;
    mapping(ToadExtra => string) public extraToPNG;

    function __ToadzState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
        ERC721Upgradeable.__ERC721_init("Toadz", "TDZ");

        tokenIdCounter.increment();

        rarityToString[ToadRarity.COMMON] = ToadTraitConstants.RARITY_COMMON;

        backgroundToString[ToadBackground.GREY] = ToadTraitConstants.BACKGROUND_GREY;
        backgroundToPNG[ToadBackground.GREY] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAFSDNYfAAAAXElEQVRo3u3PsQ0AIAhFQdl/E1fUggWwoDEU91tCXi7OvqtaOIw6vObBgwcP0x66ExAQEBAQEBAQEBAQEBAQEBAQ+DkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgPYSt188AKLLbSMAAAAASUVORK5CYII=";

        stoolToString[ToadStool.RED_SPOTS] = ToadTraitConstants.STOOL_RED_SPOTS;
        stoolToPNG[ToadStool.RED_SPOTS] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAAHdbkFIAAACjUlEQVR42u2aS24CMQyG5whlU7Fky3UQR0EcouIAnIF2yz2ouuA4Lh7GU8dk8gTKwD+S1QIh/PnycBynIaImZM2oCnzPZkTzOcnfyds79QVOL8ToczptP+TX42tmsEDb5o5By2G5JFug6dreFsjiUK3xVSsQ2k63qK7xVvAxmbRDVcbzoHFF6zUlNWG/35N60I2o4OUqcGZiN4HEWQQr4Nkos85XiW9K9/9sTtPZ+cKQrVaOGr2IOG5ML+NqKScpE4W43W7peDyeF4KmuV0v/PswgAAIgAAIuLsAvU5bu4kAcQg/KhjymbN57DaQOhbI3t7KTrWvnJ+Qm7Ofn33nxW42KkBw8nZZtsxiLOZwOKT5XSNmiEZO3/fG3pW33mLsdtn4fePXm6IuiJn4evH3nc8P+n2sAxAAARAAARAAARAAARDwHAJCYVnKFrxYgE0EeMOyzJAsSYD+YQm/kkREwrEkAToU02FWlITEg4k0vG/qc9esGNAGp52FRFwg5x/f7Xb0ZaPjElsszkROB8RDXeILQIPRcUlknHxe7jm19p5g+06zPafazvRM6oLU8JyjYxuad+F5VmhetBLK2YAOze8angcEjNMXvLwzBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIDxAxg6NE+99Td0LbEk/3UXALkNjoKwqS5Jd/1lm+haMKoanJKvqQbhg6FSb7UjI7vhVYmqWhsAUQMjubc3gUxdEYTYZdxcEG5C9nopaklTslkInEfNGso1ZoFx7pUtMj1qASSnSUN5XWtBUJkjIzcde40b9EXGuUtO62qLwbQNSrWH2whJ4305bXsL3Kabb+H7HwaA75GGy/MUW2ENINTrNRcNSu0XWU33OvnnHsMAAAAASUVORK5CYII=";

        bodyToString[ToadBody.OG_GREEN] = ToadTraitConstants.BODY_OG_GREEN;
        bodyToPNG[ToadBody.OG_GREEN] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAAHdbkFIAAACAklEQVR42u2aTU7EMAyFcyCuwIItEntOgjgDQhyC+3AmQ9A4cl3nr21SXF6lrCbjef7qOHYmgYhCaYRjJzx/BuJhTrh/qUyIH3x83eUnTPBi34SfZ+WinpA4ZCcwh8lenGOAHY7j8c3GVzNAMva2GEjvJGLXIdhkgN1gNb+y/LwFGDjAgExwPLriQMa/MNAeiU/v+9cCaTe6XJDLmRdSr4HVSuxicHvSF28DoTzKAAT8HwH8xBwhs5XehNMqHCHAyrPWGCWAcmm2NfXuFmBtFDMFLOIgg35sDOiA4+1CbhulrWPIKjB+fCiBZJ+FSFFDXwEyIQRAAARAAAT8laJ00bhy5zerIGkqyUqt6G4BjRXxGAG6Eppelj+8tlfEQ2rC0wXEV9DamAyriqMIHmesAjMXWI3pKY3JFALac90Z1U6oDxOgT/KmCeB0bAmY1ZyuSMg9YkYQLpajFMB9InpDCIAACHAnAAAAAAAAAAAAAACuA8B4qDBq89bGHAGg2oEad3KlORqEFwDU+gd/z5EnADgBQPEkteUgU17yOvrQ0wWALZEAAJ5yQC3Db8kD3uqA1d7e4axZD7gshEo7Qu7uk74B67YQanXcAmH9CewWQO3W22UB5CDUnDdygd8cwKOnOrxCM5S97mg4WfrsMgBCZzscXALAiRAAAAAAAAAAAICb8Q02aVGWxCXkTAAAAABJRU5ErkJggg==";

        clothesToString[ToadClothes.TURTLENECK_BLUE] = ToadTraitConstants.CLOTHES_TURTLENECK_BLUE;
        clothesToPNG[ToadClothes.TURTLENECK_BLUE] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAAHdbkFIAAABhElEQVR42u2aTY6CQBBGv9rIFWQSBRtPoomHNtHMYuYWihgXeouaxYhBxxH/MGperfhL8frRjSlKc3edCnu2C8xMWZL6fFnsjtvLjeL2C7rxh7eiSLNiYQ9kqIt3TlAqH08nkqTRYLinH4kkIMGZCfppz+sW0skE5Q9BuX9xAp7CAxPcGgAAAMBrAnTjD19t1kfPubs1CmBm3mnHkqRWFP05P18WF0Fc/QjMzO+Rk0kIAAAAAAAAAAAAAAAAV9cFh4VJlqSq9hYaATAzz5J079h4OtFoMHxMYWJm6rRjX23WypJUs2KhPM8VQlA/7Wm+LJovTMxMkrzTjvX5/aUQgvI812gwfAxATVnWfHHKMgQAAAAAeLdAAAIQgAAEIAABCEAAAhCAAAQgAAEIuP8Ntv2MY/9xqovtx/ZGORsVUDf48XSiEMJuv+wyVAVsGz8Xf/R/FgHl5u4mh0JKCYeDr8yA337MK86A/2ZENU4tjWv6TbwEEYAABCAAAQhAAAIQgICz4gepePYgY6K6uAAAAABJRU5ErkJggg==";

        mouthToString[ToadMouth.SMILE] = ToadTraitConstants.MOUTH_SMILE;
        mouthToPNG[ToadMouth.SMILE] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAAHdbkFIAAAA0ElEQVR42u3awQ2CQBBA0ZkOWA5Qg/0XQw1yEDtYTxgPqBGDSnxzRFh/HtlEiFlrjUeTTnDCC/PjC2Tm9cNaa/6jgQUscLsP7AULbL7AuyNAgIBVAW3pIyJiOo+H+VhpuiEi4jQd3QIBAgQIECBAgAABArYNaEsf03lcvKg0XX7kZ/nCc8FQmi48FwgQIECAAAECdhnw7QEAAAAAAAAAAAAAAACA7b4ks656dZxZ7/37b1cA8+vsNfMqmi0AAAAAAAAAAAAAAAAAAAAAAADwZC74fY8g0F5FfQAAAABJRU5ErkJggg==";

        eyesToString[ToadEyes.LASERS] = ToadTraitConstants.EYES_LASERS;
        eyesToPNG[ToadEyes.LASERS] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAAHdbkFIAAAA90lEQVR42u2aQQ6CMBBF/9yAsoD7H68uWm8wLmCMmIgRUwXyZkMaJsProyXNBHN3rYWR0CKhT6NLUqnZDjWLd9G2QJ9GLzVbXA84BQpQYN79VmrWpqUcBeYhe4ECOy/wbQAAwFYANzOlblAcHer1Mt1wN14BAAAAAAAAAAAAAADNAZ7bfzGOpkBTgMcTcOqGeODilNwaQJIWM/6pARYhAAAAAAAAAAAAwOkA/h0IQAACEIAABCAAAQhoGfNPVDKbOpfuHl3GezfxVc6n7c5DCJCk1A2rAiLnFAL4BiAAAQhAAAIQgAAEIAABCEAAAhCAAAQgAAG7iRvM7cggWf2f5AAAAABJRU5ErkJggg==";

        itemToString[ToadItem.NONE] = ToadTraitConstants.ITEM_NONE;

        headGearToString[ToadHeadGear.NONE] = ToadTraitConstants.HEAD_GEAR_NONE;

        extraToString[ToadExtra.NONE] = ToadTraitConstants.EXTRA_NONE;
    }
}