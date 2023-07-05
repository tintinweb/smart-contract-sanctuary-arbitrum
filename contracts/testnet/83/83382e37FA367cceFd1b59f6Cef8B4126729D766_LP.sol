// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC721/ERC721.sol)

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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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

        _beforeTokenTransfer(address(0), to, tokenId);

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

        _afterTokenTransfer(address(0), to, tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

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

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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
     * @dev Hook that is called before any (single) token transfer. This includes minting and burning.
     * See {_beforeConsecutiveTokenTransfer}.
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

    /**
     * @dev Hook that is called after any (single) transfer of tokens. This includes minting and burning.
     * See {_afterConsecutiveTokenTransfer}.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called before consecutive token transfers.
     * Calling conditions are similar to {_beforeTokenTransfer}.
     *
     * The default implementation include balances updates that extensions such as {ERC721Consecutive} cannot perform
     * directly.
     */
    function _beforeConsecutiveTokenTransfer(
        address from,
        address to,
        uint256, /*first*/
        uint96 size
    ) internal virtual {
        if (from != address(0)) {
            _balances[from] -= size;
        }
        if (to != address(0)) {
            _balances[to] += size;
        }
    }

    /**
     * @dev Hook that is called after consecutive token transfers.
     * Calling conditions are similar to {_afterTokenTransfer}.
     */
    function _afterConsecutiveTokenTransfer(
        address, /*from*/
        address, /*to*/
        uint256, /*first*/
        uint96 /*size*/
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` and 'to' cannot be the zero address at the same time.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

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
     * @dev Hook that is called before any batch token transfer. For now this is limited
     * to batch minting by the {ERC721Consecutive} extension.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeConsecutiveTokenTransfer(
        address,
        address,
        uint256,
        uint96 size
    ) internal virtual override {
        // We revert because enumerability is not supported with consecutive batch minting.
        // This conditional is only needed to silence spurious warnings about unreachable code.
        if (size > 0) {
            revert("ERC721Enumerable: consecutive transfers not supported");
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

pragma solidity ^0.8.1;

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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./IOwnable.sol";

interface IAccess is IOwnable {
    struct RoleData {
        address target; // target contract address
        bytes4 selector; // target function selector
        uint8 roleId; // ID of the role associated with contract-function combination
    }

    event RoleAdded(bytes32 indexed role, uint256 indexed roleId);
    event RoleRenamed(bytes32 indexed role, uint8 indexed roleId);
    event RoleBound(bytes32 indexed funcId, uint8 indexed roleId);
    event RoleUnbound(bytes32 indexed funcId, uint8 indexed roleId);
    event RoleGranted(address indexed user, uint8 indexed roleId);
    event RoleRevoked(address indexed user, uint8 indexed roleId);

    error NotTokenOwner();
    error MaxRolesReached();
    error AccessNotGranted();
    error RoleAlreadyGranted();

    function initialize() external;

    function checkAccess(
        address sender,
        address _contract,
        bytes4 selector
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./IOwnable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IAzuroBet is IOwnable, IERC721EnumerableUpgradeable {
    function initialize(address core) external;

    function burn(uint256 id) external;

    function mint(address account) external returns (uint256);

    error OnlyCore();
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IBet {
    struct BetData {
        address affiliate; // address indicated as an affiliate when placing bet
        uint64 minOdds;
        bytes data; // core-specific customized bet data
    }

    error BetNotExists();
    error SmallOdds();

    /**
     * @notice Register new bet.
     * @param  bettor wallet for emitting bet token
     * @param  amount amount of tokens to bet
     * @param  betData customized bet data
     */
    function putBet(
        address bettor,
        uint128 amount,
        BetData calldata betData
    ) external returns (uint256 tokenId);

    function resolvePayout(address caller, uint256 tokenId)
        external
        returns (address account, uint128 payout);

    function viewPayout(uint256 tokenId) external view returns (uint128 payout);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface ICondition {
    enum ConditionState {
        CREATED,
        RESOLVED,
        CANCELED,
        PAUSED
    }

    struct Condition {
        uint256 gameId;
        uint128[] payouts;
        uint128[] virtualFunds;
        uint128 totalNetBets;
        uint128 reinforcement;
        uint128 fund;
        uint64 margin;
        uint64 endsAt;
        uint48 lastDepositId;
        uint8 winningOutcomesCount;
        ConditionState state;
        address oracle;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./IBet.sol";
import "./ICondition.sol";
import "./ILP.sol";
import "./IOwnable.sol";
import "./IAzuroBet.sol";

interface ICoreBase is ICondition, IOwnable, IBet {
    struct Bet {
        uint256 conditionId;
        uint128 amount;
        uint128 payout;
        uint64 outcome;
        bool isPaid;
    }

    struct CoreBetData {
        uint256 conditionId; // The match or game ID
        uint64 outcomeId; // ID of predicted outcome
    }

    event ConditionCreated(
        uint256 indexed gameId,
        uint256 indexed conditionId,
        uint64[] outcomes
    );
    event ConditionResolved(
        uint256 indexed conditionId,
        uint8 state,
        uint64[] winningOutcomes,
        int128 lpProfit
    );
    event ConditionStopped(uint256 indexed conditionId, bool flag);

    event ReinforcementChanged(
        uint256 indexed conditionId,
        uint128 newReinforcement
    );
    event MarginChanged(uint256 indexed conditionId, uint64 newMargin);
    event OddsChanged(uint256 indexed conditionId, uint256[] newOdds);

    error OnlyLp();

    error AlreadyPaid();
    error DuplicateOutcomes(uint64 outcome);
    error IncorrectConditionId();
    error IncorrectMargin();
    error IncorrectReinforcement();
    error NothingChanged();
    error IncorrectTimestamp();
    error IncorrectWinningOutcomesCount();
    error IncorrectOutcomesCount();
    error NoPendingReward();
    error OnlyBetOwner();
    error OnlyOracle(address);
    error OutcomesAndOddsCountDiffer();
    error StartOutOfRange(uint256 pendingRewardsCount);
    error WrongOutcome();
    error ZeroOdds();

    error CantChangeFlag();
    error ConditionAlreadyCreated();
    error ConditionAlreadyResolved();
    error ConditionNotExists();
    error ConditionNotRunning();
    error GameAlreadyStarted();
    error InsufficientFund();
    error InsufficientVirtualFund();
    error ResolveTooEarly(uint64 waitTime);

    function lp() external view returns (ILP);

    function azuroBet() external view returns (IAzuroBet);

    function initialize(address azuroBet, address lp) external;

    function calcOdds(
        uint256 conditionId,
        uint128 amount,
        uint64 outcome
    ) external view returns (uint64 odds);

    /**
     * @notice Change the current condition `conditionId` margin.
     */
    function changeMargin(uint256 conditionId, uint64 newMargin) external;

    /**
     * @notice Change the current condition `conditionId` odds.
     */
    function changeOdds(uint256 conditionId, uint256[] calldata newOdds)
        external;

    /**
     * @notice Change the current condition `conditionId` reinforcement.
     */
    function changeReinforcement(uint256 conditionId, uint128 newReinforcement)
        external;

    function getCondition(uint256 conditionId)
        external
        view
        returns (Condition memory);

    /**
     * @notice Indicate the condition `conditionId` as canceled.
     * @notice The condition creator can always cancel it regardless of granted access tokens.
     */
    function cancelCondition(uint256 conditionId) external;

    /**
     * @notice Indicate the status of condition `conditionId` bet lock.
     * @param  conditionId the match or condition ID
     * @param  flag if stop receiving bets for the condition or not
     */
    function stopCondition(uint256 conditionId, bool flag) external;

    /**
     * @notice Register new condition.
     * @param  gameId the game ID the condition belongs
     * @param  conditionId the match or condition ID according to oracle's internal numbering
     * @param  odds start odds for [team 1, ..., team N]
     * @param  outcomes unique outcomes for the condition [outcome 1, ..., outcome N]
     * @param  reinforcement maximum amount of liquidity intended to condition reinforcement
     * @param  margin bookmaker commission
     * @param  winningOutcomesCount the number of winning outcomes of the Condition
     */
    function createCondition(
        uint256 gameId,
        uint256 conditionId,
        uint256[] calldata odds,
        uint64[] calldata outcomes,
        uint128 reinforcement,
        uint64 margin,
        uint8 winningOutcomesCount
    ) external;

    function getOutcomeIndex(uint256 conditionId, uint64 outcome)
        external
        view
        returns (uint256);

    function isOutcomeWinning(uint256 conditionId, uint64 outcome)
        external
        view
        returns (bool);

    function isConditionCanceled(uint256 conditionId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface ILiquidityManager {
    /**
     * @notice The hook that is called after the withdrawal of liquidity.
     * @param  account The address of the liquidity provider.
     * @param  depositId The ID of the liquidity deposit.
     * @param  balance The remaining balance of the liquidity deposit.
     */
    function afterWithdrawLiquidity(
        address account,
        uint48 depositId,
        uint128 balance
    ) external;

    /**
     * @notice The hook that is called before adding liquidity.
     * @param  account The address of the liquidity provider.
     * @param  depositId The ID of the liquidity deposit.
     * @param  balance The amount of the liquidity deposit.
     */
    function beforeAddLiquidity(
        address account,
        uint48 depositId,
        uint128 balance
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./IBet.sol";
import "./IOwnable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface ILP is IOwnable, IERC721EnumerableUpgradeable {
    enum FeeType {
        DAO,
        DATA_PROVIDER
    }

    enum CoreState {
        UNKNOWN,
        ACTIVE,
        INACTIVE
    }

    struct Condition {
        address core;
        uint256 conditionId;
    }

    struct CoreData {
        CoreState state;
        uint64 reinforcementAbility;
        uint128 minBet;
        uint128 lockedLiquidity;
    }

    struct Game {
        uint128 lockedLiquidity;
        uint64 startsAt;
        bool canceled;
    }

    struct Reward {
        int128 amount;
        uint64 claimedAt;
    }

    event CoreSettingsUpdated(
        address indexed core,
        CoreState state,
        uint64 reinforcementAbility,
        uint128 minBet
    );

    event BettorWin(
        address indexed core,
        address indexed bettor,
        uint256 tokenId,
        uint256 amount
    );
    event ClaimTimeoutChanged(uint64 newClaimTimeout);
    event DataProviderChanged(address newDataProvider);
    event FeeChanged(FeeType feeType, uint64 fee);
    event GameCanceled(uint256 indexed gameId);
    event GameShifted(uint256 indexed gameId, uint64 newStart);
    event LiquidityAdded(
        address indexed account,
        uint48 indexed depositId,
        uint256 amount
    );
    event LiquidityDonated(
        address indexed account,
        uint48 indexed depositId,
        uint256 amount
    );
    event LiquidityManagerChanged(address newLiquidityManager);
    event LiquidityRemoved(
        address indexed account,
        uint48 indexed depositId,
        uint256 amount
    );
    event MinBetChanged(address core, uint128 newMinBet);
    event MinDepoChanged(uint128 newMinDepo);
    event NewGame(uint256 indexed gameId, uint64 startsAt, bytes[] data);
    event ReinforcementAbilityChanged(uint128 newReinforcementAbility);
    event WithdrawTimeoutChanged(uint64 newWithdrawTimeout);

    error OnlyFactory();

    error SmallDepo();
    error SmallDonation();

    error BetExpired();
    error CoreNotActive();
    error ClaimTimeout(uint64 waitTime);
    error DepositDoesNotExist();
    error GameAlreadyCanceled();
    error GameAlreadyCreated();
    error GameCanceled_();
    error GameNotExists();
    error IncorrectCoreState();
    error IncorrectFee();
    error IncorrectGameId();
    error IncorrectMinBet();
    error IncorrectMinDepo();
    error IncorrectReinforcementAbility();
    error IncorrectTimestamp();
    error LiquidityNotOwned();
    error LiquidityIsLocked();
    error NoLiquidity();
    error NotEnoughLiquidity();
    error SmallBet();
    error UnknownCore();
    error WithdrawalTimeout(uint64 waitTime);

    function initialize(
        address access,
        address dataProvider,
        address token,
        uint128 minDepo,
        uint64 daoFee,
        uint64 dataProviderFee
    ) external;

    function addCore(address core) external;

    function addLiquidity(uint128 amount) external returns (uint48);

    function withdrawLiquidity(uint48 depositId, uint40 percent)
        external
        returns (uint128);

    function viewPayout(address core, uint256 tokenId)
        external
        view
        returns (uint128 payout);

    function betFor(
        address bettor,
        address core,
        uint128 amount,
        uint64 expiresAt,
        IBet.BetData calldata betData
    ) external returns (uint256 tokenId);

    /**
     * @notice Make new bet.
     * @notice Emits bet token to `msg.sender`.
     * @param  core address of the Core the bet is intended
     * @param  amount amount of tokens to bet
     * @param  expiresAt the time before which bet should be made
     * @param  betData customized bet data
     */
    function bet(
        address core,
        uint128 amount,
        uint64 expiresAt,
        IBet.BetData calldata betData
    ) external returns (uint256 tokenId);

    function changeDataProvider(address newDataProvider) external;

    function claimReward() external returns (uint128);

    function getReserve() external view returns (uint128);

    function addReserve(
        uint256 gameId,
        uint128 lockedReserve,
        uint128 profitReserve,
        uint48 depositId
    ) external;

    function addCondition(uint256 gameId) external view returns (uint64);

    function withdrawPayout(address core, uint256 tokenId)
        external
        returns (uint128);

    function changeLockedLiquidity(uint256 gameId, int128 deltaReserve)
        external;

    /**
     * @notice Indicate the game `gameId` as canceled.
     * @param  gameId the game ID
     */
    function cancelGame(uint256 gameId) external;

    /**
     * @notice Create new game.
     * @param  gameId the match or condition ID according to oracle's internal numbering
     * @param  startsAt timestamp when the game starts
     * @param  data the additional data to emit in the `NewGame` event
     */
    function createGame(
        uint256 gameId,
        uint64 startsAt,
        bytes[] calldata data
    ) external;

    /**
     * @notice Set `startsAt` as new game `gameId` start time.
     * @param  gameId the game ID
     * @param  startsAt new timestamp when the game starts
     */
    function shiftGame(uint256 gameId, uint64 startsAt) external;

    function getGameInfo(uint256 gameId)
        external
        view
        returns (uint64 startsAt, bool canceled);

    function getLockedLiquidityLimit(address core)
        external
        view
        returns (uint128);

    function isGameCanceled(uint256 gameId)
        external
        view
        returns (bool canceled);

    function checkAccess(
        address account,
        address target,
        bytes4 selector
    ) external;

    function checkCore(address core) external view;

    function getLastDepositId() external view returns (uint48 depositId);

    function isDepositExists(uint256 depositId) external view returns (bool);

    function token() external view returns (address);

    function fees(uint256) external view returns (uint64);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IOwnable {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() external view returns (address);

    function checkOwner(address account) external view;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @title Fixed-point math tools
library FixedMath {
    uint256 constant ONE = 1e12;

    /**
     * @notice Get the ratio of `self` and `other` that is larger than 'ONE'.
     */
    function ratio(uint256 self, uint256 other)
        internal
        pure
        returns (uint256)
    {
        return self > other ? div(self, other) : div(other, self);
    }

    function mul(uint256 self, uint256 other) internal pure returns (uint256) {
        return (self * other) / ONE;
    }

    function div(uint256 self, uint256 other) internal pure returns (uint256) {
        return (self * ONE) / other;
    }

    /**
     * @notice Implementation of the sigmoid function.
     * @notice The sigmoid function is commonly used in machine learning to limit output values within a range of 0 to 1.
     */
    function sigmoid(uint256 self) internal pure returns (uint256) {
        return (self * ONE) / (self + ONE);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library SafeCast {
    enum Type {
        BYTES32,
        INT128,
        UINT64,
        UINT128
    }
    error SafeCastError(Type to);

    function toBytes32(string calldata value) internal pure returns (bytes32) {
        bytes memory value_ = bytes(value);
        if (value_.length > 32) revert SafeCastError(Type.BYTES32);
        return bytes32(value_);
    }

    function toInt128(uint128 value) internal pure returns (int128) {
        if (value > uint128(type(int128).max))
            revert SafeCastError(Type.INT128);
        return int128(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) revert SafeCastError(Type.UINT64);
        return uint64(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) revert SafeCastError(Type.UINT128);
        return uint128(value);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./interface/IAccess.sol";
import "./interface/ICoreBase.sol";
import "./interface/ILP.sol";
import "./interface/IOwnable.sol";
import "./interface/IBet.sol";
import "./interface/ILiquidityManager.sol";
import "./libraries/FixedMath.sol";
import "./libraries/SafeCast.sol";
import "./utils/LiquidityTree.sol";
import "./utils/OwnableUpgradeable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

/// @title Azuro Liquidity Pool managing
contract LP is
    LiquidityTree,
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ILP
{
    using FixedMath for uint64;
    using SafeCast for uint256;
    using SafeCast for uint128;

    IOwnable public factory;
    IAccess public access;

    address public token;
    address public dataProvider;

    uint128 public minDepo; // Minimum amount of liquidity deposit
    uint128 public lockedLiquidity; // Liquidity reserved by conditions

    uint64 public claimTimeout; // Withdraw reward timeout
    uint64 public withdrawTimeout; // Deposit-withdraw liquidity timeout

    mapping(address => CoreData) public cores;

    mapping(uint256 => Game) public games;

    uint64[3] public fees; // fees[2] is not used

    mapping(address => Reward) public rewards;
    // withdrawAfter[depositId] = timestamp indicating when the liquidity deposit withdrawal will be available.
    mapping(uint48 => uint64) public withdrawAfter;

    ILiquidityManager public liquidityManager;

    /**
     * @notice Check if Core `core` belongs to this Liquidity Pool and is active.
     */
    modifier isActive(address core) {
        _checkCoreActive(core);
        _;
    }

    /**
     * @notice Check if Core `core` belongs to this Liquidity Pool.
     */
    modifier isCore(address core) {
        checkCore(core);
        _;
    }

    /**
     * @notice Throw if caller is not the Pool Factory.
     */
    modifier onlyFactory() {
        if (msg.sender != address(factory)) revert OnlyFactory();
        _;
    }

    /**
     * @notice Throw if caller have no access to function with selector `selector`.
     */
    modifier restricted(bytes4 selector) {
        checkAccess(msg.sender, address(this), selector);
        _;
    }

    receive() external payable {
        require(msg.sender == token);
    }

    function initialize(
        address access_,
        address dataProvider_,
        address token_,
        uint128 minDepo_,
        uint64 daoFee,
        uint64 dataProviderFee
    ) external virtual override initializer {
        if (minDepo_ == 0) revert IncorrectMinDepo();

        __Ownable_init();
        __ERC721_init("Azuro LP NFT token", "LP-AZR");
        __liquidityTree_init();
        factory = IOwnable(msg.sender);
        access = IAccess(access_);
        dataProvider = dataProvider_;
        token = token_;
        fees[0] = daoFee;
        fees[1] = dataProviderFee;
        _checkFee();
        minDepo = minDepo_;
    }

    /**
     * @notice Owner: Set `newClaimTimeout` as claim timeout.
     */
    function changeClaimTimeout(uint64 newClaimTimeout) external onlyOwner {
        claimTimeout = newClaimTimeout;
        emit ClaimTimeoutChanged(newClaimTimeout);
    }

    /**
     * @notice Owner: Set `newDataProvider` as Data Provider.
     */
    function changeDataProvider(address newDataProvider) external onlyOwner {
        dataProvider = newDataProvider;
        emit DataProviderChanged(newDataProvider);
    }

    /**
     * @notice Owner: Set `newFee` as type `feeType` fee.
     * @param  newFee fee share where `FixedMath.ONE` is 100% of the Liquidity Pool profit
     */
    function changeFee(FeeType feeType, uint64 newFee) external onlyOwner {
        fees[uint256(feeType)] = newFee;
        _checkFee();
        emit FeeChanged(feeType, newFee);
    }

    /**
     * @notice Owner: Set `newLiquidityManager` as liquidity manager contract address.
     */
    function changeLiquidityManager(address newLiquidityManager)
        external
        onlyOwner
    {
        liquidityManager = ILiquidityManager(newLiquidityManager);
        emit LiquidityManagerChanged(newLiquidityManager);
    }

    /**
     * @notice Owner: Set `newMinDepo` as minimum liquidity deposit.
     */
    function changeMinDepo(uint128 newMinDepo) external onlyOwner {
        if (newMinDepo == 0) revert IncorrectMinDepo();
        minDepo = newMinDepo;
        emit MinDepoChanged(newMinDepo);
    }

    /**
     * @notice Owner: Set `withdrawTimeout` as liquidity deposit withdrawal timeout.
     */
    function changeWithdrawTimeout(uint64 newWithdrawTimeout)
        external
        onlyOwner
    {
        withdrawTimeout = newWithdrawTimeout;
        emit WithdrawTimeoutChanged(newWithdrawTimeout);
    }

    /**
     * @notice Owner: Update Core `core` settings.
     */
    function updateCoreSettings(
        address core,
        CoreState state,
        uint64 reinforcementAbility,
        uint128 minBet
    ) external onlyOwner isCore(core) {
        if (minBet == 0) revert IncorrectMinBet();
        if (reinforcementAbility > FixedMath.ONE)
            revert IncorrectReinforcementAbility();
        if (state == CoreState.UNKNOWN) revert IncorrectCoreState();

        CoreData storage coreData = cores[core];
        coreData.minBet = minBet;
        coreData.reinforcementAbility = reinforcementAbility;
        coreData.state = state;

        emit CoreSettingsUpdated(core, state, reinforcementAbility, minBet);
    }

    /**
     * @notice See {ILP-cancelGame}.
     */
    function cancelGame(uint256 gameId)
        external
        restricted(this.cancelGame.selector)
    {
        Game storage game = _getGame(gameId);
        if (game.canceled) revert GameAlreadyCanceled();

        lockedLiquidity -= game.lockedLiquidity;
        game.canceled = true;
        emit GameCanceled(gameId);
    }

    /**
     * @notice See {ILP-createGame}.
     */
    function createGame(
        uint256 gameId,
        uint64 startsAt,
        bytes[] calldata data
    ) external restricted(this.createGame.selector) {
        Game storage game = games[gameId];
        if (game.startsAt > 0) revert GameAlreadyCreated();
        if (gameId == 0) revert IncorrectGameId();
        if (startsAt < block.timestamp) revert IncorrectTimestamp();

        game.startsAt = startsAt;

        emit NewGame(gameId, startsAt, data);
    }

    /**
     * @notice See {ILP-shiftGame}.
     */
    function shiftGame(uint256 gameId, uint64 startsAt)
        external
        restricted(this.shiftGame.selector)
    {
        if (startsAt == 0) revert IncorrectTimestamp();
        _getGame(gameId).startsAt = startsAt;
        emit GameShifted(gameId, startsAt);
    }

    /**
     * @notice Deposit liquidity in the Liquidity Pool.
     * @notice Emits deposit token to `msg.sender`.
     * @param  amount token's amount to deposit
     * @return The deposit ID.
     */
    function addLiquidity(uint128 amount) external returns (uint48) {
        _deposit(amount);
        return _addLiquidity(amount);
    }

    /**
     * @notice Donate and share liquidity between liquidity deposits.
     * @param  amount The amount of liquidity to share between deposits.
     * @param  depositId The ID of the last deposit that shares the donation.
     */
    function donateLiquidity(uint128 amount, uint48 depositId) external {
        if (amount == 0) revert SmallDonation();
        if (depositId >= nextNode) revert DepositDoesNotExist();

        _deposit(amount);
        _addLimit(amount, depositId);

        emit LiquidityDonated(msg.sender, depositId, amount);
    }

    /**
     * @notice Withdraw payout for liquidity deposit.
     * @param  depositId The ID of the liquidity deposit.
     * @param  percent The payout share to withdraw, where `FixedMath.ONE` is 100% of the deposit balance.
     * @return withdrawnAmount The amount of withdrawn liquidity.
     */
    function withdrawLiquidity(uint48 depositId, uint40 percent)
        external
        returns (uint128 withdrawnAmount)
    {
        uint64 time = uint64(block.timestamp);
        uint64 _withdrawAfter = withdrawAfter[depositId];
        if (time < _withdrawAfter)
            revert WithdrawalTimeout(_withdrawAfter - time);
        if (msg.sender != ownerOf(depositId)) revert LiquidityNotOwned();

        withdrawAfter[depositId] = time + withdrawTimeout;
        uint128 topNodeAmount = getReserve();
        withdrawnAmount = _nodeWithdrawPercent(depositId, percent);

        if (address(liquidityManager) != address(0))
            liquidityManager.afterWithdrawLiquidity(
                msg.sender,
                depositId,
                _getReserve(depositId)
            );

        // if owned deposit token and 0 deposit value - burn deposit token
        if (withdrawnAmount == 0 || percent == FixedMath.ONE) _burn(depositId);

        if (withdrawnAmount > 0) {
            // check withdrawAmount allowed in ("node #1" - "active condition reinforcements")
            if (withdrawnAmount > (topNodeAmount - lockedLiquidity))
                revert LiquidityIsLocked();

            _withdraw(msg.sender, withdrawnAmount);
        }
        emit LiquidityRemoved(msg.sender, depositId, withdrawnAmount);
    }

    /**
     * @notice Reward the Factory owner (DAO) or Data Provider with total amount of charged fees.
     * @return claimedAmount claimed reward amount
     */
    function claimReward() external returns (uint128 claimedAmount) {
        Reward storage reward = rewards[msg.sender];
        if ((block.timestamp - reward.claimedAt) < claimTimeout)
            revert ClaimTimeout(reward.claimedAt + claimTimeout);

        int128 rewardAmount = reward.amount;
        if (rewardAmount > 0) {
            reward.amount = 0;
            reward.claimedAt = uint64(block.timestamp);

            claimedAmount = uint128(rewardAmount);
            _withdraw(msg.sender, claimedAmount);
        }
    }

    /**
     * @notice Make new bet.
     * @notice Emits bet token to `msg.sender`.
     * @notice See {ILP-bet}.
     */
    function bet(
        address core,
        uint128 amount,
        uint64 expiresAt,
        IBet.BetData calldata betData
    ) external override returns (uint256) {
        _deposit(amount);
        return _bet(msg.sender, core, amount, expiresAt, betData);
    }

    /**
     * @notice Make new bet for `bettor`.
     * @notice Emits bet token to `bettor`.
     * @param  bettor wallet for emitting bet token
     * @param  core address of the Core the bet is intended
     * @param  amount amount of tokens to bet
     * @param  expiresAt the time before which bet should be made
     * @param  betData customized bet data
     */
    function betFor(
        address bettor,
        address core,
        uint128 amount,
        uint64 expiresAt,
        IBet.BetData calldata betData
    ) external override returns (uint256) {
        _deposit(amount);
        return _bet(bettor, core, amount, expiresAt, betData);
    }

    /**
     * @notice Core: Withdraw payout for bet token `tokenId` from the Core `core`.
     * @return amount The amount of withdrawn payout.
     */
    function withdrawPayout(address core, uint256 tokenId)
        external
        override
        isCore(core)
        returns (uint128 amount)
    {
        address account;
        (account, amount) = IBet(core).resolvePayout(msg.sender, tokenId);
        if (amount > 0) {
            _withdraw(account, amount);
            emit BettorWin(core, account, tokenId, amount);
        }
    }

    /**
     * @notice Active Core: Check if Core `msg.sender` can create condition for game `gameId`.
     */
    function addCondition(uint256 gameId)
        external
        view
        override
        isActive(msg.sender)
        returns (uint64)
    {
        Game storage game = _getGame(gameId);
        if (game.canceled) revert GameCanceled_();

        return game.startsAt;
    }

    /**
     * @notice Active Core: Change amount of liquidity reserved by the game `gameId`.
     * @param  gameId the game ID
     * @param  deltaReserve value of the change in the amount of liquidity used by the game as a reinforcement
     */
    function changeLockedLiquidity(uint256 gameId, int128 deltaReserve)
        external
        override
        isActive(msg.sender)
    {
        if (deltaReserve > 0) {
            uint128 _deltaReserve = uint128(deltaReserve);
            if (gameId > 0) {
                games[gameId].lockedLiquidity += _deltaReserve;
            }

            CoreData storage coreData = _getCore(msg.sender);
            coreData.lockedLiquidity += _deltaReserve;
            lockedLiquidity += _deltaReserve;

            uint256 reserve = getReserve();
            if (
                lockedLiquidity > reserve ||
                coreData.lockedLiquidity >
                coreData.reinforcementAbility.mul(reserve)
            ) revert NotEnoughLiquidity();
        } else
            _reduceLockedLiquidity(msg.sender, gameId, uint128(-deltaReserve));
    }

    /**
     * @notice Factory: Indicate `core` as new active Core.
     */
    function addCore(address core) external override onlyFactory {
        CoreData storage coreData = _getCore(core);
        coreData.minBet = 1;
        coreData.reinforcementAbility = uint64(FixedMath.ONE);
        coreData.state = CoreState.ACTIVE;

        emit CoreSettingsUpdated(
            core,
            CoreState.ACTIVE,
            uint64(FixedMath.ONE),
            1
        );
    }

    /**
     * @notice Core: Finalize changes in the balance of Liquidity Pool
     *         after the game `gameId` condition's resolve.
     * @param  gameId the game ID
     * @param  lockedReserve amount of liquidity reserved by condition
     * @param  finalReserve amount of liquidity that was not demand according to the condition result
     * @param  depositId The ID of the last deposit that shares the income. In case of loss, all deposits bear the loss
     *         collectively.
     */
    function addReserve(
        uint256 gameId,
        uint128 lockedReserve,
        uint128 finalReserve,
        uint48 depositId
    ) external override isCore(msg.sender) {
        Reward storage dataProviderRewards = rewards[dataProvider];
        Reward storage daoRewards = rewards[factory.owner()];

        if (finalReserve > lockedReserve) {
            uint128 netProfit = finalReserve - lockedReserve;
            uint256 profit = netProfit;

            // increase data provider rewards
            uint128 dataProviderReward = _getShare(
                profit,
                FeeType.DATA_PROVIDER
            );
            netProfit -= _addDelta(
                dataProviderRewards.amount,
                dataProviderReward
            );
            dataProviderRewards.amount += dataProviderReward.toInt128();
            // increase DAO rewards
            uint128 daoReward = _getShare(profit, FeeType.DAO);
            netProfit -= _addDelta(daoRewards.amount, daoReward);
            daoRewards.amount += daoReward.toInt128();

            // add profit to liquidity (reduced by data provider/dao's rewards)
            _addLimit(netProfit, depositId);
        } else {
            // remove loss from liquidityTree excluding canceled conditions (when finalReserve = lockedReserve)
            if (lockedReserve - finalReserve > 0) {
                uint128 netLoss = lockedReserve - finalReserve;
                uint256 loss = netLoss;

                // reduce data provider loss
                uint128 dataProviderLoss = _getShare(
                    loss,
                    FeeType.DATA_PROVIDER
                );
                netLoss -= _reduceDelta(
                    dataProviderRewards.amount,
                    dataProviderLoss
                );
                dataProviderRewards.amount -= dataProviderLoss.toInt128();
                // reduce DAO rewards
                uint128 daoLoss = _getShare(loss, FeeType.DAO);
                netLoss -= _reduceDelta(daoRewards.amount, daoLoss);
                daoRewards.amount -= daoLoss.toInt128();

                // remove all loss (reduced by data provider/dao's losses) from liquidity
                _remove(netLoss);
            }
        }
        if (lockedReserve > 0)
            _reduceLockedLiquidity(msg.sender, gameId, lockedReserve);
    }

    /**
     * @notice Checks if the deposit token exists (not burned).
     */
    function isDepositExists(uint256 depositId)
        external
        view
        override
        returns (bool)
    {
        return _exists(depositId);
    }

    /**
     * @notice Get the start time of the game `gameId` and whether it was canceled.
     */
    function getGameInfo(uint256 gameId)
        external
        view
        override
        returns (uint64, bool)
    {
        Game storage game = games[gameId];
        return (game.startsAt, game.canceled);
    }

    /**
     * @notice Get the max amount of liquidity that can be locked by Core `core` conditions.
     */
    function getLockedLiquidityLimit(address core)
        external
        view
        returns (uint128)
    {
        return uint128(_getCore(core).reinforcementAbility.mul(getReserve()));
    }

    /**
     * @notice Get the total amount of liquidity in the Pool.
     */
    function getReserve() public view returns (uint128 reserve) {
        return _getReserve(1);
    }

    /**
     * @notice Get the ID of the most recently made deposit.
     */
    function getLastDepositId()
        external
        view
        override
        returns (uint48 depositId)
    {
        return (nextNode - 1);
    }

    /**
     * @notice Check if game `gameId` is canceled.
     */
    function isGameCanceled(uint256 gameId)
        external
        view
        override
        returns (bool)
    {
        return games[gameId].canceled;
    }

    /**
     * @notice Get bet token `tokenId` payout.
     * @param  core address of the Core where bet was placed
     * @param  tokenId bet token ID
     * @return payout winnings of the token owner
     */
    function viewPayout(address core, uint256 tokenId)
        external
        view
        isCore(core)
        returns (uint128)
    {
        return IBet(core).viewPayout(tokenId);
    }

    /**
     * @notice Throw if `account` have no access to function with selector `selector` of `target`.
     */
    function checkAccess(
        address account,
        address target,
        bytes4 selector
    ) public {
        access.checkAccess(account, target, selector);
    }

    /**
     * @notice Throw if `core` not belongs to the Liquidity Pool's Cores.
     */
    function checkCore(address core) public view {
        if (_getCore(core).state == CoreState.UNKNOWN) revert UnknownCore();
    }

    /**
     * @notice Deposit liquidity in the Liquidity Pool.
     * @notice Emits deposit token to `msg.sender`.
     * @param  amount token's amount to deposit
     * @return depositId The ID of made liquidity deposit.
     */
    function _addLiquidity(uint128 amount) internal returns (uint48 depositId) {
        if (amount < minDepo) revert SmallDepo();

        depositId = _nodeAddLiquidity(amount);

        if (address(liquidityManager) != address(0))
            liquidityManager.beforeAddLiquidity(msg.sender, depositId, amount);

        withdrawAfter[depositId] = uint64(block.timestamp) + withdrawTimeout;
        _mint(msg.sender, depositId);
        emit LiquidityAdded(msg.sender, depositId, amount);
    }

    /**
     * @notice Make new bet.
     * @param  bettor wallet for emitting bet token
     * @param  core address of the Core the bet is intended
     * @param  amount amount of tokens to bet
     * @param  expiresAt the time before which bet should be made
     * @param  betData customized bet data
     */
    function _bet(
        address bettor,
        address core,
        uint128 amount,
        uint64 expiresAt,
        IBet.BetData memory betData
    ) internal isActive(core) returns (uint256) {
        if (block.timestamp >= expiresAt) revert BetExpired();
        if (amount < _getCore(core).minBet) revert SmallBet();
        // owner is default affiliate
        if (betData.affiliate == address(0)) betData.affiliate = owner();
        return IBet(core).putBet(bettor, amount, betData);
    }

    /**
     * @notice Deposit `amount` of `token` tokens from `account` balance to the contract.
     */
    function _deposit(uint128 amount) internal {
        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            amount
        );
    }

    function _reduceLockedLiquidity(
        address core,
        uint256 gameId,
        uint128 deltaReserve
    ) internal {
        if (gameId > 0) {
            games[gameId].lockedLiquidity -= deltaReserve;
        }
        _getCore(core).lockedLiquidity -= deltaReserve;
        lockedLiquidity -= deltaReserve;
    }

    /**
     * @notice Withdraw `amount` of tokens to `account` balance.
     */
    function _withdraw(address account, uint128 amount) internal {
        TransferHelper.safeTransfer(token, account, amount);
    }

    /**
     * @notice Throw if `core` not belongs to the Liquidity Pool's active Cores.
     */
    function _checkCoreActive(address core) internal view {
        if (_getCore(core).state != CoreState.ACTIVE) revert CoreNotActive();
    }

    /**
     * @notice Throw if set fees are incorrect.
     */
    function _checkFee() internal view {
        if (
            _getFee(FeeType.DAO) + _getFee(FeeType.DATA_PROVIDER) >
            FixedMath.ONE
        ) revert IncorrectFee();
    }

    function _getCore(address core) internal view returns (CoreData storage) {
        return cores[core];
    }

    /**
     * @notice Get current fee type `feeType` profit share.
     */
    function _getFee(FeeType feeType) internal view returns (uint64) {
        return fees[uint256(feeType)];
    }

    /**
     * @notice Get game by it's ID.
     */
    function _getGame(uint256 gameId) internal view returns (Game storage) {
        Game storage game = games[gameId];
        if (game.startsAt == 0) revert GameNotExists();

        return game;
    }

    /**
     * @notice Get the amount of liquidity remaining on the deposit `depositId`.
     */
    function _getReserve(uint48 depositId) internal view returns (uint128) {
        return treeNode[depositId].amount;
    }

    function _getShare(uint256 amount, FeeType feeType)
        internal
        view
        returns (uint128)
    {
        return _getFee(feeType).mul(amount).toUint128();
    }

    /**
     * @notice Calculate the positive delta between `a` and `a + b`.
     */
    function _addDelta(int128 a, uint128 b) internal pure returns (uint128) {
        if (a < 0) {
            int128 c = a + b.toInt128();
            return (c > 0) ? uint128(c) : 0;
        } else return b;
    }

    /**
     * @notice Calculate the positive delta between `a - b` and `a`.
     */
    function _reduceDelta(int128 a, uint128 b) internal pure returns (uint128) {
        return (a < 0 ? 0 : (a > b.toInt128() ? b : uint128(a)));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "../libraries/FixedMath.sol";

contract LiquidityTree {
    using FixedMath for uint40;

    struct Node {
        uint64 updateId; // last update number
        uint128 amount; // node amount
    }

    uint48 constant LIQUIDITYNODES = 1_099_511_627_776; // begining of data nodes (top at node #1)
    uint48 constant LIQUIDITYLASTNODE = LIQUIDITYNODES * 2 - 1;

    uint48 public nextNode; // next unused node number for adding liquidity

    uint64 public updateId; // update number, used instead of timestamp for splitting changes time on the same nodes

    // liquidity (segment) tree
    mapping(uint48 => Node) public treeNode;

    error LeafNotExist();
    error IncorrectPercent();

    /**
     * @dev initializing LIQUIDITYNODES and nextNode.
     * @dev LIQUIDITYNODES is count of liquidity (segment) tree leaves contains single liquidity addings
     * @dev liquidity (segment) tree build as array of 2*LIQUIDITYNODES count, top node has id #1 (id #0 not used)
     * @dev liquidity (segment) tree leaves is array [LIQUIDITYNODES, 2*LIQUIDITYNODES-1]
     * @dev liquidity (segment) tree node index N has left child index 2*N and right child index 2N+1
     * @dev +--------------------------------------------+
            |                  1 (top node)              |
            +------------------------+-------------------+
            |             2          |         3         |
            +-------------+----------+---------+---------+
            | 4 (nextNode)|     5    |    6    |    7    |
            +-------------+----------+---------+---------+
     */
    function __liquidityTree_init() internal {
        nextNode = LIQUIDITYNODES;
        updateId++; // start from non zero
    }

    /**
     * @dev leaf withdraw preview, emulates push value from updated node to leaf
     * @param leaf - withdrawing leaf
     */
    function nodeWithdrawView(uint48 leaf)
        public
        view
        returns (uint128 withdrawAmount)
    {
        if (leaf < LIQUIDITYNODES || leaf > LIQUIDITYLASTNODE) return 0;
        if (treeNode[leaf].updateId == 0) return 0;

        // get last-updated top node
        (uint48 updatedNode, uint48 start, uint48 end) = _getUpdatedNode(
            1,
            treeNode[1].updateId,
            LIQUIDITYNODES,
            LIQUIDITYLASTNODE,
            1,
            LIQUIDITYNODES,
            LIQUIDITYLASTNODE,
            leaf
        );

        return
            _getPushView(
                updatedNode,
                start,
                end,
                leaf,
                treeNode[updatedNode].amount
            );
    }

    /**
     * @dev add amount only for limited leaves in tree [first_leaf, leaf]
     * @param amount value to add
     */
    function _addLimit(uint128 amount, uint48 leaf) internal {
        // get last-updated top node
        (uint48 updatedNode, uint48 start, uint48 end) = _getUpdatedNode(
            1,
            treeNode[1].updateId,
            LIQUIDITYNODES,
            LIQUIDITYLASTNODE,
            1,
            LIQUIDITYNODES,
            LIQUIDITYLASTNODE,
            leaf
        );
        uint64 updateId_ = updateId;
        // push changes from last-updated node down to the leaf, if leaf is not up to date
        _push(updatedNode, start, end, leaf, ++updateId_);
        _pushLazy(
            1,
            LIQUIDITYNODES,
            LIQUIDITYLASTNODE,
            LIQUIDITYNODES,
            leaf,
            amount,
            false,
            ++updateId_
        );

        updateId = updateId_;
    }

    /**
     * @dev change amount by adding value or reducing value
     * @param node - node for changing
     * @param amount - amount value for changing
     * @param isSub - true - reduce by amount, true - add by amount
     * @param updateId_ - update number
     */
    function _changeAmount(
        uint48 node,
        uint128 amount,
        bool isSub,
        uint64 updateId_
    ) internal {
        treeNode[node].updateId = updateId_;
        if (isSub) {
            treeNode[node].amount -= amount;
        } else {
            treeNode[node].amount += amount;
        }
    }

    /**
     * @dev add liquidity amount from the leaf up to top node
     * @param amount - adding amount
     */
    function _nodeAddLiquidity(uint128 amount)
        internal
        returns (uint48 resNode)
    {
        resNode = nextNode++;
        _updateUp(resNode, amount, false, ++updateId);
    }

    /**
     * @dev withdraw part of liquidity from the leaf, due possible many changes in leaf's parent nodes
     * @dev it is needed firstly to update its amount and then withdraw
     * @dev used steps:
     * @dev 1 - get last updated parent most near to the leaf
     * @dev 2 - push all changes from found parent to the leaf - that updates leaf's amount
     * @dev 3 - execute withdraw of leaf amount and update amount changing up to top parents
     * @param leaf -
     * @param percent - percent of leaf amount 1*10^12 is 100%, 5*10^11 is 50%
     */
    function _nodeWithdrawPercent(uint48 leaf, uint40 percent)
        internal
        returns (uint128 withdrawAmount)
    {
        if (treeNode[leaf].updateId == 0) revert LeafNotExist();
        if (percent > FixedMath.ONE) revert IncorrectPercent();

        // get last-updated top node
        (uint48 updatedNode, uint48 start, uint48 end) = _getUpdatedNode(
            1,
            treeNode[1].updateId,
            LIQUIDITYNODES,
            LIQUIDITYLASTNODE,
            1,
            LIQUIDITYNODES,
            LIQUIDITYLASTNODE,
            leaf
        );
        uint64 updateId_ = updateId;
        // push changes from last-updated node down to the leaf, if leaf is not up to date
        _push(updatedNode, start, end, leaf, ++updateId_);

        // remove amount (percent of amount) from leaf to it's parents
        withdrawAmount = uint128(percent.mul(treeNode[leaf].amount));
        _updateUp(leaf, withdrawAmount, true, ++updateId_);

        updateId = updateId_;
    }

    /**
     * @dev push changes from last "lazy update" down to leaf
     * @param node - last node from lazy update
     * @param start - leaf search start
     * @param end - leaf search end
     * @param leaf - last node to update
     * @param updateId_ update number
     */
    function _push(
        uint48 node,
        uint48 start,
        uint48 end,
        uint48 leaf,
        uint64 updateId_
    ) internal {
        // if node is leaf, stop
        if (node == leaf) {
            return;
        }
        uint48 lChild = node * 2;
        uint48 rChild = node * 2 + 1;
        uint128 amount = treeNode[node].amount;
        uint256 lAmount = treeNode[lChild].amount;
        uint256 rAmount = treeNode[rChild].amount;
        uint256 sumAmounts = lAmount + rAmount;
        if (sumAmounts == 0) return;
        uint128 setLAmount = uint128((amount * lAmount) / sumAmounts);

        // update left and right child
        _setAmount(lChild, setLAmount, updateId_);
        _setAmount(rChild, amount - setLAmount, updateId_);

        uint48 mid = (start + end) / 2;

        if (start <= leaf && leaf <= mid) {
            _push(lChild, start, mid, leaf, updateId_);
        } else {
            _push(rChild, mid + 1, end, leaf, updateId_);
        }
    }

    /**
     * @dev push lazy (lazy propagation) amount value from top node to child nodes contained leafs from 0 to r
     * @param node - start from node
     * @param start - node left element
     * @param end - node right element
     * @param l - left leaf child
     * @param r - right leaf child
     * @param amount - amount to add/reduce stored amounts
     * @param isSub - true means negative to reduce
     * @param updateId_ update number
     */
    function _pushLazy(
        uint48 node,
        uint48 start,
        uint48 end,
        uint48 l,
        uint48 r,
        uint128 amount,
        bool isSub,
        uint64 updateId_
    ) internal {
        if ((start == l && end == r) || (start == end)) {
            // if node leafs equal to leaf interval then stop
            _changeAmount(node, amount, isSub, updateId_);
            return;
        }

        uint48 mid = (start + end) / 2;

        if (start <= r && r <= mid) {
            // [l,r] in [start,mid] - all leafs in left child
            _pushLazy(node * 2, start, mid, l, r, amount, isSub, updateId_);
        } else {
            uint256 lAmount = treeNode[node * 2].amount;
            // get right amount excluding unused leaves when adding amounts
            uint256 rAmount = treeNode[node * 2 + 1].amount -
                (
                    !isSub
                        ? _getLeavesAmount(
                            node * 2 + 1,
                            mid + 1,
                            end,
                            r + 1,
                            end
                        )
                        : 0
                );
            uint256 sumAmounts = lAmount + rAmount;
            if (sumAmounts == 0) return;
            uint128 forLeftAmount = uint128((amount * lAmount) / sumAmounts);

            // l in [start,mid] - part in left child
            _pushLazy(
                node * 2,
                start,
                mid,
                l,
                mid,
                forLeftAmount,
                isSub,
                updateId_
            );

            // r in [mid+1,end] - part in right child
            _pushLazy(
                node * 2 + 1,
                mid + 1,
                end,
                mid + 1,
                r,
                amount - forLeftAmount,
                isSub,
                updateId_
            );
        }
        _changeAmount(node, amount, isSub, updateId_);
    }

    /**
     * @dev remove amount from whole tree, starting from top node #1
     * @param amount value to remove
     */
    function _remove(uint128 amount) internal {
        if (treeNode[1].amount >= amount) {
            _pushLazy(
                1,
                LIQUIDITYNODES,
                LIQUIDITYLASTNODE,
                LIQUIDITYNODES,
                nextNode - 1,
                amount,
                true,
                ++updateId
            );
        }
    }

    /**
     * @dev reset node amount, used in push
     * @param node for set
     * @param amount value
     * @param updateId_ update number
     */
    function _setAmount(
        uint48 node,
        uint128 amount,
        uint64 updateId_
    ) internal {
        if (treeNode[node].amount != amount) {
            treeNode[node].updateId = updateId_;
            treeNode[node].amount = amount;
        }
    }

    /**
     * @dev update up amounts from leaf up to top node #1, used in adding/removing values on leaves
     * @param child node for update
     * @param amount value for update
     * @param isSub true - reduce, false - add
     * @param updateId_ update number
     */
    function _updateUp(
        uint48 child,
        uint128 amount,
        bool isSub,
        uint64 updateId_
    ) internal {
        _changeAmount(child, amount, isSub, updateId_);
        // if not top parent
        if (child != 1) {
            _updateUp(child > 1 ? child / 2 : 1, amount, isSub, updateId_);
        }
    }

    /**
     * @dev for current node get sum amount of exact leaves list
     * @param node node to get sum amount
     * @param start - node left element
     * @param end - node right element
     * @param l - left leaf of the list
     * @param r - right leaf of the list
     * @return amount sum of leaves list
     */
    function _getLeavesAmount(
        uint48 node,
        uint48 start,
        uint48 end,
        uint48 l,
        uint48 r
    ) internal view returns (uint128 amount) {
        if ((start == l && end == r) || (start == end)) {
            // if node leafs equal to leaf interval then stop and return amount value
            return (treeNode[node].amount);
        }

        uint48 mid = (start + end) / 2;

        if (start <= l && l <= mid) {
            amount += _getLeavesAmount(node * 2, start, mid, l, mid);
            amount += _getLeavesAmount(node * 2 + 1, mid + 1, end, mid + 1, r);
        } else {
            amount += _getLeavesAmount(node * 2 + 1, mid + 1, end, l, r);
        }

        return amount;
    }

    /**
     * @dev   emulating push changes from last "lazy update" down to leaf
     * @param node - last node from lazy update
     * @param start - leaf search start
     * @param end - leaf search end
     * @param leaf - last node to update
     * @param amount - pushed (calced) amount for the node
     */
    function _getPushView(
        uint48 node,
        uint48 start,
        uint48 end,
        uint48 leaf,
        uint128 amount
    ) internal view returns (uint128 withdrawAmount) {
        // if node is leaf, stop
        if (node == leaf) {
            return amount;
        }

        uint48 lChild = node * 2;
        uint48 rChild = node * 2 + 1;
        uint256 lAmount = treeNode[lChild].amount;
        uint256 sumAmounts = lAmount + treeNode[rChild].amount;
        if (sumAmounts == 0) return 0;
        uint128 setLAmount = uint128((amount * lAmount) / sumAmounts);

        uint48 mid = (start + end) / 2;

        if (start <= leaf && leaf <= mid) {
            return _getPushView(lChild, start, mid, leaf, setLAmount);
        } else {
            return
                _getPushView(rChild, mid + 1, end, leaf, amount - setLAmount);
        }
    }

    /**
     * @dev top node is ever most updated, trying to find lower node not older then top node
     * @dev get nearest to leaf (lowest) last-updated node from the parents, runing down from top to leaf
     * @param parent top node
     * @param parentUpdate top node update
     * @param parentBegin top node most left leaf
     * @param parentEnd top node most right leaf
     * @param node node parent for the leaf
     * @param start node most left leaf
     * @param end node most right leaf
     * @param leaf target leaf
     * @return resParent found most updated leaf parent
     * @return resBegin found parent most left leaf
     * @return resEnd found parent most right leaf
     */
    function _getUpdatedNode(
        uint48 parent,
        uint64 parentUpdate,
        uint48 parentBegin,
        uint48 parentEnd,
        uint48 node,
        uint48 start,
        uint48 end,
        uint48 leaf
    )
        internal
        view
        returns (
            uint48 resParent,
            uint48 resBegin,
            uint48 resEnd
        )
    {
        // if node is older than it's parent, stop and return parent
        if (treeNode[node].updateId < parentUpdate) {
            return (parent, parentBegin, parentEnd);
        }
        if (node == leaf) {
            return (leaf, start, end);
        }

        uint48 mid = (start + end) / 2;

        if (start <= leaf && leaf <= mid) {
            // work on left child
            (resParent, resBegin, resEnd) = _getUpdatedNode(
                node,
                parentUpdate,
                start,
                end,
                node * 2,
                start,
                mid,
                leaf
            );
        } else {
            // work on right child
            (resParent, resBegin, resEnd) = _getUpdatedNode(
                node,
                parentUpdate,
                start,
                end,
                node * 2 + 1,
                mid + 1,
                end,
                leaf
            );
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../interface/IOwnable.sol";

/**
 * @dev Forked from OpenZeppelin contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/ae03ee04ae226526abad6731cf4024134f46ae28/contracts/access/OwnableUpgradeable.sol
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
abstract contract OwnableUpgradeable is
    IOwnable,
    Initializable,
    ContextUpgradeable
{
    address private _owner;

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        checkOwner(_msgSender());
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the account is not the owner.
     */
    function checkOwner(address account) public view virtual override {
        require(owner() == account, "Ownable: account is not the owner");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}