// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrowerUpgradeable {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "IERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrowerUpgradeable.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLenderUpgradeable {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrowerUpgradeable receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2Upgradeable {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.15;

import {Base64} from "base64-sol/base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {HexStrings} from "@uni-periphery/libraries/HexStrings.sol";

contract InventoryStakingDescriptor {
    using Strings for uint256;
    using HexStrings for uint256;

    // =============================================================
    //                        CONSTANTS
    // =============================================================

    string internal constant PREFIX = "x";

    // =============================================================
    //                        INTERNAL
    // =============================================================

    function renderSVG(
        uint256 tokenId,
        uint256 vaultId,
        address vToken,
        string calldata vTokenSymbol,
        uint256 vTokenBalance,
        uint256 wethBalance,
        uint256 timelockLeft
    ) public pure returns (string memory) {
        return
            string.concat(
                '<svg width="290" height="500" viewBox="0 0 290 500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                getDefs(
                    tokenToColorHex(uint256(uint160(vToken)), 136),
                    tokenToColorHex(uint256(uint160(vToken)), 100)
                ),
                '<g mask="url(#fade-symbol)">',
                text("32", "70", "200", "32"),
                PREFIX,
                vTokenSymbol,
                "</text>",
                underlyingBalances(vTokenSymbol, vTokenBalance, wethBalance),
                '<rect x="16" y="16" width="258" height="468" rx="26" ry="26" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)"/>',
                infoTags(tokenId, vaultId, timelockLeft),
                "</svg>"
            );
    }

    function tokenURI(
        uint256 tokenId,
        uint256 vaultId,
        address vToken,
        string calldata vTokenSymbol,
        uint256 vTokenBalance,
        uint256 wethBalance,
        uint256 timelockedUntil
    ) external view returns (string memory) {
        string memory image = Base64.encode(
            bytes(
                renderSVG(
                    tokenId,
                    vaultId,
                    vToken,
                    vTokenSymbol,
                    vTokenBalance,
                    wethBalance,
                    block.timestamp > timelockedUntil
                        ? 0
                        : timelockedUntil - block.timestamp
                )
            )
        );

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string.concat(
                            '{"name":"',
                            string.concat(
                                "x",
                                vTokenSymbol,
                                " #",
                                tokenId.toString()
                            ),
                            '", "description":"',
                            "xNFT representing inventory staking position on NFTX",
                            '", "image": "',
                            "data:image/svg+xml;base64,",
                            image,
                            '", "attributes": [{"trait_type": "VaultId", "value": "',
                            vaultId.toString(),
                            '"}]}'
                        )
                    )
                )
            );
    }

    // =============================================================
    //                        PRIVATE
    // =============================================================

    function getDefs(
        string memory color2,
        string memory color3
    ) private pure returns (string memory) {
        return
            string.concat(
                "<defs>",
                '<filter id="f1"><feImage result="p2" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        string.concat(
                            "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='16' cy='232' r='120px' fill='#",
                            color2,
                            "'/></svg>"
                        )
                    )
                ),
                '"/><feImage result="p3" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        string.concat(
                            "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='20' cy='100' r='130px' fill='#",
                            color3,
                            "'/></svg>"
                        )
                    )
                ),
                '"/><feBlend mode="exclusion" in2="p2"/><feBlend mode="overlay" in2="p3" result="blendOut"/><feGaussianBlur in="blendOut" stdDeviation="42"/></filter><clipPath id="corners"><rect width="290" height="500" rx="42" ry="42"/></clipPath><filter id="top-region-blur"><feGaussianBlur in="SourceGraphic" stdDeviation="24"/></filter><linearGradient id="grad-symbol"><stop offset="0.7" stop-color="white" stop-opacity="1"/><stop offset=".95" stop-color="white" stop-opacity="0"/></linearGradient><mask id="fade-symbol" maskContentUnits="userSpaceOnUse"><rect width="290px" height="200px" fill="url(#grad-symbol)"/></mask></defs>',
                '<g clip-path="url(#corners)"><rect fill="2c9715" x="0px" y="0px" width="290px" height="500px"/><rect style="filter: url(#f1)" x="0px" y="0px" width="290px" height="500px"/><g style="filter:url(#top-region-blur); transform:scale(1.5); transform-origin:center top;"><rect fill="none" x="0px" y="0px" width="290px" height="500px"/><ellipse cx="50%" cy="0px" rx="180px" ry="120px" fill="#000" opacity="0.85"/></g><rect x="0" y="0" width="290" height="500" rx="42" ry="42" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)"/></g>'
            );
    }

    function text(
        string memory x,
        string memory y,
        string memory fontWeight,
        string memory fontSize
    ) private pure returns (string memory) {
        return text(x, y, fontWeight, fontSize, false);
    }

    function text(
        string memory x,
        string memory y,
        string memory fontWeight,
        string memory fontSize,
        bool onlyMonospace
    ) private pure returns (string memory) {
        return
            string.concat(
                '<text y="',
                y,
                'px" x="',
                x,
                'px" fill="white" font-family="',
                !onlyMonospace ? "'Courier New', " : "",
                'monospace" font-weight="',
                fontWeight,
                '" font-size="',
                fontSize,
                'px">'
            );
    }

    function tokenToColorHex(
        uint256 token,
        uint256 offset
    ) private pure returns (string memory str) {
        return string((token >> offset).toHexStringNoPrefix(3));
    }

    function balanceTag(
        string memory y,
        uint256 tokenBalance,
        string memory tokenSymbol
    ) private pure returns (string memory) {
        uint256 beforeDecimal = tokenBalance / 1 ether;
        string memory afterDecimals = getAfterDecimals(tokenBalance);

        uint256 leftPadding = 12;
        uint256 beforeDecimalFontSize = 20;
        uint256 afterDecimalFontSize = 16;

        uint256 width = leftPadding +
            ((getDigitsCount(beforeDecimal) + 1) * beforeDecimalFontSize) /
            2 +
            (bytes(afterDecimals).length * afterDecimalFontSize * 100) /
            100;

        return
            string.concat(
                '<g style="transform:translate(29px, ',
                y,
                'px)"><rect width="',
                width.toString(),
                'px" height="30px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)"/>',
                text(
                    leftPadding.toString(),
                    "21",
                    "100",
                    beforeDecimalFontSize.toString(),
                    true
                ),
                beforeDecimal.toString(),
                '.<tspan font-size="',
                afterDecimalFontSize.toString(),
                'px">',
                afterDecimals,
                '</tspan> <tspan fill="rgba(255,255,255,0.8)">',
                tokenSymbol,
                "</tspan></text></g>"
            );
    }

    function infoTag(
        string memory y,
        string memory label,
        string memory value
    ) private pure returns (string memory) {
        return
            string.concat(
                '<g style="transform:translate(29px, ',
                y,
                'px)"><rect width="98px" height="26px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)"/>',
                text("12", "17", "100", "12"),
                '<tspan fill="rgba(255,255,255,0.6)">',
                label,
                ": </tspan>",
                value,
                "</text></g>"
            );
    }

    function underlyingBalances(
        string memory vTokenSymbol,
        uint256 vTokenBalance,
        uint256 wethBalance
    ) private pure returns (string memory) {
        return
            string.concat(
                text("32", "160", "200", "16"),
                "Underlying Balance</text></g>",
                balanceTag("180", vTokenBalance, vTokenSymbol),
                balanceTag("220", wethBalance, "WETH")
            );
    }

    function infoTags(
        uint256 tokenId,
        uint256 vaultId,
        uint256 timelockLeft
    ) private pure returns (string memory) {
        return
            string.concat(
                infoTag("384", "ID", tokenId.toString()),
                infoTag("414", "VaultId", vaultId.toString()),
                infoTag(
                    "444",
                    "Timelock",
                    timelockLeft > 0
                        ? string.concat(timelockLeft.toString(), "s left")
                        : "Unlocked"
                )
            );
    }

    function getDigitsCount(uint256 num) private pure returns (uint256 count) {
        if (num == 0) return 1;

        while (num > 0) {
            ++count;
            num /= 10;
        }
    }

    function getAfterDecimals(
        uint256 tokenBalance
    ) private pure returns (string memory afterDecimals) {
        uint256 afterDecimal = (tokenBalance % 1 ether) / 10 ** (18 - 10); // show 10 decimals

        uint256 leadingZeroes;
        if (afterDecimal == 0) {
            leadingZeroes = 0;
        } else {
            leadingZeroes = 10 - getDigitsCount(afterDecimal);
        }

        afterDecimals = afterDecimal.toString();
        for (uint256 i; i < leadingZeroes; ) {
            afterDecimals = string.concat("0", afterDecimals);

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);

    function upgradeBeaconTo(address newImplementation) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/ERC20FlashMint.sol)

pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@src/custom/tokens/ERC20/ERC20Upgradeable.sol";
import {IERC3156FlashLenderUpgradeable} from "@openzeppelin-upgradeable/contracts/interfaces/IERC3156FlashLenderUpgradeable.sol";
import {IERC3156FlashBorrowerUpgradeable} from "@openzeppelin-upgradeable/contracts/interfaces/IERC3156FlashBorrowerUpgradeable.sol";

/**
 * NOTE: #NFTX: Forked from OZ, to use custom ERC20Upgradeable which includes `setMetadata()`
 *
 *
 * @dev Implementation of the ERC3156 Flash loans extension, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * Adds the {flashLoan} method, which provides flash loan support at the token
 * level. By default there is no fee, but this can be changed by overriding {flashFee}.
 *
 * _Available since v4.1._
 */
abstract contract ERC20FlashMintUpgradeable is
    Initializable,
    ERC20Upgradeable,
    IERC3156FlashLenderUpgradeable
{
    // Errors
    error WrongToken();
    error AmountExceedsMaxFlashLoan();
    error InvalidReturnValue();

    function __ERC20FlashMint_init() internal onlyInitializing {}

    function __ERC20FlashMint_init_unchained() internal onlyInitializing {}

    bytes32 private constant _RETURN_VALUE =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

    /**
     * @dev Returns the maximum amount of tokens available for loan.
     * @param token The address of the token that is requested.
     * @return The amount of token that can be loaned.
     */
    function maxFlashLoan(
        address token
    ) public view virtual override returns (uint256) {
        return
            token == address(this)
                ? type(uint256).max - ERC20Upgradeable.totalSupply()
                : 0;
    }

    /**
     * @dev Returns the fee applied when doing flash loans. This function calls
     * the {_flashFee} function which returns the fee applied when doing flash
     * loans.
     * @param token The token to be flash loaned.
     * @param amount The amount of tokens to be loaned.
     * @return The fees applied to the corresponding flash loan.
     */
    function flashFee(
        address token,
        uint256 amount
    ) public view virtual override returns (uint256) {
        if (token != address(this)) revert WrongToken();
        return _flashFee(token, amount);
    }

    /**
     * @dev Returns the fee applied when doing flash loans. By default this
     * implementation has 0 fees. This function can be overloaded to make
     * the flash loan mechanism deflationary.
     * @param token The token to be flash loaned.
     * @param amount The amount of tokens to be loaned.
     * @return The fees applied to the corresponding flash loan.
     */
    function _flashFee(
        address token,
        uint256 amount
    ) internal view virtual returns (uint256) {
        // silence warning about unused variable without the addition of bytecode.
        token;
        amount;
        return 0;
    }

    /**
     * @dev Returns the receiver address of the flash fee. By default this
     * implementation returns the address(0) which means the fee amount will be burnt.
     * This function can be overloaded to change the fee receiver.
     * @return The address for which the flash fee will be sent to.
     */
    function _flashFeeReceiver() internal view virtual returns (address) {
        return address(0);
    }

    /**
     * @dev Performs a flash loan. New tokens are minted and sent to the
     * `receiver`, who is required to implement the {IERC3156FlashBorrower}
     * interface. By the end of the flash loan, the receiver is expected to own
     * amount + fee tokens and have them approved back to the token contract itself so
     * they can be burned.
     * @param receiver The receiver of the flash loan. Should implement the
     * {IERC3156FlashBorrower-onFlashLoan} interface.
     * @param token The token to be flash loaned. Only `address(this)` is
     * supported.
     * @param amount The amount of tokens to be loaned.
     * @param data An arbitrary datafield that is passed to the receiver.
     * @return `true` if the flash loan was successful.
     */
    // This function can reenter, but it doesn't pose a risk because it always preserves the property that the amount
    // minted at the beginning is always recovered and burned at the end, or else the entire function will revert.
    // slither-disable-next-line reentrancy-no-eth
    function flashLoan(
        IERC3156FlashBorrowerUpgradeable receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) public virtual override returns (bool) {
        if (amount > maxFlashLoan(token)) revert AmountExceedsMaxFlashLoan();
        uint256 fee = flashFee(token, amount);
        _mint(address(receiver), amount);

        if (
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) !=
            _RETURN_VALUE
        ) revert InvalidReturnValue();

        address flashFeeReceiver = _flashFeeReceiver();
        _spendAllowance(address(receiver), address(this), amount + fee);
        if (fee == 0 || flashFeeReceiver == address(0)) {
            _burn(address(receiver), amount + fee);
        } else {
            _burn(address(receiver), amount);
            _transfer(address(receiver), flashFeeReceiver, fee);
        }
        return true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {IERC20Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/ContextUpgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * NOTE: #NFTX: Forked from OZ, to add `setMetadata()`
 *
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
contract ERC20Upgradeable is
    Initializable,
    ContextUpgradeable,
    IERC20Upgradeable,
    IERC20MetadataUpgradeable
{
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    event MetadataUpdated(string name, string symbol);

    error DecreasedAllowanceBelowZero();
    error TransferFromZeroAddress();
    error TransferToZeroAddress();
    error TransferAmountExceedsBalance();
    error MintToZeroAddress();
    error BurnFromZeroAddress();
    error BurnAmountExceedsBalance();
    error ApproveFromZeroAddress();
    error ApproveToZeroAddress();
    error InsufficientAllowance();

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    function _setMetadata(string memory name_, string memory symbol_) internal {
        _name = name_;
        _symbol = symbol_;

        emit MetadataUpdated(name_, symbol_);
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
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
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
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
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
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < subtractedValue)
            revert DecreasedAllowanceBelowZero();
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
        if (from == address(0)) revert TransferFromZeroAddress();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) revert TransferAmountExceedsBalance();
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
        if (account == address(0)) revert MintToZeroAddress();

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
        if (account == address(0)) revert BurnFromZeroAddress();

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        if (accountBalance < amount) revert BurnAmountExceedsBalance();
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
        if (owner == address(0)) revert ApproveFromZeroAddress();
        if (spender == address(0)) revert ApproveToZeroAddress();

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
            if (currentAllowance < amount) revert InsufficientAllowance();
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTXEligibility {
    // Read functions.
    function name() external pure returns (string memory);

    function finalized() external view returns (bool);

    function targetAsset() external pure returns (address);

    function checkAllEligible(uint256[] calldata tokenIds)
        external
        view
        returns (bool);

    function checkEligible(uint256[] calldata tokenIds)
        external
        view
        returns (bool[] memory);

    function checkAllIneligible(uint256[] calldata tokenIds)
        external
        view
        returns (bool);

    function checkIsEligible(uint256 tokenId) external view returns (bool);

    // Write functions.
    function __NFTXEligibility_init_bytes(bytes calldata configData) external;

    function beforeMintHook(uint256[] calldata tokenIds) external;

    function afterMintHook(uint256[] calldata tokenIds) external;

    function beforeRedeemHook(uint256[] calldata tokenIds) external;

    function afterRedeemHook(uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import {IWETH9} from "@uni-periphery/interfaces/external/IWETH9.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";

import {INFTXVaultFactoryV3} from "@src/interfaces/INFTXVaultFactoryV3.sol";
import {ITimelockExcludeList} from "@src/interfaces/ITimelockExcludeList.sol";
import {IPermitAllowanceTransfer} from "@src/interfaces/external/IPermitAllowanceTransfer.sol";
import {InventoryStakingDescriptor} from "@src/custom/InventoryStakingDescriptor.sol";

interface INFTXInventoryStakingV3 is IERC721Upgradeable {
    // details about the staking position
    struct Position {
        // the nonce for permits
        uint256 nonce;
        // vaultId corresponding to the vTokens staked in this position
        uint256 vaultId;
        // timestamp at which the timelock expires
        uint256 timelockedUntil;
        // net timelock for position
        uint256 timelock;
        // position timelocked if created with vTokens. Can't early withdraw in this case
        uint256 vTokenTimelockedUntil;
        // shares balance is used to track position's ownership of total vToken balance
        uint256 vTokenShareBalance;
        // used to evaluate weth fees accumulated per vTokenShare since this snapshot
        uint256 wethFeesPerVTokenShareSnapshotX128;
        // owed weth fees, updates when positions merged
        uint256 wethOwed;
    }

    struct VaultGlobal {
        uint256 totalVTokenShares;
        uint256 globalWethFeesPerVTokenShareX128;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    function MINIMUM_LIQUIDITY() external view returns (uint256);

    function nftxVaultFactory() external view returns (INFTXVaultFactoryV3);

    function timelockExcludeList() external view returns (ITimelockExcludeList);

    function WETH() external view returns (IWETH9);

    function PERMIT2() external returns (IPermitAllowanceTransfer);

    // =============================================================
    //                            STORAGE
    // =============================================================

    function timelock() external view returns (uint256);

    function earlyWithdrawPenaltyInWei() external view returns (uint256);

    function positions(
        uint256 positionId
    )
        external
        view
        returns (
            uint256 nonce,
            uint256 vaultId,
            uint256 timelockedUntil,
            uint256 timelock,
            uint256 vTokenTimelockedUntil,
            uint256 vTokenShareBalance,
            uint256 wethFeesPerVTokenShareSnapshotX128,
            uint256 wethOwed
        );

    function vaultGlobal(
        uint256 vaultId
    )
        external
        view
        returns (
            uint256 totalVTokenShares,
            uint256 globalWethFeesPerVTokenShareX128
        );

    function descriptor() external view returns (InventoryStakingDescriptor);

    // =============================================================
    //                            EVENTS
    // =============================================================

    event Deposit(
        uint256 indexed vaultId,
        uint256 indexed positionId,
        uint256 amount,
        bool forceTimelock
    );
    event DepositWithNFT(
        uint256 indexed vaultId,
        uint256 indexed positionId,
        uint256[] tokenIds,
        uint256[] amounts
    );
    event IncreasePosition(
        uint256 indexed vaultId,
        uint256 indexed positionId,
        uint256 amount
    );
    event CombinePositions(
        uint256 parentPositionId,
        uint256[] childPositionIds
    );
    event CollectWethFees(uint256 indexed positionId, uint256 wethAmount);
    event Withdraw(
        uint256 indexed positionId,
        uint256 vTokenShares,
        uint256 vTokenAmount,
        uint256 wethAmount
    );
    event UpdateTimelock(uint256 newTimelock);
    event UpdateEarlyWithdrawPenalty(uint256 newEarlyWithdrawPenaltyInWei);

    // =============================================================
    //                            ERRORS
    // =============================================================

    error TimelockTooLong();
    error InvalidEarlyWithdrawPenalty();
    error NotPositionOwner();
    error Timelocked();
    error VaultIdMismatch();
    error ParentChildSame();
    error InsufficientVTokens();
    error LiquidityBelowMinimum();
    error ZeroAddress();
    error InsufficientVTokenShares();
    error SenderNotFeeDistributor();
    error PositionNotCreatedWithVTokens();
    error ZeroVTokenShares();

    // =============================================================
    //                           INIT
    // =============================================================

    function __NFTXInventoryStaking_init(
        uint256 timelock_,
        uint256 earlyWithdrawPenaltyInWei_,
        ITimelockExcludeList timelockExcludeList_,
        InventoryStakingDescriptor descriptor_
    ) external;

    // =============================================================
    //                     PUBLIC / EXTERNAL WRITE
    // =============================================================

    /**
     * @notice Deposits vToken to mint inventory staking xNFT position
     *
     * @param vaultId The id of the vault
     * @param amount Vault tokens amount to deposit
     * @param recipient Recipient address for the xNFT
     * @param encodedPermit2 Encoded function params (owner, permitSingle, signature) for `PERMIT2.permit()`
     * @param viaPermit2 If true then vTokens transferred via Permit2 else normal token transferFrom
     * @param forceTimelock Forcefully apply timelock to the position
     *
     * @return positionId The tokenId for the xNFT position
     */
    function deposit(
        uint256 vaultId,
        uint256 amount,
        address recipient,
        bytes calldata encodedPermit2,
        bool viaPermit2,
        bool forceTimelock
    ) external returns (uint256 positionId);

    /**
     * @notice Deposits NFT to mint inventory staking xNFT position
     *
     * @param vaultId The id of the vault corresponding to the NFT
     * @param tokenIds The token ids to deposit
     * @param amounts For ERC1155: quantity corresponding to each tokenId to deposit
     * @param recipient Recipient address for the xNFT
     *
     * @return positionId The tokenId for the xNFT position
     */
    function depositWithNFT(
        uint256 vaultId,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address recipient
    ) external returns (uint256 positionId);

    /**
     * @notice Add more vTokens to an existing position (the position have been created with just vTokens)
     *
     * @param positionId The position to add vTokens into
     * @param amount Vault tokens amount to deposit
     * @param encodedPermit2 Encoded function params (owner, permitSingle, signature) for `PERMIT2.permit()`
     * @param viaPermit2 If true then vTokens transferred via Permit2 else normal token transferFrom
     * @param forceTimelock Forcefully apply timelock to the position
     */
    function increasePosition(
        uint256 positionId,
        uint256 amount,
        bytes calldata encodedPermit2,
        bool viaPermit2,
        bool forceTimelock
    ) external;

    /**
     * @notice Withdraw vault tokens from the position. Penalty is deducted if position has not finished the timelock.
     *
     * @param positionId The position id to withdraw vault tokens from
     * @param vTokenShares Amount of vault token shares to burn
     * @param nftIds NFT tokenIds to redeem with the vault tokens withdrawn. If array is empty then only vault tokens transferred. Redeem fees (in ETH from msg.value) only paid for positions which were minted with vTokens
     * @param vTokenPremiumLimit The max net premium in vTokens the user is willing to pay to redeem nftIds, else tx reverts
     */
    function withdraw(
        uint256 positionId,
        uint256 vTokenShares,
        uint256[] calldata nftIds,
        uint256 vTokenPremiumLimit
    ) external payable;

    /**
     * @notice Combine underlying vToken and WETH balances from childPositions into parentPosition, if all of their timelocks ended. All positions must be for the same vault id.
     *
     * @param parentPositionId xNFT Position id that will receive the underlying balances from childPositions
     * @param childPositionIds Array of xNFT position ids to be combined
     */
    function combinePositions(
        uint256 parentPositionId,
        uint256[] calldata childPositionIds
    ) external;

    /**
     * @notice Receive WETH fees accumulated by multiple positions
     *
     * @param positionIds The positions to withdraw weth fees from
     */
    function collectWethFees(uint256[] calldata positionIds) external;

    /**
     * @dev Can only be called by feeDistributor. vToken rewards can be directly transferred to this contract without calling this function
     *
     * @param vaultId The vault id that should receive the rewards
     * @param wethAmount Amount of WETH to pull as rewards
     *
     * @return rewardsDistributed Returns false if the `totalVTokenShares` is zero for the given `vaultId`
     */
    function receiveWethRewards(
        uint256 vaultId,
        uint256 wethAmount
    ) external returns (bool rewardsDistributed);

    // =============================================================
    //                        ONLY OWNER WRITE
    // =============================================================

    function setTimelock(uint256 timelock_) external;

    function setEarlyWithdrawPenalty(
        uint256 earlyWithdrawPenaltyInWei_
    ) external;

    function setDescriptor(InventoryStakingDescriptor descriptor_) external;

    // =============================================================
    //                     PUBLIC / EXTERNAL VIEW
    // =============================================================

    /**
     * @notice Returns the worth of 10^18 vTokenShares in terms of the underlying vToken corresponding to the provided `vaultId`
     */
    function pricePerShareVToken(
        uint256 vaultId
    ) external view returns (uint256);

    /**
     * @notice Returns the current WETH balance for a given `positionId`
     */
    function wethBalance(uint256 positionId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IBeacon} from "@src/custom/proxy/IBeacon.sol";

interface INFTXVaultFactoryV3 is IBeacon {
    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct VaultFees {
        bool active;
        uint64 mintFee;
        uint64 redeemFee;
        uint64 swapFee;
    }

    // =============================================================
    //                            VARIABLES
    // =============================================================

    function feeDistributor() external view returns (address);

    function eligibilityManager() external view returns (address);

    function excludedFromFees(address addr) external view returns (bool);

    function factoryMintFee() external view returns (uint64);

    function factoryRedeemFee() external view returns (uint64);

    function factorySwapFee() external view returns (uint64);

    function twapInterval() external view returns (uint32);

    function premiumDuration() external view returns (uint256);

    function premiumMax() external view returns (uint256);

    function depositorPremiumShare() external view returns (uint256);

    // =============================================================
    //                            EVENTS
    // =============================================================

    event NewFeeDistributor(address oldDistributor, address newDistributor);
    event FeeExclusion(address feeExcluded, bool excluded);
    event NewEligibilityManager(address oldEligManager, address newEligManager);
    event NewVault(
        uint256 indexed vaultId,
        address vaultAddress,
        address assetAddress,
        string name,
        string symbol
    );
    event UpdateVaultFees(
        uint256 vaultId,
        uint256 mintFee,
        uint256 redeemFee,
        uint256 swapFee
    );
    event DisableVaultFees(uint256 vaultId);
    event UpdateFactoryFees(
        uint256 mintFee,
        uint256 redeemFee,
        uint256 swapFee
    );
    event NewPremiumMax(uint256 premiumMax);
    event NewPremiumDuration(uint256 premiumDuration);
    event NewDepositorPremiumShare(uint256 depositorPremiumShare);
    event NewTwapInterval(uint32 twapInterval);

    // =============================================================
    //                            ERRORS
    // =============================================================

    error FeeDistributorNotSet();
    error VaultImplementationNotSet();
    error FeeExceedsLimit();
    error CallerIsNotVault();
    error ZeroTwapInterval();
    error DepositorPremiumShareExceedsLimit();
    error ZeroAddress();
    error ZeroAmountRequested();
    error NFTInventoryExceeded();

    // =============================================================
    //                           INIT
    // =============================================================

    function __NFTXVaultFactory_init(
        address vaultImpl,
        uint32 twapInterval_,
        uint256 premiumDuration_,
        uint256 premiumMax_,
        uint256 depositorPremiumShare_
    ) external;

    // =============================================================
    //                     ONLY PRIVILEGED WRITE
    // =============================================================

    function setFactoryFees(
        uint256 mintFee,
        uint256 redeemFee,
        uint256 swapFee
    ) external;

    function setVaultFees(
        uint256 vaultId,
        uint256 mintFee,
        uint256 redeemFee,
        uint256 swapFee
    ) external;

    function disableVaultFees(uint256 vaultId) external;

    function setFeeDistributor(address feeDistributor_) external;

    function setFeeExclusion(address excludedAddr, bool excluded) external;

    function setEligibilityManager(address eligibilityManager_) external;

    function setTwapInterval(uint32 twapInterval_) external;

    function setPremiumDuration(uint256 premiumDuration_) external;

    function setPremiumMax(uint256 premiumMax_) external;

    function setDepositorPremiumShare(uint256 depositorPremiumShare_) external;

    // =============================================================
    //                     PUBLIC / EXTERNAL WRITE
    // =============================================================

    function createVault(
        string calldata name,
        string calldata symbol,
        address assetAddress,
        bool is1155,
        bool allowAllItems
    ) external returns (uint256 vaultId);

    // =============================================================
    //                     PUBLIC / EXTERNAL VIEW
    // =============================================================

    function vaultFees(
        uint256 vaultId
    )
        external
        view
        returns (uint256 mintFee, uint256 redeemFee, uint256 swapFee);

    function isLocked(uint256 id) external view returns (bool);

    function vaultsForAsset(
        address asset
    ) external view returns (address[] memory);

    function allVaults() external view returns (address[] memory);

    function numVaults() external view returns (uint256);

    function vault(uint256 vaultId) external view returns (address);

    function computeVaultAddress(
        address assetAddress,
        string memory name,
        string memory symbol
    ) external view returns (address);

    function getTwapX96(address pool) external view returns (uint256 priceX96);

    /**
     * @notice Get vToken premium corresponding for a tokenId in the vault
     *
     * @param tokenId token id to calculate the premium for
     * @return premium Premium in vTokens
     * @return depositor Depositor that receives a share of this premium
     */
    function getVTokenPremium721(
        uint256 vaultId,
        uint256 tokenId
    ) external view returns (uint256 premium, address depositor);

    /**
     * @notice Get vToken premium corresponding for a tokenId in the vault
     *
     * @param tokenId token id to calculate the premium for
     * @param amount ERC1155 amount of tokenId to redeem
     *
     * @return totalPremium Total premium in vTokens
     * @return premiums Premiums corresponding to each depositor
     * @return depositors Depositors that receive a share from the `premiums`
     */
    function getVTokenPremium1155(
        uint256 vaultId,
        uint256 tokenId,
        uint256 amount
    )
        external
        view
        returns (
            uint256 totalPremium,
            uint256[] memory premiums,
            address[] memory depositors
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IWETH9} from "@uni-periphery/interfaces/external/IWETH9.sol";
import {INFTXEligibility} from "@src/interfaces/INFTXEligibility.sol";
import {IERC20Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC721/IERC721Upgradeable.sol";
import {INFTXVaultFactoryV3} from "@src/interfaces/INFTXVaultFactoryV3.sol";
import {IERC1155Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC1155/IERC1155Upgradeable.sol";
import {IERC3156FlashBorrowerUpgradeable} from "@src/custom/tokens/ERC20/ERC20FlashMintUpgradeable.sol";

interface INFTXVaultV3 is IERC20Upgradeable {
    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenDepositInfo {
        uint48 timestamp;
        address depositor;
    }

    struct DepositInfo1155 {
        uint256 qty;
        address depositor;
        uint48 timestamp;
    }

    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    function WETH() external view returns (IWETH9);

    // only set during initialization

    function assetAddress() external view returns (address);

    function vaultFactory() external view returns (INFTXVaultFactoryV3);

    function vaultId() external view returns (uint256);

    function is1155() external view returns (bool);

    // =============================================================
    //                          VARIABLES
    // =============================================================

    function manager() external view returns (address);

    function eligibilityStorage() external view returns (INFTXEligibility);

    function allowAllItems() external view returns (bool);

    function enableMint() external view returns (bool);

    function enableRedeem() external view returns (bool);

    function enableSwap() external view returns (bool);

    function tokenDepositInfo(
        uint256 tokenId
    ) external view returns (uint48 timestamp, address depositor);

    function depositInfo1155(
        uint256 tokenId,
        uint256 index
    ) external view returns (uint256 qty, address depositor, uint48 timestamp);

    function pointerIndex1155(uint256 tokenId) external view returns (uint256);

    // =============================================================
    //                            EVENTS
    // =============================================================

    event VaultInit(
        uint256 indexed vaultId,
        address assetAddress,
        bool is1155,
        bool allowAllItems
    );

    event ManagerSet(address manager);
    event EligibilityDeployed(uint256 moduleIndex, address eligibilityAddr);

    event EnableMintUpdated(bool enabled);
    event EnableRedeemUpdated(bool enabled);
    event EnableSwapUpdated(bool enabled);

    event Minted(
        uint256[] nftIds,
        uint256[] amounts,
        address to,
        address depositor
    );
    event Redeemed(uint256[] specificIds, address to);
    event Swapped(
        uint256[] nftIds,
        uint256[] amounts,
        uint256[] specificIds,
        address to,
        address depositor
    );
    event PremiumShared(address depositor, uint256 wethPremium);
    event FeesDistributed(uint256 wethFees);
    event VaultShutdown(
        address assetAddress,
        uint256 numItems,
        address recipient
    );

    // =============================================================
    //                            ERRORS
    // =============================================================

    error ZeroAddress();
    error MintingDisabled();
    error RedeemDisabled();
    error SwapDisabled();
    error InsufficientETHSent();
    error TransferAmountIsZero();
    error TokenLengthMismatch();
    error EligibilityAlreadySet();
    error NotEligible();
    error NotNFTOwner();
    error NFTAlreadyOwned();
    error NotOwner();
    error NotManager();
    error Paused();
    error TooManyItems();
    error IdNotFound();
    error HoldingsUpdationFailed();
    error InvalidToken();
    error PremiumLimitExceeded();
    error ETHSent();
    error CantRescueAssetToken();

    // =============================================================
    //                           INIT
    // =============================================================

    function __NFTXVault_init(
        string calldata name_,
        string calldata symbol_,
        address assetAddress_,
        bool is1155_,
        bool allowAllItems_
    ) external;

    // =============================================================
    //                     ONLY PRIVILEGED WRITE
    // =============================================================

    /**
     * @notice Sets manager to zero address
     */
    function finalizeVault() external;

    function setVaultMetadata(
        string memory name_,
        string memory symbol_
    ) external;

    function setVaultFeatures(
        bool enableMint_,
        bool enableRedeem_,
        bool enableSwap_
    ) external;

    function setFees(
        uint256 mintFee_,
        uint256 redeemFee_,
        uint256 swapFee_
    ) external;

    /**
     * @notice Disables custom vault fees. Vault fees reverts back to the global vault fees.
     */
    function disableVaultFees() external;

    /**
     * @notice Allows for an easy setup of any eligibility module contract from the EligibilityManager.
     *
     * @param moduleIndex Index of the module to deploy
     * @param initData ABI encoded parameters for the desired module
     */
    function deployEligibilityStorage(
        uint256 moduleIndex,
        bytes calldata initData
    ) external returns (address);

    /**
     * @notice Set new manager. The manager has control over options like fees and features
     */
    function setManager(address _manager) external;

    /**
     * @notice Delegate all to the current vault factory's owner
     */
    function updateDelegate() external;

    // =============================================================
    //                     ONLY OWNER WRITE
    // =============================================================

    function rescueTokens(
        TokenType tt,
        address token,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;

    function shutdown(address recipient, uint256[] calldata tokenIds) external;

    // =============================================================
    //                     PUBLIC / EXTERNAL WRITE
    // =============================================================

    /**
     * @notice Mints vault tokens in exchange for depositing NFTs. Mint fees is paid in ETH (via msg.value)
     *
     * @param tokenIds The token ids to deposit
     * @param amounts For ERC1155: quantity corresponding to each tokenId to deposit
     * @param depositor Depositor address that should receive premiums for the `tokenIds` deposited here
     * @param to Recipient address for the vTokens
     */
    function mint(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address depositor,
        address to
    ) external payable returns (uint256 vTokensMinted);

    /**
     * @notice Redeem vault tokens for the underlying NFTs. Redeem fees is paid in ETH (via msg.value) or WETH
     *
     * @param idsOut NFT ids to withdraw
     * @param to Recipient address for the NFTs
     * @param wethAmount if vault fees should be deducted in WETH instead of ETH (msg.value should be 0 here)
     * @param vTokenPremiumLimit The max net premium in vTokens the user is willing to pay, else tx reverts
     * @param forceFees forcefully deduct fees even if sender is on the exclude list
     *
     * @return ethFees The ETH fees charged
     */
    function redeem(
        uint256[] calldata idsOut,
        address to,
        uint256 wethAmount,
        uint256 vTokenPremiumLimit,
        bool forceFees
    ) external payable returns (uint256 ethFees);

    /**
     * @notice Swap `idsIn` of NFTs into `idsOut` from the vault. Swap fees is paid in ETH (via msg.value)
     *
     * @param idsIn NFT ids to sell
     * @param amounts For ERC1155: quantity corresponding to each tokenId to sell
     * @param idsOut NFT ids to buy
     * @param depositor Depositor address that should receive premiums for the `idsIn` deposited here
     * @param to Recipient address for the NFTs
     * @param vTokenPremiumLimit The max net premium in vTokens the user is willing to pay, else tx reverts
     * @param forceFees forcefully deduct fees even if sender is on the exclude list
     *
     * @return ethFees The ETH fees charged
     */
    function swap(
        uint256[] calldata idsIn,
        uint256[] calldata amounts,
        uint256[] calldata idsOut,
        address depositor,
        address to,
        uint256 vTokenPremiumLimit,
        bool forceFees
    ) external payable returns (uint256 ethFees);

    /**
     * @notice Performs a flash loan. New tokens are minted and sent to the
     * `receiver`, who is required to implement the {IERC3156FlashBorrower}
     * interface. By the end of the flash loan, the receiver is expected to own
     * amount + fee tokens and have them approved back to the token contract itself so
     * they can be burned.
     *
     * @param receiver The receiver of the flash loan. Should implement the
     * {IERC3156FlashBorrower-onFlashLoan} interface.
     * @param token The token to be flash loaned. Only `address(this)` is
     * supported.
     * @param amount The amount of tokens to be loaned.
     * @param data An arbitrary datafield that is passed to the receiver.
     *
     * @return `true` if the flash loan was successful.
     */
    function flashLoan(
        IERC3156FlashBorrowerUpgradeable receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    // =============================================================
    //                     PUBLIC / EXTERNAL VIEW
    // =============================================================

    function nftIdAt(uint256 holdingsIndex) external view returns (uint256);

    function allHoldings() external view returns (uint256[] memory);

    function totalHoldings() external view returns (uint256);

    function holdingsContains(uint256 tokenId) external view returns (bool);

    /**
     * @notice Vault Fees in terms of vault tokens
     */
    function vaultFees()
        external
        view
        returns (uint256 mintFee, uint256 redeemFee, uint256 swapFee);

    function allValidNFTs(
        uint256[] calldata tokenIds
    ) external view returns (bool);

    /**
     * @notice Calculate ETH amount corresponding to a given vToken amount, calculated via TWAP from the NFTX AMM
     */
    function vTokenToETH(uint256 vTokenAmount) external view returns (uint256);

    /**
     * @notice Length of depositInfo1155 array for a given `tokenId`
     */
    function depositInfo1155Length(
        uint256 tokenId
    ) external view returns (uint256);

    function version() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITimelockExcludeList {
    function isExcluded(
        address addr,
        uint256 vaultId
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IPermitAllowanceTransfer {
    /// @notice Thrown when an allowance on a token has expired.
    /// @param deadline The timestamp at which the allowed amount is no longer valid
    error AllowanceExpired(uint256 deadline);

    /// @notice Thrown when an allowance on a token has been depleted.
    /// @param amount The maximum amount allowed
    error InsufficientAllowance(uint256 amount);

    /// @notice Thrown when too many nonces are invalidated.
    error ExcessiveInvalidation();

    /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
    event NonceInvalidation(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint48 newNonce,
        uint48 oldNonce
    );

    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration
    );

    /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
    event Permit(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    );

    /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
    event Lockdown(address indexed owner, address token, address spender);

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The saved permissions
    /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice A token spender pair.
    struct TokenSpenderPair {
        // the token the spender is approved
        address token;
        // the spender address
        address spender;
    }

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(
        address,
        address,
        address
    ) external view returns (uint160, uint48, uint48);

    /// @notice Approves the spender to use up to amount of the specified token up until the expiration
    /// @param token The token to approve
    /// @param spender The spender address to approve
    /// @param amount The approved amount of the token
    /// @param expiration The timestamp at which the approval is no longer valid
    /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    function approve(
        address token,
        address spender,
        uint160 amount,
        uint48 expiration
    ) external;

    /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(
        address owner,
        PermitSingle memory permitSingle,
        bytes calldata signature
    ) external;

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(
        address owner,
        PermitBatch memory permitBatch,
        bytes calldata signature
    ) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(
        address from,
        address to,
        uint160 amount,
        address token
    ) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(
        AllowanceTransferDetails[] calldata transferDetails
    ) external;

    /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
    /// by batch revoking approvals
    /// @param approvals Array of approvals to revoke.
    function lockdown(TokenSpenderPair[] calldata approvals) external;

    /// @notice Invalidate nonces for a given (token, spender) pair
    /// @param token The token to invalidate nonces for
    /// @param spender The spender to invalidate nonces for
    /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
    /// @dev Can't invalidate more than 2**16 nonces per transaction.
    function invalidateNonces(
        address token,
        address spender,
        uint48 newNonce
    ) external;
}

pragma solidity =0.8.15;

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library TransferLib {
    using SafeERC20 for IERC20;

    address internal constant CRYPTO_PUNKS =
        0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    address internal constant CRYPTO_KITTIES =
        0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;

    // Errors
    error UnableToSendETH();
    error NotNFTOwner();

    function transferFromERC721(
        address assetAddress,
        address to,
        uint256[] memory nftIds
    ) internal {
        for (uint256 i; i < nftIds.length; ) {
            _transferFromERC721(assetAddress, nftIds[i], to);

            if (assetAddress == CRYPTO_PUNKS) {
                _approveCryptoPunkERC721(nftIds[i], to);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Setting max allowance to save gas on subsequent calls.
    function maxApprove(
        address token,
        address spender,
        uint256 amount
    ) internal {
        uint256 allowance = IERC20(token).allowance(address(this), spender);

        if (amount > allowance) {
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }

    /// @dev Setting max allowance to save gas on subsequent calls without using safeApprove. Use it only where the tokens are known.
    function unSafeMaxApprove(
        address token,
        address spender,
        uint256 amount
    ) internal {
        uint256 allowance = IERC20(token).allowance(address(this), spender);

        if (amount > allowance) {
            // avoids reading allowance again, which is the case with safeApprove
            IERC20(token).approve(spender, type(uint256).max);
        }
    }

    function transferETH(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        if (!success) revert UnableToSendETH();
    }

    /**
     * @notice Transfers sender's ERC721 tokens to a specified recipient.
     *
     * @param assetAddr Address of the asset being transferred
     * @param tokenId The ID of the token being transferred
     * @param to The address the token is being transferred to
     */

    function _transferFromERC721(
        address assetAddr,
        uint256 tokenId,
        address to
    ) private {
        bytes memory data;

        if (assetAddr != CRYPTO_PUNKS && assetAddr != CRYPTO_KITTIES) {
            // We push to the vault to avoid an unneeded transfer.
            data = abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                msg.sender,
                to,
                tokenId
            );
        } else if (assetAddr == CRYPTO_PUNKS) {
            // Fix here for frontrun attack.
            bytes memory punkIndexToAddress = abi.encodeWithSignature(
                "punkIndexToAddress(uint256)",
                tokenId
            );
            (bool checkSuccess, bytes memory result) = CRYPTO_PUNKS.staticcall(
                punkIndexToAddress
            );
            address nftOwner = abi.decode(result, (address));

            if (!checkSuccess || nftOwner != msg.sender) revert NotNFTOwner();
            data = abi.encodeWithSignature("buyPunk(uint256)", tokenId);
        } else {
            // CRYPTO_KITTIES
            data = abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                tokenId
            );
        }

        (bool success, bytes memory resultData) = address(assetAddr).call(data);
        require(success, string(resultData));
    }

    /**
     * @notice Approves our Cryptopunk ERC721 tokens to be transferred.
     *
     * @dev This is only required to provide special logic for Cryptopunks.
     *
     * @param tokenId The ID of the token being transferred
     * @param to The address the token is being transferred to
     */

    function _approveCryptoPunkERC721(uint256 tokenId, address to) private {
        bytes memory data = abi.encodeWithSignature(
            "offerPunkForSaleToAddress(uint256,uint256,address)",
            tokenId,
            0,
            to
        );
        (bool success, bytes memory resultData) = CRYPTO_PUNKS.call(data);
        require(success, string(resultData));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./IPoolInitializer.sol";
import "./IERC721Permit.sol";
import "./IPeripheryPayments.sol";
import "./IPeripheryImmutableState.sol";
import "../libraries/PoolAddress.sol";

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(
        uint256 indexed tokenId,
        address recipient,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Returns the timestamp, till when the position is timelocked for
    function lockedUntil(uint256 tokenId) external view returns (uint256);

    /// @notice Net timelock for position
    function timelock(uint256 tokenId) external view returns (uint256);

    /// @notice Check if a particular address is excluded from timelock and hence can withdraw from the position early
    function timelockExcluded(address addr) external view returns (bool);

    /// @dev Only callable by NFTXRouter
    function setLockedUntil(
        uint256 tokenId,
        uint256 lockedUntil,
        uint256 timelock
    ) external;

    function setTimelockExcluded(address addr, bool isExcluded) external;

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    )
        external
        payable
        returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Refunds any ETH balance held by this contract to the `receiver`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH(address receiver) external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.15;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library HexStrings {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    /// @notice Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
    /// @dev Credit to Open Zeppelin under MIT license https://github.com/OpenZeppelin/openzeppelin-contracts/blob/243adff49ce1700e0ecb99fe522fb16cff1d1ddc/contracts/utils/Strings.sol#L55
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {Create2Upgradeable} from "@openzeppelin-upgradeable/contracts/utils/Create2Upgradeable.sol";

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    // NOTE: Ensure this value is latest & corresponds to current Create2BeaconProxy code
    // keccak256(type(Create2BeaconProxy).creationCode);
    bytes32 internal constant BEACON_CODE_HASH =
        0x7700ec83d0dc69c0a1e228138168ca93778a8d2f0fe9a0afb44901e1d5142d48;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(
        address factory,
        PoolKey memory key
    ) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = Create2Upgradeable.computeAddress(
            keccak256(abi.encode(key.token0, key.token1, key.fee)),
            BEACON_CODE_HASH,
            factory
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTXInventoryStakingV2 {
    function nftxVaultFactory() external view returns (address);

    function vaultXToken(uint256 vaultId) external view returns (address);

    function xTokenAddr(address baseToken) external view returns (address);

    function xTokenShareValue(uint256 vaultId) external view returns (uint256);

    function __NFTXInventoryStaking_init(address nftxFactory) external;

    function deployXTokenForVault(uint256 vaultId) external;

    function receiveRewards(
        uint256 vaultId,
        uint256 amount
    ) external returns (bool);

    function timelockMintFor(
        uint256 vaultId,
        uint256 amount,
        address to,
        uint256 timelockLength
    ) external returns (uint256);

    function deposit(uint256 vaultId, uint256 _amount) external;

    function withdraw(uint256 vaultId, uint256 _share) external;

    function timelockUntil(
        uint256 vaultId,
        address who
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTXVaultFactoryV2 {
    // Read functions.
    function owner() external view returns (address);

    function numVaults() external view returns (uint256);

    function zapContract() external view returns (address);

    function zapContracts(address addr) external view returns (bool);

    function feeDistributor() external view returns (address);

    function eligibilityManager() external view returns (address);

    function vault(uint256 vaultId) external view returns (address);

    function allVaults() external view returns (address[] memory);

    function vaultsForAsset(
        address asset
    ) external view returns (address[] memory);

    function isLocked(uint256 id) external view returns (bool);

    function excludedFromFees(address addr) external view returns (bool);

    function factoryMintFee() external view returns (uint64);

    function factoryRandomRedeemFee() external view returns (uint64);

    function factoryTargetRedeemFee() external view returns (uint64);

    function factoryRandomSwapFee() external view returns (uint64);

    function factoryTargetSwapFee() external view returns (uint64);

    function vaultFees(
        uint256 vaultId
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    event NewFeeDistributor(address oldDistributor, address newDistributor);
    event NewZapContract(address oldZap, address newZap);
    event UpdatedZapContract(address zap, bool excluded);
    event FeeExclusion(address feeExcluded, bool excluded);
    event NewEligibilityManager(address oldEligManager, address newEligManager);
    event NewVault(
        uint256 indexed vaultId,
        address vaultAddress,
        address assetAddress
    );
    event UpdateVaultFees(
        uint256 vaultId,
        uint256 mintFee,
        uint256 randomRedeemFee,
        uint256 targetRedeemFee,
        uint256 randomSwapFee,
        uint256 targetSwapFee
    );
    event DisableVaultFees(uint256 vaultId);
    event UpdateFactoryFees(
        uint256 mintFee,
        uint256 randomRedeemFee,
        uint256 targetRedeemFee,
        uint256 randomSwapFee,
        uint256 targetSwapFee
    );

    // Write functions.
    function __NFTXVaultFactory_init(
        address _vaultImpl,
        address _feeDistributor
    ) external;

    function createVault(
        string calldata name,
        string calldata symbol,
        address _assetAddress,
        bool is1155,
        bool allowAllItems
    ) external returns (uint256);

    function setFeeDistributor(address _feeDistributor) external;

    function setEligibilityManager(address _eligibilityManager) external;

    function setZapContract(address _zapContract, bool _excluded) external;

    function setFeeExclusion(address _excludedAddr, bool excluded) external;

    function setFactoryFees(
        uint256 mintFee,
        uint256 randomRedeemFee,
        uint256 targetRedeemFee,
        uint256 randomSwapFee,
        uint256 targetSwapFee
    ) external;

    function setVaultFees(
        uint256 vaultId,
        uint256 mintFee,
        uint256 randomRedeemFee,
        uint256 targetRedeemFee,
        uint256 randomSwapFee,
        uint256 targetSwapFee
    ) external;

    function disableVaultFees(uint256 vaultId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTXVaultV2 {
    function manager() external view returns (address);

    function assetAddress() external view returns (address);

    function vaultFactory() external view returns (address);

    function eligibilityStorage() external view returns (address);

    function is1155() external view returns (bool);

    function allowAllItems() external view returns (bool);

    function enableMint() external view returns (bool);

    function enableRandomRedeem() external view returns (bool);

    function enableTargetRedeem() external view returns (bool);

    function enableRandomSwap() external view returns (bool);

    function enableTargetSwap() external view returns (bool);

    function vaultId() external view returns (uint256);

    function nftIdAt(uint256 holdingsIndex) external view returns (uint256);

    function allHoldings() external view returns (uint256[] memory);

    function totalHoldings() external view returns (uint256);

    function mintFee() external view returns (uint256);

    function randomRedeemFee() external view returns (uint256);

    function targetRedeemFee() external view returns (uint256);

    function randomSwapFee() external view returns (uint256);

    function targetSwapFee() external view returns (uint256);

    function vaultFees()
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256);

    event VaultInit(
        uint256 indexed vaultId,
        address assetAddress,
        bool is1155,
        bool allowAllItems
    );

    event ManagerSet(address manager);
    event EligibilityDeployed(uint256 moduleIndex, address eligibilityAddr);
    // event CustomEligibilityDeployed(address eligibilityAddr);

    event EnableMintUpdated(bool enabled);
    event EnableRandomRedeemUpdated(bool enabled);
    event EnableTargetRedeemUpdated(bool enabled);
    event EnableRandomSwapUpdated(bool enabled);
    event EnableTargetSwapUpdated(bool enabled);

    event Minted(uint256[] nftIds, uint256[] amounts, address to);
    event Redeemed(uint256[] nftIds, uint256[] specificIds, address to);
    event Swapped(
        uint256[] nftIds,
        uint256[] amounts,
        uint256[] specificIds,
        uint256[] redeemedIds,
        address to
    );

    function __NFTXVault_init(
        string calldata _name,
        string calldata _symbol,
        address _assetAddress,
        bool _is1155,
        bool _allowAllItems
    ) external;

    function finalizeVault() external;

    function setVaultMetadata(
        string memory name_,
        string memory symbol_
    ) external;

    function setVaultFeatures(
        bool _enableMint,
        bool _enableRandomRedeem,
        bool _enableTargetRedeem,
        bool _enableRandomSwap,
        bool _enableTargetSwap
    ) external;

    function setFees(
        uint256 _mintFee,
        uint256 _randomRedeemFee,
        uint256 _targetRedeemFee,
        uint256 _randomSwapFee,
        uint256 _targetSwapFee
    ) external;

    function disableVaultFees() external;

    // This function allows for an easy setup of any eligibility module contract from the EligibilityManager.
    // It takes in ABI encoded parameters for the desired module. This is to make sure they can all follow
    // a similar interface.
    function deployEligibilityStorage(
        uint256 moduleIndex,
        bytes calldata initData
    ) external returns (address);

    // The manager has control over options like fees and features
    function setManager(address _manager) external;

    function mint(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts /* ignored for ERC721 vaults */
    ) external returns (uint256);

    function mintTo(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts /* ignored for ERC721 vaults */,
        address to
    ) external returns (uint256);

    function redeem(
        uint256 nftCount,
        uint256[] calldata specificIds
    ) external returns (uint256[] calldata);

    function redeemTo(
        uint256 nftCount,
        uint256[] calldata specificIds,
        address to
    ) external returns (uint256[] calldata);

    function swap(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts /* ignored for ERC721 vaults */,
        uint256[] calldata specificIds
    ) external returns (uint256[] calldata);

    function swapTo(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts /* ignored for ERC721 vaults */,
        uint256[] calldata specificIds,
        address to
    ) external returns (uint256[] calldata);

    function allValidNFTs(
        uint256[] calldata tokenIds
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import {TransferLib} from "@src/lib/TransferLib.sol";

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH9} from "@uni-periphery/interfaces/external/IWETH9.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {INFTXVaultV2} from "@src/v2/interfaces/INFTXVaultV2.sol";
import {INFTXVaultV3} from "@src/interfaces/INFTXVaultV3.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "@src/interfaces/external/IUniswapV2Router02.sol";
import {INFTXVaultFactoryV3} from "@src/interfaces/INFTXVaultFactoryV3.sol";
import {INFTXVaultFactoryV2} from "@src/v2/interfaces/INFTXVaultFactoryV2.sol";
import {INFTXInventoryStakingV2} from "@src/v2/interfaces/INFTXInventoryStakingV2.sol";
import {INFTXInventoryStakingV3} from "@src/interfaces/INFTXInventoryStakingV3.sol";
import {INonfungiblePositionManager} from "@uni-periphery/interfaces/INonfungiblePositionManager.sol";

/**
 * @title NFTX Migrator Zap
 * @author @apoorvlathey
 * @notice Migrates positions from NFTX v2 to v3
 * @dev This Zap must be excluded from vault fees in both NFTX v2 & v3.
 */
contract MigratorZap is Ownable {
    using SafeERC20 for IERC20;

    struct SushiToNFTXAMMParams {
        // Sushiswap pool address for vTokenV2 <> WETH pair
        address sushiPair;
        // LP balance to withdraw from sushiswap
        uint256 lpAmount;
        // Vault address in NFTX v2
        address vTokenV2;
        // If underlying vault NFT is ERC1155
        bool is1155;
        // Encoded permit signature for sushiPair
        bytes permitSig;
        // Vault id in NFTX v3
        uint256 vaultIdV3;
        // Add liquidity params for NFTX AMM:
        int24 tickLower;
        int24 tickUpper;
        uint24 fee;
        // this price is used if new pool needs to be initialized
        uint160 sqrtPriceX96;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    uint256 private constant DEADLINE =
        0xf000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant DUST_THRESHOLD = 0.005 ether;
    uint256 private constant V2_VTOKEN_DUST = 100; // 100 wei

    IWETH9 public immutable WETH;
    INFTXVaultFactoryV2 public immutable v2NFTXFactory;
    INFTXInventoryStakingV2 public immutable v2Inventory;
    IUniswapV2Router02 public immutable sushiRouter;
    INonfungiblePositionManager public immutable positionManager;
    INFTXVaultFactoryV3 public immutable v3NFTXFactory;
    INFTXInventoryStakingV3 public immutable v3Inventory;

    // =============================================================
    //                            ERRORS
    // =============================================================

    error InvalidSignatureLength();

    // =============================================================
    //                           INIT
    // =============================================================

    constructor(
        IWETH9 WETH_,
        INFTXVaultFactoryV2 v2NFTXFactory_,
        INFTXInventoryStakingV2 v2Inventory_,
        IUniswapV2Router02 sushiRouter_,
        INonfungiblePositionManager positionManager_,
        INFTXVaultFactoryV3 v3NFTXFactory_,
        INFTXInventoryStakingV3 v3Inventory_
    ) {
        WETH = WETH_;
        v2NFTXFactory = v2NFTXFactory_;
        v2Inventory = v2Inventory_;
        sushiRouter = sushiRouter_;
        positionManager = positionManager_;
        v3NFTXFactory = v3NFTXFactory_;
        v3Inventory = v3Inventory_;

        WETH_.approve(address(positionManager_), type(uint256).max);
    }

    // =============================================================
    //                     PUBLIC / EXTERNAL WRITE
    // =============================================================

    /**
     * @notice Migrates liquidity from Sushiswap to NFTX AMM
     */
    function sushiToNFTXAMM(
        SushiToNFTXAMMParams calldata params
    ) external returns (uint256 positionId) {
        if (params.permitSig.length > 0) {
            _permit(params.sushiPair, params.lpAmount, params.permitSig);
        }

        uint256 wethBalance;
        address vTokenV3;
        uint256 vTokenV3Balance;
        {
            // withdraw liquidity from Sushiswap
            uint256 vTokenV2Balance;
            (vTokenV2Balance, wethBalance) = _withdrawFromSushi(
                params.sushiPair,
                params.lpAmount,
                params.vTokenV2
            );

            // convert v2 to v3 vault tokens
            uint256 wethReceived;
            (vTokenV3, vTokenV3Balance, wethReceived) = _v2ToV3Vault(
                params.vTokenV2,
                vTokenV2Balance,
                params.vaultIdV3,
                params.is1155,
                0 // passing zero here as `positionManager.mint` takes this into account via `amount0Min` or `amount1Min`
            );
            wethBalance += wethReceived;
        }

        bool isVTokenV30 = vTokenV3 < address(WETH);
        (
            address token0,
            address token1,
            uint256 amount0,
            uint256 amount1
        ) = isVTokenV30
                ? (vTokenV3, address(WETH), vTokenV3Balance, wethBalance)
                : (address(WETH), vTokenV3, wethBalance, vTokenV3Balance);

        // deploy new pool if it doesn't yet exist
        positionManager.createAndInitializePoolIfNecessary(
            token0,
            token1,
            params.fee,
            params.sqrtPriceX96
        );

        // give vToken approval to positionManager
        TransferLib.unSafeMaxApprove(
            vTokenV3,
            address(positionManager),
            vTokenV3Balance
        );

        // provide liquidity to NFTX AMM
        uint256 newAmount0;
        uint256 newAmount1;
        (positionId, , newAmount0, newAmount1) = positionManager.mint(
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: params.fee,
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: params.amount0Min,
                amount1Min: params.amount1Min,
                recipient: msg.sender,
                deadline: params.deadline
            })
        );

        // refund any dust left
        if (newAmount0 < amount0) {
            IERC20(token0).transfer(msg.sender, amount0 - newAmount0);
        }
        if (newAmount1 < amount1) {
            IERC20(token1).transfer(msg.sender, amount1 - newAmount1);
        }
    }

    /**
     * @notice Move vTokens from v2 Inventory to v3 Inventory (minting xNFT)
     * @dev Must give xToken approval before calling this function
     */
    function v2InventoryToXNFT(
        uint256 vaultIdV2,
        uint256 shares,
        bool is1155,
        uint256 vaultIdV3,
        uint256 minWethToReceive
    ) external returns (uint256 xNFTId) {
        address xToken = v2Inventory.vaultXToken(vaultIdV2);
        IERC20(xToken).transferFrom(msg.sender, address(this), shares);

        v2Inventory.withdraw(vaultIdV2, shares);
        address vTokenV2 = v2NFTXFactory.vault(vaultIdV2);
        uint256 vTokenV2Balance = IERC20(vTokenV2).balanceOf(address(this));

        // to account for rounding down when withdrawing xTokens to vTokens
        uint256 numNftsRedeemable = vTokenV2Balance / 1 ether;
        uint256 numNftsRedeemableAfterDust = (vTokenV2Balance +
            V2_VTOKEN_DUST) / 1 ether;

        if (numNftsRedeemableAfterDust > numNftsRedeemable) {
            // having few wei more of vTokens (100 wei at max) would result in redeeming one whole more NFT
            uint256 vTokensToBuy = numNftsRedeemableAfterDust *
                1 ether -
                vTokenV2Balance;
            // swapping ETH from this contract to get `vTokensToBuy`
            address[] memory path = new address[](2);
            path[0] = address(WETH);
            path[1] = vTokenV2;
            sushiRouter.swapETHForExactTokens{value: 1_000_000_000}(
                vTokensToBuy,
                path,
                address(this),
                block.timestamp
            );

            // update var to the latest balance
            vTokenV2Balance = IERC20(vTokenV2).balanceOf(address(this));
        }

        (
            address vTokenV3,
            uint256 vTokenV3Balance,
            uint256 wethReceived
        ) = _v2ToV3Vault(
                vTokenV2,
                vTokenV2Balance,
                vaultIdV3,
                is1155,
                minWethToReceive
            );
        if (wethReceived > 0) {
            WETH.transfer(msg.sender, wethReceived);
        }

        TransferLib.unSafeMaxApprove(
            vTokenV3,
            address(v3Inventory),
            vTokenV3Balance
        );
        xNFTId = v3Inventory.deposit(
            vaultIdV3,
            vTokenV3Balance,
            msg.sender,
            "",
            false,
            false
        );
    }

    /**
     * @notice Move v2 vTokens to v3 Inventory (minting xNFT)
     * @dev Must give v2 VToken approval before calling this function
     */
    function v2VaultToXNFT(
        address vTokenV2,
        uint256 vTokenV2Balance,
        bool is1155,
        uint256 vaultIdV3,
        uint256 minWethToReceive
    ) external returns (uint256 xNFTId) {
        IERC20(vTokenV2).transferFrom(
            msg.sender,
            address(this),
            vTokenV2Balance
        );

        (
            address vTokenV3,
            uint256 vTokenV3Balance,
            uint256 wethReceived
        ) = _v2ToV3Vault(
                vTokenV2,
                vTokenV2Balance,
                vaultIdV3,
                is1155,
                minWethToReceive
            );
        if (wethReceived > 0) {
            WETH.transfer(msg.sender, wethReceived);
        }

        TransferLib.unSafeMaxApprove(
            vTokenV3,
            address(v3Inventory),
            vTokenV3Balance
        );
        xNFTId = v3Inventory.deposit(
            vaultIdV3,
            vTokenV3Balance,
            msg.sender,
            "",
            false,
            false
        );
    }

    // =============================================================
    //                        ONLY OWNER WRITE
    // =============================================================

    function rescueTokens(address token) external onlyOwner {
        if (token != address(0)) {
            uint256 balance = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(msg.sender, balance);
        } else {
            uint256 balance = address(this).balance;
            TransferLib.transferETH(msg.sender, balance);
        }
    }

    // =============================================================
    //                        INTERNAL HELPERS
    // =============================================================

    function _permit(
        address sushiPair,
        uint256 lpAmount,
        bytes memory permitSig
    ) internal {
        if (permitSig.length != 65) revert InvalidSignatureLength();

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(permitSig, 32))
            s := mload(add(permitSig, 64))
            v := byte(0, mload(add(permitSig, 96)))
        }
        IUniswapV2Pair(sushiPair).permit(
            msg.sender,
            address(this),
            lpAmount,
            DEADLINE,
            v,
            r,
            s
        );
    }

    function _withdrawFromSushi(
        address sushiPair,
        uint256 lpAmount,
        address vTokenV2
    ) internal returns (uint256 vTokenV2Balance, uint256 wethBalance) {
        // burn sushi liquidity to this contract
        IUniswapV2Pair(sushiPair).transferFrom(msg.sender, sushiPair, lpAmount);
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(sushiPair).burn(
            address(this)
        );

        bool isVTokenV20 = vTokenV2 < address(WETH);

        (vTokenV2Balance, wethBalance) = isVTokenV20
            ? (amount0, amount1)
            : (amount1, amount0);
    }

    function _v2ToV3Vault(
        address vTokenV2,
        uint256 vTokenV2Balance,
        uint256 vaultIdV3,
        bool is1155,
        uint256 minWethToReceive
    )
        internal
        returns (
            address vTokenV3,
            uint256 vTokenV3Balance,
            uint256 wethReceived
        )
    {
        vTokenV3 = v3NFTXFactory.vault(vaultIdV3);

        // random redeem v2 vTokens. Directly transferring to the v3 vault
        uint256[] memory idsToRedeem;
        uint256[] memory idsRedeemed = INFTXVaultV2(vTokenV2).redeemTo(
            vTokenV2Balance / 1 ether,
            idsToRedeem,
            is1155 ? address(this) : vTokenV3
        );
        if (is1155) {
            IERC1155(INFTXVaultV3(vTokenV3).assetAddress()).setApprovalForAll(
                vTokenV3,
                true
            );
        }

        // fractional portion of vToken would be left
        vTokenV2Balance = vTokenV2Balance % 1 ether;

        // sell fractional portion for WETH
        if (vTokenV2Balance > DUST_THRESHOLD) {
            address[] memory path = new address[](2);
            path[0] = vTokenV2;
            path[1] = address(WETH);

            TransferLib.unSafeMaxApprove(
                vTokenV2,
                address(sushiRouter),
                vTokenV2Balance
            );
            wethReceived = sushiRouter.swapExactTokensForTokens(
                vTokenV2Balance,
                minWethToReceive,
                path,
                address(this),
                block.timestamp
            )[path.length - 1];
        } else if (vTokenV2Balance > 0) {
            // send back the vTokens as not worth the swap gas fees
            IERC20(vTokenV2).transfer(msg.sender, vTokenV2Balance);
        }

        // mint v3 vault tokens with the nfts received
        uint256[] memory amounts;
        if (is1155) {
            amounts = new uint256[](idsRedeemed.length);

            for (uint256 i; i < idsRedeemed.length; ) {
                amounts[i] = 1;

                unchecked {
                    ++i;
                }
            }
        }
        vTokenV3Balance = INFTXVaultV3(vTokenV3).mint(
            idsRedeemed,
            amounts,
            msg.sender,
            address(this)
        );
    }

    // To fund the zap with ETH to swap for missing vTokens during v2 redeem
    receive() external payable {}
}