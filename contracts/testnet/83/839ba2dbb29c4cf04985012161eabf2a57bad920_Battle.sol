// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981Upgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {
    function __ERC2981_init() internal onlyInitializing {
    }

    function __ERC2981_init_unchained() internal onlyInitializing {
    }
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

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

        _afterTokenTransfer(from, to, tokenId, 1);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
library Counters {
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

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IBattle.sol";
import "../mint_info/IMintInfoOracle.sol";
import "../final_form_cards/IFinalFormCards.sol";
import "../final_form_cards/FinalFormCards.sol";
import "../pledging/IPledging.sol";
import "./HirelingLogic.sol";
import "./BattleLogic.sol";

pragma solidity ^0.8.12;

// Error Messages
// 1: Tried setting eth price for hireling of invalid rarity.
// 2: Invalid rarity
// 3: Cannot purchase or claim free hirelings unless your next battle has been prepared.
// 4: No hireling exists for the specified rarity at the specified index.
// 5: Already claimed this hireling from this hand.
// 6: Invalid rarity, house, and token index association
// 7: Invalid value for specified hireling price.
// 8: Nothing to withdraw.
// 9: Battle config is already set for your wallet address. Complete your pending battle before requesting a new opponent!
// 10: Cannot request new hireling draw if next battle is not queued.
// 11: You have already employed a hireling from the current selection. Wait for your next battle to see new options.
// 12: Must prepare a battle first.
// 13: No battle data saved for ID.
// 15. Invalid rarity for hireling lookup
// 16. Invalid house for hireling lookup
// 17. Failed to send Ether
// 18. Invalid hireling rarity & house combo submitted for purchase

contract Battle is IBattle, AccessControl {

	struct Hireling {
		uint8 rarity;
		uint8 house;
		uint256 index;
		uint256 power;
		uint256 hp;
		uint256 attack;
		uint256 ability1;
		uint256 ability2;
		uint256 ability3;
		bool initialized;
	}

	struct CardOrHireling {
		bool isCard;
		uint256 id;
	}

	struct BattlePrepConfig {
		CardOrHireling[4] enemyCards; // Adversary card indexes.
		uint256[4][4] availableHirelings; // Token indexes of hirelings by house by rarity.
		bool[4][4] purchasedHirelings; // Track if user has purchased hirelings by house by rarity.
		uint8[2] freeCommonHouses; // Represents which 2 houses of the randomly generated commons hirelings are free for this draw. Example: if freeCommonHouses[0] == 3, then availableHirelings[0][3] is free.
		bool ready; // Gets marked as true when the config is prepared for the user's upcoming battle; if true then config is saved, if false then user has no battle config prepped and must do so before attempting to battle.
		bool claimedAnyHireling; // A flag so we know if the user is allowed to "re-roll" the hireling list for their "current" battle.
	}

	struct BattleData {
		bool initialized;
		uint8 result;
		uint256[] logs;
	}

	struct ContractData {
		mapping(address => BattlePrepConfig) nextBattleConfig;
		mapping(uint256 => BattleData) battleDataMap;
		mapping(uint8 => mapping(uint8 => Hireling[])) hirelingPool; // Map rarities => houses => hireling pool
		mapping(address => mapping(uint8 => mapping(uint8 => uint256[]))) userHirelingsLists; // Map wallets => hireling rarities => hireling houses => index in associated hirelingPool
		mapping(address => mapping(uint8 => mapping(uint8 => mapping(uint256 => uint256)))) userHirelingsOwnershipLookup; // wallet => rarities => house => index => number owned of that hireling
	}

	using Counters for Counters.Counter;
	Counters.Counter _currentBattleId;

	bytes32 public constant ADMIN_AUTH = keccak256("ADMIN_AUTH");

	address private _mintInfoOracleAddress;
	address private _finalFormCardsAddress;
	address private _pledgingAddress;
	address payable private _hirelingRevenueReceiver;

	mapping(uint8 => uint256) private _hirelingPrices; // Map hireling rarities => price to buy in wei

	ContractData private _contractData;

	event PreparedBattle(address user);
	event PurchasedHireling(address user, uint8 rarity, uint8 house, uint256 index);
	event ReRolledHirelings(address user);
	event Battle(uint256 id, uint8 result, address user);

	function initialize(
		address mintInfoOracleAddress_,
		address finalFormCardsAddress_,
		address pledgingAddress_,
		address admin_,
		address payable hirelingRevenueReceiver_,
		uint256 commonPrice_,
		uint256 rarePrice_,
		uint256 epicPrice_,
		uint256 legendaryPrice_
	) external {
		_mintInfoOracleAddress = mintInfoOracleAddress_;
		_finalFormCardsAddress = finalFormCardsAddress_;
		_pledgingAddress = pledgingAddress_;
		_hirelingRevenueReceiver = hirelingRevenueReceiver_;
		_setupRole(ADMIN_AUTH, admin_);
		_setRoleAdmin(ADMIN_AUTH, ADMIN_AUTH);

		_hirelingPrices[0] = commonPrice_;
		_hirelingPrices[1] = rarePrice_;
		_hirelingPrices[2] = epicPrice_;
		_hirelingPrices[3] = legendaryPrice_;
	}

	function updateHirelingPrice(uint8 rarity, uint256 price) external onlyRole(ADMIN_AUTH) {
		require(rarity <= 3, "1");
		_hirelingPrices[rarity] = price;
	}

	function getHirelingPrices() external view returns (uint256[4] memory prices) {
		return [
			_hirelingPrices[0],
			_hirelingPrices[1],
			_hirelingPrices[2],
			_hirelingPrices[3]
		];
	}

	function purchaseHireling(uint8 rarity, uint8 house, uint256 tokenIndex) external payable {
		require(rarity <= 3 && house <= 3, "18");
		require(_contractData.nextBattleConfig[msg.sender].ready, "3");
		require(_contractData.hirelingPool[rarity][house][tokenIndex].initialized, "4");
		require(!_contractData.nextBattleConfig[msg.sender].purchasedHirelings[rarity][house], "5");
		require(_contractData.nextBattleConfig[msg.sender].availableHirelings[rarity][house] == tokenIndex, "6");

		// if the card being "purchased" is NOT one of the free commons of this hand, then require they correct amount is being paid
		if (
			rarity > 0 || (
				rarity == 0 && (
					_contractData.nextBattleConfig[msg.sender].freeCommonHouses[0] != house &&
					_contractData.nextBattleConfig[msg.sender].freeCommonHouses[1] != house
				)
			)
		) {
			require(msg.value == _hirelingPrices[rarity], "7");
			(bool sent,) = _hirelingRevenueReceiver.call{value: msg.value}("");
			require(sent, "17");
		}

		_contractData.userHirelingsLists[msg.sender][rarity][house].push(tokenIndex);
		_contractData.userHirelingsOwnershipLookup[msg.sender][rarity][house][tokenIndex] += 1;
		_contractData.nextBattleConfig[msg.sender].purchasedHirelings[rarity][house] = true;

		if (!_contractData.nextBattleConfig[msg.sender].claimedAnyHireling) {
			_contractData.nextBattleConfig[msg.sender].claimedAnyHireling = true;
		}

		emit PurchasedHireling(msg.sender, rarity, house, tokenIndex);
	}

	function setHirelingData(uint8 rarity, Hireling[] calldata metadata) external onlyRole(ADMIN_AUTH) {
		HirelingLogic.setHirelingData(rarity, metadata, _contractData);
	}

	function prepareBattle() external {
		require(_contractData.nextBattleConfig[msg.sender].ready == false, "9");
		HirelingLogic.prepareBattle(_contractData, _finalFormCardsAddress);
		emit PreparedBattle(msg.sender);
	}

	function getBattleConfig(address wallet) external view returns (BattlePrepConfig memory config) {
		return _contractData.nextBattleConfig[wallet];
	}

	function requestNewHirelingsDraw() external {
		HirelingLogic.requestNewHirelingsDraw(_contractData);
		emit ReRolledHirelings(msg.sender);
	}

	function getHirelingsFromConfig() external view returns (Hireling[] memory hirelings, bool[] memory purchases) {
		return HirelingLogic.getHirelingsFromConfig(_contractData);
	}

	function getOwnedHirelingsIndexes(address wallet) external view returns (uint256[][4][4] memory hirelingIndexes) {
		return HirelingLogic.getOwnedHirelingsIndexes(wallet, _contractData);
	}

	function getHirelings(uint8 rarity, uint8 house, uint256[] calldata indexes) external view returns (Hireling[] memory hirelings) {
		return HirelingLogic.getHirelings(rarity, house, indexes, _contractData);
	}

	//--------- Just For Testing ---------// TODO remove functions in this block before prod

	function testGenerateRandomHirelings() external view returns(uint256[4][4] memory availableHirelings, uint8[2] memory freeCommonHouses) {
		return HirelingLogic.generateHirelings(_contractData);
	}

	// use to remove your battle config so you can get a new one without going through battle flow
	function deleteBattleConfig() external {
		delete _contractData.nextBattleConfig[msg.sender];
	}

	function bigBoyDumbTest() external view returns(bool ready) {
		return _contractData.nextBattleConfig[msg.sender].ready;
	}

	//---------------------------------------//

//	function getContractData() external view returns (ContractData memory) {
//		return _contractData;
//	}

	function battle(uint256[4] calldata deck) external {
		uint8 result = BattleLogic.battle(deck, _currentBattleId.current(), _pledgingAddress, _finalFormCardsAddress, _mintInfoOracleAddress, _contractData);

		emit Battle(_currentBattleId.current(), result, msg.sender);

		_currentBattleId.increment();
	}

	function lookup(uint256 battleId) external view returns (BattleData memory battle) {
		require(_contractData.battleDataMap[battleId].initialized, "13");

        return (_contractData.battleDataMap[battleId]);
    }
}

import "./Battle.sol";
import "../pledging/IPledging.sol";
import "../mint_info/IMintInfoOracle.sol";

pragma solidity ^0.8.12;

// Battle log format: number
// Every encoded value will take 2 digits
// type of action
//   0: game end - {win (00) / lose (01) / tie (02)}00
//   1: base attack - {enemyDamage}{yourDamage}{indexOfEnemy}{indexOfYou}01
//   2: death - {Array<indexOfEnemyDead}99{Array<indexOfYourDead>}02

library BattleLogic {
    function battle(uint256[4] calldata deck, uint256 battleId, address pledgingAddress, address finalFormCardsAddress, address mintInfoOracleAddress, Battle.ContractData storage data) external returns (uint8 result) {
        // get the deck data and validate users ownership
        //		uint256[3][4] memory deckData;
        //		uint256[3][4] memory enemyDeckData;
        //
        //		uint256[4] memory deckCardIds;
        //		uint256[4] memory enemyDeckCardIds;
        //
        //		for (uint8 i = 0; i < 4; i++) {
        //			if (deck[i].isCard) {
        //				deckCardIds[i] = deck[i].id;
        //			} else {
        //				// count how many times this hireling is in the deck
        //				uint8 count = 0;
        //				for (uint8 j = 0; j < 4; j++) {
        //					if (!deck[j].isCard && deck[j].id == deck[i].id) {
        //						count++;
        //					}
        //				}
        //
        //				// check user owns [count] of this hireling
        //				require(_userHirelingsOwnershipLookup[msg.sender][deck[i].id % 10][deck[i].id % 100 / 10][deck[i].id / 100] >= count, "Did not own all hirelings used");
        //
        //				// set hireling data for deck
        //				deckData[i] = [
        //					i,
        //					_hirelingPool[deck[i].id % 10][deck[i].id % 100 / 10][deck[i].id / 100].hp + 1,
        //					_hirelingPool[deck[i].id % 10][deck[i].id % 100 / 10][deck[i].id / 100].attack + 1
        //				];
        //			}
        //
        //			if (enemyDeck[i].isCard) {
        //				enemyDeckCardIds[i] = enemyDeck[i].id;
        //			} else {
        //				enemyDeckData[i] = [
        //					i,
        //					_hirelingPool[enemyDeck[i].id % 10][enemyDeck[i].id % 100 / 10][enemyDeck[i].id / 100].hp + 1,
        //					_hirelingPool[enemyDeck[i].id % 10][enemyDeck[i].id % 100 / 10][enemyDeck[i].id / 100].attack + 1
        //				]
        //			}
        //		}

        // check that user has a active battle config
        require(data.nextBattleConfig[msg.sender].ready, "No battle config set");

        // check that user owns the deck cards and that cards are pledged
        require(IPledging(pledgingAddress).verifyPledgedCardsOwnership(finalFormCardsAddress, msg.sender, deck), "Could not verify card ownership");

        // get deck metadata
//        (uint256[3][4] memory deckData, uint256[3][4] memory enemyDeckData) = IMintInfoOracle(mintInfoOracleAddress).getDeckBattleData(finalFormCardsAddress, deck, data.nextBattleConfig[msg.sender].enemyCards);
        uint256[4] memory test;
        (uint256[3][4] memory deckData, uint256[3][4] memory enemyDeckData) = IMintInfoOracle(mintInfoOracleAddress).getDeckBattleData(finalFormCardsAddress, deck, test);

        uint256 currentLogIndex = 0;
        uint256[] memory logs = new uint256[](128);

        // battle loop
        while (isDeckAlive(deckData) && isDeckAlive(enemyDeckData)) {
            // basic attack
            if (enemyDeckData[0][1] < deckData[0][2]) {
                enemyDeckData[0][1] = 0;
            } else {
                enemyDeckData[0][1] = enemyDeckData[0][1] - deckData[0][2];
            }

            if (deckData[0][1] < enemyDeckData[0][2]) {
                deckData[0][1] = 0;
            } else {
                deckData[0][1] = deckData[0][1] - enemyDeckData[0][2];
            }

            // log basic attack
            logs[currentLogIndex] = 1 + 100 * deckData[0][0] + 10000 * enemyDeckData[0][0] + 1000000 * deckData[0][2] + 100000000 * enemyDeckData[0][2];
            currentLogIndex++;

            // log any deaths
            if (deckData[0][1] == 0 || enemyDeckData[0][1] == 0) {
                if (deckData[0][1] == 0 && enemyDeckData[0][1] == 0) {
                    logs[currentLogIndex] = 2 + 100 * deckData[0][0] + 990000 + 1000000 * enemyDeckData[0][0];
                } else if (deckData[0][1] == 0) {
                    logs[currentLogIndex] = 2 + 100 * deckData[0][0];
                } else if (enemyDeckData[0][1] == 0) {
                    logs[currentLogIndex] = 2 + 100 * 99 + 10000 * enemyDeckData[0][0];
                }

                currentLogIndex++;
            }

            // early exit if dead
            if (!isDeckAlive(deckData) || !isDeckAlive(enemyDeckData)) {
                break;
            }

            // move up deckData
            uint8 deckIndex = 0;
            if (deckData[0][1] != 0) {
                deckIndex++;
            }

            if (deckData[1][1] != 0) {
                deckData[deckIndex] = deckData[1];
                deckIndex++;
            }

            if (deckData[2][1] != 0) {
                deckData[deckIndex] = deckData[2];
                deckIndex++;
            }

            if (deckData[3][1] != 0) {
                deckData[deckIndex] = deckData[3];
                deckIndex++;
            }

            while (deckIndex < 4) {
                delete deckData[deckIndex];
                deckIndex++;
            }

            // move up enemy deck
            uint8 enemyDeckIndex = 0;
            if (enemyDeckData[0][1] != 0) {
                enemyDeckIndex++;
            }

            if (enemyDeckData[1][1] != 0) {
                enemyDeckData[enemyDeckIndex] = enemyDeckData[1];
                enemyDeckIndex++;
            }

            if (enemyDeckData[2][1] != 0) {
                enemyDeckData[enemyDeckIndex] = enemyDeckData[2];
                enemyDeckIndex++;
            }

            if (enemyDeckData[3][1] != 0) {
                enemyDeckData[enemyDeckIndex] = enemyDeckData[3];
                enemyDeckIndex++;
            }

            while (enemyDeckIndex < 4) {
                delete enemyDeckData[enemyDeckIndex];
                enemyDeckIndex++;
            }
        }

        // determine result
        uint8 result;
        if (isDeckAlive(deckData)) {
            result = 0;
            logs[currentLogIndex] = 0;
        } else if (isDeckAlive(enemyDeckData)) {
            result = 1;
            logs[currentLogIndex] = 100;
        } else {
            result = 2;
            logs[currentLogIndex] = 200;
        }

        currentLogIndex++;

        // delete user's hirelings on loss
        //		if (result == 1) {
        //			for (uint8 i = 0; i < 4; i++) {
        //				for (uint8 j = 0; j < 4; j++) {
        //					for (uint256 index = 0; index < _userHirelingsLists[msg.sender][i][j].length; index++) {
        //						delete _userHirelingsOwnershipLookup[msg.sender][i][j][_userHirelingsLists[msg.sender][i][j][index]];
        //					}
        //
        //					delete _userHirelingsLists[msg.sender][i][j];
        //				}
        //			}
        //		}

        // create BattleData
        data.battleDataMap[battleId] = Battle.BattleData(true, result, logs);

        delete data.nextBattleConfig[msg.sender];

        return result;
    }

    function isDeckAlive(uint256[3][4] memory deck) internal pure returns (bool) {
        return deck[0][1] > 0 || deck[1][1] > 0 || deck[2][1] > 0 || deck[3][1] > 0;
    }
}

import "./Battle.sol";
import "../final_form_cards/FinalFormCards.sol";
//import "hardhat/console.sol";

pragma solidity ^0.8.12;

library HirelingLogic {

	function setHirelingData(uint8 rarity, Battle.Hireling[] calldata metadata, Battle.ContractData storage data) external {
		require(rarity <= 3, "2");

		for (uint8 i; i < metadata.length; i++) {
			data.hirelingPool[rarity][metadata[i].house].push(
				Battle.Hireling({
					rarity: rarity,
					house: metadata[i].house,
					index: data.hirelingPool[rarity][metadata[i].house].length,
					power: metadata[i].power,
					hp: metadata[i].hp,
					attack: metadata[i].attack,
					ability1: metadata[i].ability1,
					ability2: metadata[i].ability2,
					ability3: metadata[i].ability3,
					initialized: true
				})
			);
		}
	}

	function prepareBattle(Battle.ContractData storage data, address finalFormCardsAddress) external {
		// check that the user has no pending battle so they can't abuse re-rolling opponents until they get an easy fight
//		require(!data.nextBattleConfig[msg.sender].ready, "9");
		require(data.nextBattleConfig[msg.sender].ready == false, "9");

		// generate cards for the adversary's deck
		uint256[] memory enemyCards = new uint256[](4);

		// use the total token supply to generate ids of 4 in-circulation cards to use for adversary deck
//		uint256 totalSupplyRange = FinalFormCards(finalFormCardsAddress).totalSupply() - 1;
		uint256 totalSupplyRange = FinalFormCards(finalFormCardsAddress).totalSupply();
//		console.log(
//			"totalSupplyRange:",
//			totalSupplyRange
//		);
		uint256[4] memory cardIndexes = [
			uint(blockhash(block.number - 1)) % totalSupplyRange,
			uint(blockhash(block.number - 2)) % totalSupplyRange,
			uint(blockhash(block.number - 3)) % totalSupplyRange,
			uint(blockhash(block.number - 4)) % totalSupplyRange
		];
//		console.log(
//			"cardIndexes: %s",
//			cardIndexes
//		);

		// get the token ids of the randomly chosen cards
		uint256[4] memory tokenIds = FinalFormCards(finalFormCardsAddress).tokensByIndexes([cardIndexes[0], cardIndexes[1], cardIndexes[2], cardIndexes[3]]);
//		console.log(
//			"tokenIds: %s",
//			tokenIds
//		);

		data.nextBattleConfig[msg.sender].enemyCards[0].isCard = true;
		data.nextBattleConfig[msg.sender].enemyCards[0].id = tokenIds[0];
		data.nextBattleConfig[msg.sender].enemyCards[1].isCard = true;
		data.nextBattleConfig[msg.sender].enemyCards[1].id = tokenIds[1];
		data.nextBattleConfig[msg.sender].enemyCards[2].isCard = true;
		data.nextBattleConfig[msg.sender].enemyCards[2].id = tokenIds[2];
		data.nextBattleConfig[msg.sender].enemyCards[3].isCard = true;
		data.nextBattleConfig[msg.sender].enemyCards[3].id = tokenIds[3];

		// check for duplicate cards
		uint8[] memory hirelingRarities = new uint8[](6);
		uint8[] memory hirelingHouses = new uint8[](6);

		if (cardIndexes[0] == cardIndexes[1]) {
			hirelingRarities[0] = uint8(uint(blockhash(block.number - 5)) % 4); // 0 - 3
			hirelingHouses[0] = uint8(uint(blockhash(block.number - 6)) % 4); // 0 - 3
			data.nextBattleConfig[msg.sender].enemyCards[1].isCard = false;
			data.nextBattleConfig[msg.sender].enemyCards[1].id = ((uint(blockhash(block.number - 7)) % data.hirelingPool[hirelingRarities[0]][hirelingHouses[0]].length) * 10000) + (hirelingHouses[0] * 100) + hirelingRarities[0];
		}

		if (cardIndexes[0] == cardIndexes[2]) {
			hirelingRarities[1] = uint8(uint(blockhash(block.number - 8)) % 4); // 0 - 3
			hirelingHouses[1] = uint8(uint(blockhash(block.number - 9)) % 4); // 0 - 3
			data.nextBattleConfig[msg.sender].enemyCards[2].isCard = false;
			data.nextBattleConfig[msg.sender].enemyCards[2].id = ((uint(blockhash(block.number - 10)) % data.hirelingPool[hirelingRarities[1]][hirelingHouses[1]].length) * 10000) + (hirelingHouses[1] * 100) + hirelingRarities[1];
		}

		if (cardIndexes[0] == cardIndexes[3]) {
			hirelingRarities[2] = uint8(uint(blockhash(block.number - 11)) % 4); // 0 - 3
			hirelingHouses[2] = uint8(uint(blockhash(block.number - 12)) % 4); // 0 - 3
			data.nextBattleConfig[msg.sender].enemyCards[3].isCard = false;
			data.nextBattleConfig[msg.sender].enemyCards[3].id = ((uint(blockhash(block.number - 13)) % data.hirelingPool[hirelingRarities[2]][hirelingHouses[2]].length) * 10000) + (hirelingHouses[2] * 100) + hirelingRarities[2];
		}

		if (cardIndexes[1] == cardIndexes[2]) {
			hirelingRarities[3] = uint8(uint(blockhash(block.number - 14)) % 4); // 0 - 3
			hirelingHouses[3] = uint8(uint(blockhash(block.number - 15)) % 4); // 0 - 3
			data.nextBattleConfig[msg.sender].enemyCards[2].isCard = false;
			data.nextBattleConfig[msg.sender].enemyCards[2].id = ((uint(blockhash(block.number - 16)) % data.hirelingPool[hirelingRarities[3]][hirelingHouses[3]].length) * 10000) + (hirelingHouses[3] * 100) + hirelingRarities[3];
		}

		if (cardIndexes[1] == cardIndexes[3]) {
			hirelingRarities[4] = uint8(uint(blockhash(block.number - 17)) % 4); // 0 - 3
			hirelingHouses[4] = uint8(uint(blockhash(block.number - 18)) % 4); // 0 - 3
			data.nextBattleConfig[msg.sender].enemyCards[3].isCard = false;
			data.nextBattleConfig[msg.sender].enemyCards[3].id = ((uint(blockhash(block.number - 19)) % data.hirelingPool[hirelingRarities[4]][hirelingHouses[4]].length) * 10000) + (hirelingHouses[4] * 100) + hirelingRarities[4];
		}

		if (cardIndexes[2] == cardIndexes[3]) {
			hirelingRarities[5] = uint8(uint(blockhash(block.number - 20)) % 4); // 0 - 3
			hirelingHouses[5] = uint8(uint(blockhash(block.number - 21)) % 4); // 0 - 3
			data.nextBattleConfig[msg.sender].enemyCards[3].isCard = false;
			data.nextBattleConfig[msg.sender].enemyCards[3].id = ((uint(blockhash(block.number - 22)) % data.hirelingPool[hirelingRarities[5]][hirelingHouses[5]].length) * 10000) + (hirelingHouses[5] * 100) + hirelingRarities[5];
		}

		// get the available hirelings and free common hireling houses
		(uint256[4][4] memory availableHirelings, uint8[2] memory freeCommonHouses) = generateHirelings(data);
		bool[4][4] memory purchasedHirelings;

		// save all other data for the user's prepped battle
		data.nextBattleConfig[msg.sender].availableHirelings = availableHirelings;
		data.nextBattleConfig[msg.sender].purchasedHirelings = purchasedHirelings;
		data.nextBattleConfig[msg.sender].freeCommonHouses = freeCommonHouses;
		data.nextBattleConfig[msg.sender].ready = true;
		data.nextBattleConfig[msg.sender].claimedAnyHireling = false;

//		data.nextBattleConfig[msg.sender] = Battle.BattlePrepConfig({
//			enemyCards: cardIndexes,
//			availableHirelings: availableHirelings,
//			purchasedHirelings: purchasedHirelings,
//			freeCommonHouses: freeCommonHouses,
//			ready: true,
//			claimedAnyHireling: false
//		});
	}

	function generateHirelings(Battle.ContractData storage data) public view returns (uint256[4][4] memory availableHirelings, uint8[2] memory freeCommonHouses) {
		uint8 free1 = uint8(uint(blockhash(block.number - 17)) % 4);
		uint8 free2 = uint8(uint(blockhash(block.number - 18)) % 4);
		if (free1 == free2) {
			if (free1 == 3) {
				free2--;
			} else {
				free2++;
			}
		}

		return (
			[
				// Commons
				[
					uint(blockhash(block.number - 1)) % data.hirelingPool[0][0].length,
					uint(blockhash(block.number - 2)) % data.hirelingPool[0][1].length,
					uint(blockhash(block.number - 3)) % data.hirelingPool[0][2].length,
					uint(blockhash(block.number - 4)) % data.hirelingPool[0][3].length
				],
				// Rares
				[
					uint(blockhash(block.number - 5)) % data.hirelingPool[1][0].length,
					uint(blockhash(block.number - 6)) % data.hirelingPool[1][1].length,
					uint(blockhash(block.number - 7)) % data.hirelingPool[1][2].length,
					uint(blockhash(block.number - 8)) % data.hirelingPool[1][3].length
				],
				// Epics
				[
					uint(blockhash(block.number - 9)) % data.hirelingPool[2][0].length,
					uint(blockhash(block.number - 10)) % data.hirelingPool[2][1].length,
					uint(blockhash(block.number - 11)) % data.hirelingPool[2][2].length,
					uint(blockhash(block.number - 12)) % data.hirelingPool[2][3].length
				],
				// Legendaries
				[
					uint(blockhash(block.number - 13)) % data.hirelingPool[3][0].length,
					uint(blockhash(block.number - 14)) % data.hirelingPool[3][1].length,
					uint(blockhash(block.number - 15)) % data.hirelingPool[3][2].length,
					uint(blockhash(block.number - 16)) % data.hirelingPool[3][3].length
				]
			],
			[
//				uint8(uint(blockhash(block.number - 17)) % 4),
//				uint8(uint(blockhash(block.number - 18)) % 4)
				free1,
				free2
			]
		);
	}

	function requestNewHirelingsDraw(Battle.ContractData storage data) external {
		require(data.nextBattleConfig[msg.sender].ready, "10");
		require(!data.nextBattleConfig[msg.sender].claimedAnyHireling, "11");

		// get the available hirelings and free common hireling houses
		(uint256[4][4] memory availableHirelings, uint8[2] memory freeCommonHouses) = generateHirelings(data);

		data.nextBattleConfig[msg.sender].availableHirelings = availableHirelings;
		data.nextBattleConfig[msg.sender].freeCommonHouses = freeCommonHouses;
		delete data.nextBattleConfig[msg.sender].purchasedHirelings;
	}

	function getHirelingsFromConfig(Battle.ContractData storage data) external view returns (Battle.Hireling[] memory hirelings, bool[] memory purchases) {
		require(data.nextBattleConfig[msg.sender].ready, "12");

		Battle.Hireling[] memory hirelings = new Battle.Hireling[](16);
		bool[] memory purchases = new bool[](16);

		uint256[4][4] memory availableHirelingIndexes = data.nextBattleConfig[msg.sender].availableHirelings;
		bool[4][4] memory purchasedHirelingIndexes = data.nextBattleConfig[msg.sender].purchasedHirelings;

		uint8 a;
		for (a = 0; a < 4; a++) {
			hirelings[a] = data.hirelingPool[0][a][availableHirelingIndexes[0][a]];
			purchases[a] = purchasedHirelingIndexes[0][a];
		}

		uint8 b;
		for (b; b < 4; b++) {
			hirelings[a + b] = data.hirelingPool[1][b][availableHirelingIndexes[1][b]];
			purchases[a + b] = purchasedHirelingIndexes[1][b];
		}

		uint8 c;
		for (c; c < 4; c++) {
			hirelings[a + b + c] = data.hirelingPool[2][c][availableHirelingIndexes[2][c]];
			purchases[a + b + c] = purchasedHirelingIndexes[2][c];
		}

		uint8 d;
		for (d; d < 4; d++) {
			hirelings[a + b + c + d] = data.hirelingPool[3][d][availableHirelingIndexes[3][d]];
			purchases[a + b + c + d] = purchasedHirelingIndexes[3][d];
		}

		return (hirelings, purchases);
	}

	function getOwnedHirelingsIndexes(address wallet, Battle.ContractData storage data) external view returns (uint256[][4][4] memory hirelingIndexes) {
//		uint256[][][] memory indexes;
//
//		indexes[0][0] = data.userHirelingsLists[msg.sender][0][0];
//		indexes[0][1] = data.userHirelingsLists[msg.sender][0][1];
//		indexes[0][2] = data.userHirelingsLists[msg.sender][0][2];
//		indexes[0][3] = data.userHirelingsLists[msg.sender][0][3];
//
//		indexes[1][0] = data.userHirelingsLists[msg.sender][1][0];
//		indexes[1][1] = data.userHirelingsLists[msg.sender][1][1];
//		indexes[1][2] = data.userHirelingsLists[msg.sender][1][2];
//		indexes[1][3] = data.userHirelingsLists[msg.sender][1][3];
//
//		indexes[2][0] = data.userHirelingsLists[msg.sender][2][0];
//		indexes[2][1] = data.userHirelingsLists[msg.sender][2][1];
//		indexes[2][2] = data.userHirelingsLists[msg.sender][2][2];
//		indexes[2][3] = data.userHirelingsLists[msg.sender][2][3];
//
//		indexes[3][0] = data.userHirelingsLists[msg.sender][3][0];
//		indexes[3][1] = data.userHirelingsLists[msg.sender][3][1];
//		indexes[3][2] = data.userHirelingsLists[msg.sender][3][2];
//		indexes[3][3] = data.userHirelingsLists[msg.sender][3][3];
//
//		return indexes;

		//-----//

		return (
			[
				[
					data.userHirelingsLists[wallet][0][0],
					data.userHirelingsLists[wallet][0][1],
					data.userHirelingsLists[wallet][0][2],
					data.userHirelingsLists[wallet][0][3]
				],
				[
					data.userHirelingsLists[wallet][1][0],
					data.userHirelingsLists[wallet][1][1],
					data.userHirelingsLists[wallet][1][2],
					data.userHirelingsLists[wallet][1][3]
				],
				[
					data.userHirelingsLists[wallet][2][0],
					data.userHirelingsLists[wallet][2][1],
					data.userHirelingsLists[wallet][2][2],
					data.userHirelingsLists[wallet][2][3]
				],
				[
					data.userHirelingsLists[wallet][3][0],
					data.userHirelingsLists[wallet][3][1],
					data.userHirelingsLists[wallet][3][2],
					data.userHirelingsLists[wallet][3][3]
				]
			]
		);
	}

	function getHirelings(uint8 rarity, uint8 house, uint256[] calldata indexes, Battle.ContractData storage data) external view returns (Battle.Hireling[] memory hirelings) {
		require(rarity <= 3, "15");
		require(house <= 3, "16");

		Battle.Hireling[] memory hirelings = new Battle.Hireling[](indexes.length);

		for (uint256 i; i < indexes.length; i++) {
			hirelings[i] = data.hirelingPool[rarity][house][indexes[i]];
		}

		return hirelings;
	}
}

interface IBattle {
//	struct Hireling {
//		uint8 rarity;
//		uint8 house;
//		uint256 index;
//		uint256 power;
//		uint256 hp;
//		uint256 attack;
//		uint256 ability1;
//		uint256 ability2;
//		uint256 ability3;
//		bool initialized;
//	}
//
//	struct CardOrHireling {
//		bool isCard;
//		uint256 id;
//	}
//
//	struct BattlePrepConfig {
//		uint256[4] enemyCards; // Adversary card indexes.
//		uint256[4][4] availableHirelings; // Token indexes of hirelings by house by rarity.
//		bool[4][4] purchasedHirelings; // Track if user has purchased hirelings by house by rarity.
//		uint8[2] freeCommonHouses; // Represents which 2 houses of the randomly generated commons hirelings are free for this draw. Example: if freeCommonHouses[0] == 3, then availableHirelings[0][3] is free.
//		bool ready; // Gets marked as true when the config is prepared for the user's upcoming battle; if true then config is saved, if false then user has no battle config prepped and must do so before attempting to battle.
//		bool claimedAnyHireling; // A flag so we know if the user is allowed to "re-roll" the hireling list for their "current" battle.
//	}
//
//	struct BattleHistory {
//		bool initialized;
//		bool result;
//		uint256[3][4] deck;
//		uint256[3][4] enemyDeck;
//	}
//
//	struct TurnData {
//		bool removeMeImJustHereSoTheCodeCompiles;
//	}
//
//	struct BattleData {
//		mapping(address => BattlePrepConfig) nextBattleConfig;
//		mapping(uint256 => BattleData) battleDataMap;
//		mapping(uint256 => TurnData[]) turnDataMap;
//	}
//
//	struct HirelingData {
//		mapping(uint8 => mapping(uint8 => Hireling[])) hirelingPool; // Map rarities => houses => hireling pool
//		mapping(address => mapping(uint8 => mapping(uint8 => uint256[]))) userHirelingsLists; // Map wallets => hireling rarities => hireling houses => index in associated hirelingPool
//		mapping(address => mapping(uint8 => mapping(uint8 => mapping(uint256 => uint256)))) userHirelingsOwnershipLookup; // wallet => rarities => house => index => number owned of that hireling
//	}
//
//	event PreparedBattle(address user);
//
//	event ReRolledHirelings(address user);
//
//	event Battle(uint256 id, bool result, address user);

//    function updateHirelingPrice(uint8 rarity, uint256 price) external;

//    function getHirelingPrices() external view returns (uint256[4] calldata prices);

//    function setHirelingData(uint8 rarity, Hireling[] calldata metadata) external;

//    function purchaseHireling(uint8 rarity, uint8 house, uint256 tokenIndex) external payable;

//    function withdrawBalance() external;

//    function prepareBattle() external;

//    function getBattleConfig(address wallet) external view returns (BattlePrepConfig memory config);

//    function getOwnedHirelingsIndexes() external returns (uint256[][][] memory hirelingIndexes);

//    function getAllOwnedHirelings() external returns (Hireling[] memory hirelings);

//    function getHirelings(uint8 rarity, uint8 house, uint256[] calldata indexes) external view returns (Hireling[] memory hirelings);

//    function battle(CardOrHireling[4] calldata deckIds, CardOrHireling[4] calldata enemyDeckIds) external;

//    function battle(uint256[4] calldata deckIds, uint256[4] calldata enemyDeckIds) external returns (uint256[3][4] memory deck, uint256[3][4] memory enemyDeck);

//    function lookup(uint256 battleId) external view returns (BattleData memory battle, TurnData[] memory turns);

//    function test(uint256 one, uint256 two) external view returns (uint256);
}

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IChromos is IERC20 {
    function mint(uint256 amount, address to) external;
    function burn(uint256 amount, address from) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../mint_info/IMintInfoOracle.sol";
import "../chromos/IChromos.sol";
import "./IFinalFormCards.sol";

// Error Messages
// 1: You don't have authority to burn this card
// 2: Can't burn a card you don't own
// 3: Card is not legendary

contract FinalFormCards is IFinalFormCards, AccessControl, ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable {

    bytes32 public constant ADMIN_AUTH = keccak256("ADMIN_AUTH");

    // used to assign a unique tokenId
    using Counters for Counters.Counter;
    Counters.Counter private _counter;

    string private _baseURIInternal;
    address private _mintOracleAddress;
    address private _chromosAddress;
    address _ironPigeonsRoyaltyReceiver;
    uint96 _ironPigeonsRoyaltyFeeNumerator;
    uint256 private _legendaryBurnReward;

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseUri_,
        address mintOracleAddress_,
        address chromosAddress_,
        address admin_,
        address defaultRoyaltyReceiver,
        uint96 defaultRoyaltyFeeNumerator,
        address ironPigeonsRoyaltyReceiver,
        uint96 ironPigeonsRoyaltyFeeNumerator,
        uint256 legendaryBurnReward
    ) initializer public {
        __ERC721_init(name_, symbol_);
        __ERC2981_init();
        _baseURIInternal = baseUri_;
        _mintOracleAddress = mintOracleAddress_;
        _chromosAddress = chromosAddress_;
        _ironPigeonsRoyaltyReceiver = ironPigeonsRoyaltyReceiver;
        _ironPigeonsRoyaltyFeeNumerator = ironPigeonsRoyaltyFeeNumerator;
        _legendaryBurnReward = legendaryBurnReward;

        _setupRole(ADMIN_AUTH, admin_);
        _setRoleAdmin(ADMIN_AUTH, ADMIN_AUTH);
        _setDefaultRoyalty(defaultRoyaltyReceiver, defaultRoyaltyFeeNumerator);

    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIInternal;
    }

    function mint(address to, string calldata tokenUri, IMintInfoOracle.MintInfo memory metadata) external virtual returns (uint256) {

        // get current count to ensure uniqueness
        uint256 currentTokenId = _counter.current();

        // mint the nft to the address
        _safeMint(to, currentTokenId);

        // set the token URI
        _setTokenURI(currentTokenId, tokenUri);

        // increment the counter
        _counter.increment();

        // add to the oracle
        IMintInfoOracle(_mintOracleAddress).setMintInfo(address(this), currentTokenId, metadata);

        // add the royalty override for iron pigeons
        if (metadata.set == 2) {
            _setTokenRoyalty(currentTokenId, _ironPigeonsRoyaltyReceiver, _ironPigeonsRoyaltyFeeNumerator);
        }

        return currentTokenId;
    }

    function exists(uint256 id) external view virtual returns (bool) {
        return _exists(id);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721EnumerableUpgradeable, ERC721Upgradeable) {
        ERC721EnumerableUpgradeable._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @dev See {ERC721-_burn}.
	 */
    function _burn(uint256 tokenId) internal virtual override(ERC721URIStorageUpgradeable, ERC721Upgradeable) {
        ERC721URIStorageUpgradeable._burn(tokenId);
    }

    function burnForEvolution(uint256 tokenId) external {
        require(
            _ownerOf(tokenId) == tx.origin,
        //            && msg.sender == _evolutionAddress,
            "1"
        );

        _burn(tokenId);
    }

    function setLegendaryBurnReward(uint256 reward) external onlyRole(ADMIN_AUTH) {
        _legendaryBurnReward = reward;
    }

    function getLegendaryBurnReward() external view returns (uint256) {
        return _legendaryBurnReward;
    }

    function burnLegendary(uint256 tokenId) external {
        require(_ownerOf(tokenId) == msg.sender, "2");

        (uint8 rarity, , ,) = IMintInfoOracle(_mintOracleAddress).getMintInfo(address(this), tokenId);
        require(rarity == 3, "3");

        _burn(tokenId);
        IChromos(_chromosAddress).mint(_legendaryBurnReward, msg.sender);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
	 */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (string memory) {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

	/**
 	 * Get multiple token ids via their indexes.
     */
	function tokensByIndexes(uint256[4] calldata indexes) external view returns (uint256[4] memory tokenIds) {
        return [
            tokenByIndex(indexes[0]),
            tokenByIndex(indexes[1]),
            tokenByIndex(indexes[2]),
            tokenByIndex(indexes[3])
        ];
	}

    /**
     * @dev See {IERC165-supportsInterface}.
	 */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721EnumerableUpgradeable, ERC721Upgradeable, ERC2981Upgradeable) returns (bool) {
        return ERC721EnumerableUpgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC2981Upgradeable-_setDefaultRoyalty}.
	 */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(ADMIN_AUTH) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Will change the royalties for any new iron pigeons being minted
	 */
    function setNewIronPigeonRoyalties(address receiver, uint96 feeNumerator) external onlyRole(ADMIN_AUTH) {
        _ironPigeonsRoyaltyReceiver = receiver;
        _ironPigeonsRoyaltyFeeNumerator = feeNumerator;
    }

    /**
     * @dev See {ERC2981Upgradeable-_setTokenRoyalty}.
	 */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyRole(ADMIN_AUTH) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981Upgradeable-_resetTokenRoyalty}.
	 */
    function resetTokenRoyalty(uint256 tokenId) external onlyRole(ADMIN_AUTH) {
        _resetTokenRoyalty(tokenId);
    }

    function _msgSender() internal view override(Context, ContextUpgradeable) returns (address sender) {
        return Context._msgSender();
    }

    function _msgData() internal view override(Context, ContextUpgradeable) returns (bytes calldata) {
        return Context._msgData();
    }
}

import "../mint_info/IMintInfoOracle.sol";

interface IFinalFormCards {
    function mint(address to, string calldata tokenUri, IMintInfoOracle.MintInfo memory metadata) external virtual returns(uint256);

    function exists(uint256 id) external view virtual returns(bool);

    function burnForEvolution(uint256 tokenId) external;

    function setLegendaryBurnReward(uint256 reward) external;

    function getLegendaryBurnReward() external view returns (uint256);

    function burnLegendary(uint256 tokenId) external;

    function tokensByIndexes(uint256[4] calldata indexes) external view returns (uint256[4] calldata tokenIds);
}

interface IMintInfoOracle {
    struct MintInfo {
        uint8 rarity;
        uint8 house;
        uint8 set;
        uint256 power;
        uint256 hp;
        uint256 attack;
        uint256 ability1;
        uint256 ability2;
        uint256 ability3;
        bool initialized;
    }

    function addCollection(address collection) external;

    function checkCollection(address collection) external view returns (bool);

    function setMintInfo(address collection, uint256 nftID, MintInfo memory metadata) external;

    function getMintInfo(address collection, uint256 nftID) external view returns (uint8, uint8, uint8, uint256);

    function getMintInfos(address[] memory collections, uint256[] memory nftIDs) external view returns (uint8[] memory rarities, uint8[] memory houses, uint8[] memory sets);

    function getCardDataArray(address collection, uint256[] calldata cardIds) external view returns (MintInfo[] memory cards);

    function getDeckBattleData(address collection, uint256[4] calldata deckIds, uint256[4] calldata enemyDeckIds) external view returns (uint256[3][4] memory deck, uint256[3][4] memory enemyDeck);
}

interface IPledging {
    function setRewardsConfig(uint8 rarity, uint256 rewards) external;

    function pledgeNFT(address[] memory collections, uint256[] memory nftIDs) external;

    function unPledgeNFT(address[] memory collections, uint256[] memory nftIDs) external;

    function checkOwnerOfPledgedCard(address collection, uint256 nftId) external view returns (address);

    function verifyPledgedCardsOwnership(address collection, address owner, uint256[4] calldata cardIds) external view returns (bool);

    function claimRewards() external;

    function getClaimableAmount(address owner) external view returns (uint256);

    function getUserPledgedRarityCounts(address user) external view returns (uint256, uint256, uint256);
}