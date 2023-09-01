// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { Ownable2StepUpgradeable } from "./Ownable2StepUpgradeable.sol";

library Ownable2StepStorage {

  struct Layout {
    address _pendingOwner;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.Ownable2Step');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import { Ownable2StepStorage } from "./Ownable2StepStorage.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    using Ownable2StepStorage for Ownable2StepStorage.Layout;
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return Ownable2StepStorage.layout()._pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        Ownable2StepStorage.layout()._pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete Ownable2StepStorage.layout()._pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { OwnableUpgradeable } from "./OwnableUpgradeable.sol";

library OwnableStorage {

  struct Layout {
    address _owner;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.Ownable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import { OwnableStorage } from "./OwnableStorage.sol";
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
    using OwnableStorage for OwnableStorage.Layout;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
        return OwnableStorage.layout()._owner;
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
        address oldOwner = OwnableStorage.layout()._owner;
        OwnableStorage.layout()._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";
import { InitializableStorage } from "./InitializableStorage.sol";

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
        bool isTopLevelCall = !InitializableStorage.layout()._initializing;
        require(
            (isTopLevelCall && InitializableStorage.layout()._initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && InitializableStorage.layout()._initialized == 1),
            "Initializable: contract is already initialized"
        );
        InitializableStorage.layout()._initialized = 1;
        if (isTopLevelCall) {
            InitializableStorage.layout()._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            InitializableStorage.layout()._initializing = false;
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
        require(!InitializableStorage.layout()._initializing && InitializableStorage.layout()._initialized < version, "Initializable: contract is already initialized");
        InitializableStorage.layout()._initialized = version;
        InitializableStorage.layout()._initializing = true;
        _;
        InitializableStorage.layout()._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(InitializableStorage.layout()._initializing, "Initializable: contract is not initializing");
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
        require(!InitializableStorage.layout()._initializing, "Initializable: contract is initializing");
        if (InitializableStorage.layout()._initialized < type(uint8).max) {
            InitializableStorage.layout()._initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return InitializableStorage.layout()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return InitializableStorage.layout()._initializing;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { Initializable } from "./Initializable.sol";

library InitializableStorage {

  struct Layout {
    /*
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 _initialized;

    /*
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool _initializing;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.Initializable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { PausableUpgradeable } from "./PausableUpgradeable.sol";

library PausableStorage {

  struct Layout {

    bool _paused;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.Pausable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import { PausableStorage } from "./PausableStorage.sol";
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
    using PausableStorage for PausableStorage.Layout;
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        PausableStorage.layout()._paused = false;
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
        return PausableStorage.layout()._paused;
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
        PausableStorage.layout()._paused = true;
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
        PausableStorage.layout()._paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { ERC721Upgradeable } from "./ERC721Upgradeable.sol";

library ERC721Storage {

  struct Layout {

    // Token name
    string _name;

    // Token symbol
    string _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) _owners;

    // Mapping owner address to token count
    mapping(address => uint256) _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.ERC721');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
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
import { ERC721Storage } from "./ERC721Storage.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using ERC721Storage for ERC721Storage.Layout;
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        ERC721Storage.layout()._name = name_;
        ERC721Storage.layout()._symbol = symbol_;
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
        return ERC721Storage.layout()._balances[owner];
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
        return ERC721Storage.layout()._name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return ERC721Storage.layout()._symbol;
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

        return ERC721Storage.layout()._tokenApprovals[tokenId];
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
        return ERC721Storage.layout()._operatorApprovals[owner][operator];
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
        return ERC721Storage.layout()._owners[tokenId];
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
            ERC721Storage.layout()._balances[to] += 1;
        }

        ERC721Storage.layout()._owners[tokenId] = to;

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
        delete ERC721Storage.layout()._tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            ERC721Storage.layout()._balances[owner] -= 1;
        }
        delete ERC721Storage.layout()._owners[tokenId];

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
        delete ERC721Storage.layout()._tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            ERC721Storage.layout()._balances[from] -= 1;
            ERC721Storage.layout()._balances[to] += 1;
        }
        ERC721Storage.layout()._owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        ERC721Storage.layout()._tokenApprovals[tokenId] = to;
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
        ERC721Storage.layout()._operatorApprovals[owner][operator] = approved;
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
                ERC721Storage.layout()._balances[from] -= batchSize;
            }
            if (to != address(0)) {
                ERC721Storage.layout()._balances[to] += batchSize;
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
pragma solidity ^0.8.0;

/**
 * @dev Info related to a specific organization. Think of organizations as systems/games. i.e. Bridgeworld, The Beacon, etc.
 * @param guildIdCur The next available guild id within this organization for newly created guilds
 * @param creationRule Describes who can create a guild within this organization
 * @param maxGuildsPerUser The number of guilds a user can join within the organization.
 * @param timeoutAfterLeavingGuild The timeout a user has before joining a new guild after being kicked or leaving another guild
 * @param tokenAddress The address of the 1155 token that represents guilds created within this organization
 * @param maxUsersPerGuildRule Indicates how the max number of users per guild is decided
 * @param maxUsersPerGuildConstant If maxUsersPerGuildRule is set to CONSTANT, this is the max
 * @param customGuildManagerAddress A contract address that handles custom guild creation requirements (i.e owning specific NFTs).
 *  This is used for guild creation if @param creationRule == CUSTOM_RULE
 */
struct GuildOrganizationInfo {
    uint32 guildIdCur;
    GuildCreationRule creationRule;
    uint8 maxGuildsPerUser;
    uint32 timeoutAfterLeavingGuild;
    // Slot 4 (202/256)
    address tokenAddress;
    MaxUsersPerGuildRule maxUsersPerGuildRule;
    uint32 maxUsersPerGuildConstant;
    bool requireTreasureTagForGuilds;
    // Slot 5 (160/256) - customGuildManagerAddress
    address customGuildManagerAddress;
}

/**
 * @dev Contains information about a user at the organization user.
 * @param guildsIdsAMemberOf A list of guild ids they are currently a member/admin/owner of. Excludes invitations
 * @param timeUserLeftGuild The time this user last left or was kicked from a guild. Useful for guild joining timeouts
 */
struct GuildOrganizationUserInfo {
    // Slot 1
    uint32[] guildIdsAMemberOf;
    // Slot 2 (64/256)
    uint64 timeUserLeftGuild;
}

/**
 * @dev Information about a guild within a given organization.
 * @param name The name of this guild
 * @param description A description of this guild
 * @param symbolImageData A symbol that represents this guild
 * @param isSymbolOnChain Indicates if symbolImageData is on chain or is a URL
 * @param currentOwner The current owner of this guild
 * @param usersInGuild Keeps track of the number of users in the guild. This includes MEMBER, ADMIN, and OWNER
 * @param guildStatus Current guild status (active or terminated)
 */
struct GuildInfo {
    // Slot 1
    string name;
    // Slot 2
    string description;
    // Slot 3
    string symbolImageData;
    // Slot 4 (168/256)
    bool isSymbolOnChain;
    address currentOwner;
    uint32 usersInGuild;
    // Slot 5
    mapping(address => GuildUserInfo) addressToGuildUserInfo;
    // Slot 6 (8/256)
    GuildStatus guildStatus;
}

/**
 * @dev Provides information regarding a user in a specific guild
 * @param userStatus Indicates the status of this user (i.e member, admin, invited)
 * @param timeUserJoined The time this user joined this guild
 * @param memberLevel The member level of this user
 */
struct GuildUserInfo {
    // Slot 1 (8+64+8/256)
    GuildUserStatus userStatus;
    uint64 timeUserJoined;
    uint8 memberLevel;
}

enum GuildUserStatus {
    NOT_ASSOCIATED,
    INVITED,
    MEMBER,
    ADMIN,
    OWNER
}

enum GuildCreationRule {
    ANYONE,
    ADMIN_ONLY,
    CUSTOM_RULE
}

enum MaxUsersPerGuildRule {
    CONSTANT,
    CUSTOM_RULE
}

enum GuildStatus {
    ACTIVE,
    TERMINATED
}

interface IGuildManager {
    /**
     * @dev Sets all necessary state and permissions for the contract
     * @param _guildTokenImplementationAddress The token implementation address for guild token contracts to proxy to
     */
    function GuildManager_init(address _guildTokenImplementationAddress) external;

    /**
     * @dev Creates a new guild within the given organization. Must pass the guild creation requirements.
     * @param _organizationId The organization to create the guild within
     */
    function createGuild(bytes32 _organizationId) external;

    /**
     * @dev Terminates a provided guild
     * @param _organizationId The organization of the guild
     * @param _guildId The guild to terminate
     * @param _reason The reason of termination for the guild
     */
    function terminateGuild(bytes32 _organizationId, uint32 _guildId, string calldata _reason) external;

    /**
     * @dev Grants a given user guild terminator priviliges under a certain guild
     * @param _account The user to give terminator
     * @param _organizationId The org they belong to
     * @param _guildId The guild they belong to
     */
    function grantGuildTerminator(address _account, bytes32 _organizationId, uint32 _guildId) external;

    /**
     * @dev Grants a given user guild admin priviliges under a certain guild
     * @param _account The user to give admin
     * @param _organizationId The org they belong to
     * @param _guildId The guild they belong to
     */
    function grantGuildAdmin(address _account, bytes32 _organizationId, uint32 _guildId) external;

    /**
     * @dev Updates the guild info for the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to update
     * @param _name The new name of the guild
     * @param _description The new description of the guild
     */
    function updateGuildInfo(
        bytes32 _organizationId,
        uint32 _guildId,
        string calldata _name,
        string calldata _description
    ) external;

    /**
     * @dev Updates the guild symbol for the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to update
     * @param _symbolImageData The new symbol for the guild
     * @param _isSymbolOnChain Indicates if symbolImageData is on chain or is a URL
     */
    function updateGuildSymbol(
        bytes32 _organizationId,
        uint32 _guildId,
        string calldata _symbolImageData,
        bool _isSymbolOnChain
    ) external;

    /**
     * @dev Adjusts a given users member level
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild the user is in
     * @param _user The user to adjust
     * @param _memberLevel The memberLevel to adjust to
     */
    function adjustMemberLevel(bytes32 _organizationId, uint32 _guildId, address _user, uint8 _memberLevel) external;

    /**
     * @dev Invites users to the given guild. Can only be done by admins or the guild owner.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to invite users to
     * @param _users The users to invite
     */
    function inviteUsers(bytes32 _organizationId, uint32 _guildId, address[] calldata _users) external;

    /**
     * @dev Accepts an invitation to the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to accept the invitation to
     */
    function acceptInvitation(bytes32 _organizationId, uint32 _guildId) external;

    /**
     * @dev Changes the admin status of the given users within the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to change the admin status of users within
     * @param _users The users to change the admin status of
     * @param _isAdmins Indicates if the users should be admins or not
     */
    function changeGuildAdmins(
        bytes32 _organizationId,
        uint32 _guildId,
        address[] calldata _users,
        bool[] calldata _isAdmins
    ) external;

    /**
     * @dev Changes the owner of the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to change the owner of
     * @param _newOwner The new owner of the guild
     */
    function changeGuildOwner(bytes32 _organizationId, uint32 _guildId, address _newOwner) external;

    /**
     * @dev Leaves the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to leave
     */
    function leaveGuild(bytes32 _organizationId, uint32 _guildId) external;

    /**
     * @dev Kicks or cancels any invites of the given users from the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to kick users from
     * @param _users The users to kick
     */
    function kickOrRemoveInvitations(bytes32 _organizationId, uint32 _guildId, address[] calldata _users) external;

    /**
     * @dev Returns the current status of a guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to get the status of
     */
    function getGuildStatus(bytes32 _organizationId, uint32 _guildId) external view returns (GuildStatus);

    /**
     * @dev Returns whether or not the given user can create a guild within the given organization.
     * @param _organizationId The organization to check
     * @param _user The user to check
     * @return Whether or not the user can create a guild within the given organization
     */
    function userCanCreateGuild(bytes32 _organizationId, address _user) external view returns (bool);

    /**
     * @dev Returns the membership status of the given user within the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to get the membership status of the user within
     * @param _user The user to get the membership status of
     * @return The membership status of the user within the guild
     */
    function getGuildMemberStatus(
        bytes32 _organizationId,
        uint32 _guildId,
        address _user
    ) external view returns (GuildUserStatus);

    /**
     * @dev Returns the guild user info struct of the given user within the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to get the info struct of the user within
     * @param _user The user to get the info struct of
     * @return The info struct of the user within the guild
     */
    function getGuildMemberInfo(
        bytes32 _organizationId,
        uint32 _guildId,
        address _user
    ) external view returns (GuildUserInfo memory);

    /**
     * @dev Initializes the Guild feature for the given organization.
     *  This can only be done by admins on the GuildManager contract.
     * @param _organizationId The id of the organization to initialize
     * @param _maxGuildsPerUser The maximum number of guilds a user can join within the organization.
     * @param _timeoutAfterLeavingGuild The number of seconds a user has to wait before being able to rejoin a guild
     * @param _guildCreationRule The rule for creating new guilds
     * @param _maxUsersPerGuildRule Indicates how the max number of users per guild is decided
     * @param _maxUsersPerGuildConstant If maxUsersPerGuildRule is set to CONSTANT, this is the max
     * @param _customGuildManagerAddress A contract address that handles custom guild creation requirements (i.e owning specific NFTs).
     * @param _requireTreasureTagForGuilds Whether this org requires a treasure tag for guilds
     *  This is used for guild creation if @param _guildCreationRule == CUSTOM_RULE
     */
    function initializeForOrganization(
        bytes32 _organizationId,
        uint8 _maxGuildsPerUser,
        uint32 _timeoutAfterLeavingGuild,
        GuildCreationRule _guildCreationRule,
        MaxUsersPerGuildRule _maxUsersPerGuildRule,
        uint32 _maxUsersPerGuildConstant,
        address _customGuildManagerAddress,
        bool _requireTreasureTagForGuilds
    ) external;

    /**
     * @dev Sets the max number of guilds a user can join within the organization.
     * @param _organizationId The id of the organization to set the max guilds per user for.
     * @param _maxGuildsPerUser The maximum number of guilds a user can join within the organization.
     */
    function setMaxGuildsPerUser(bytes32 _organizationId, uint8 _maxGuildsPerUser) external;

    /**
     * @dev Sets the cooldown period a user has to wait before joining a new guild within the organization.
     * @param _organizationId The id of the organization to set the guild joining timeout for.
     * @param _timeoutAfterLeavingGuild The cooldown period a user has to wait before joining a new guild within the organization.
     */
    function setTimeoutAfterLeavingGuild(bytes32 _organizationId, uint32 _timeoutAfterLeavingGuild) external;

    /**
     * @dev Sets the rule for creating new guilds within the organization.
     * @param _organizationId The id of the organization to set the guild creation rule for.
     * @param _guildCreationRule The rule that outlines how a user can create a new guild within the organization.
     */
    function setGuildCreationRule(bytes32 _organizationId, GuildCreationRule _guildCreationRule) external;

    /**
     * @dev Sets the max number of users per guild within the organization.
     * @param _organizationId The id of the organization to set the max number of users per guild for
     * @param _maxUsersPerGuildRule Indicates how the max number of users per guild is decided within the organization.
     * @param _maxUsersPerGuildConstant If maxUsersPerGuildRule is set to CONSTANT, this is the max.
     */
    function setMaxUsersPerGuild(
        bytes32 _organizationId,
        MaxUsersPerGuildRule _maxUsersPerGuildRule,
        uint32 _maxUsersPerGuildConstant
    ) external;

    /**
     * @dev Sets whether an org requires treasure tags for guilds
     * @param _organizationId The id of the organization to adjust
     * @param _requireTreasureTagForGuilds Whether treasure tags are required
     */
    function setRequireTreasureTagForGuilds(bytes32 _organizationId, bool _requireTreasureTagForGuilds) external;

    /**
     * @dev Sets the contract address that handles custom guild creation requirements (i.e owning specific NFTs).
     * @param _organizationId The id of the organization to set the custom guild manager address for
     * @param _customGuildManagerAddress The contract address that handles custom guild creation requirements (i.e owning specific NFTs).
     *  This is used for guild creation if the saved `guildCreationRule` == CUSTOM_RULE
     */
    function setCustomGuildManagerAddress(bytes32 _organizationId, address _customGuildManagerAddress) external;

    /**
     * @dev Sets the treasure tag nft address
     * @param _treasureTagNFTAddress The address of the treasure tag nft contract
     */
    function setTreasureTagNFTAddress(address _treasureTagNFTAddress) external;

    /**
     * @dev Retrieves the stored info for a given organization. Used to wrap the tuple from
     *  calling the mapping directly from external contracts
     * @param _organizationId The organization to return guild management info for
     * @return The stored guild settings for a given organization
     */
    function getGuildOrganizationInfo(bytes32 _organizationId) external view returns (GuildOrganizationInfo memory);

    /**
     * @dev Retrieves the token address for guilds within the given organization
     * @param _organizationId The organization to return the guild token address for
     * @return The token address for guilds within the given organization
     */
    function guildTokenAddress(bytes32 _organizationId) external view returns (address);

    /**
     * @dev Retrieves the token implementation address for guild token contracts to proxy to
     * @return The beacon token implementation address
     */
    function guildTokenImplementation() external view returns (address);

    /**
     * @dev Determines if the given guild is valid for the given organization
     * @param _organizationId The organization to verify against
     * @param _guildId The guild to verify
     * @return If the given guild is valid within the given organization
     */
    function isValidGuild(bytes32 _organizationId, uint32 _guildId) external view returns (bool);

    /**
     * @dev Get a given guild's name
     * @param _organizationId The organization to find the given guild within
     * @param _guildId The guild to retrieve the name from
     * @return The name of the given guild within the given organization
     */
    function guildName(bytes32 _organizationId, uint32 _guildId) external view returns (string memory);

    /**
     * @dev Get a given guild's description
     * @param _organizationId The organization to find the given guild within
     * @param _guildId The guild to retrieve the description from
     * @return The description of the given guild within the given organization
     */
    function guildDescription(bytes32 _organizationId, uint32 _guildId) external view returns (string memory);

    /**
     * @dev Get a given guild's symbol info
     * @param _organizationId The organization to find the given guild within
     * @param _guildId The guild to retrieve the symbol info from
     * @return symbolImageData_ The symbol data of the given guild within the given organization
     * @return isSymbolOnChain_ Whether or not the returned data is a URL or on-chain
     */
    function guildSymbolInfo(
        bytes32 _organizationId,
        uint32 _guildId
    ) external view returns (string memory symbolImageData_, bool isSymbolOnChain_);

    /**
     * @dev Retrieves the current owner for a given guild within a organization.
     * @param _organizationId The organization to find the guild within
     * @param _guildId The guild to return the owner of
     * @return The current owner of the given guild within the given organization
     */
    function guildOwner(bytes32 _organizationId, uint32 _guildId) external view returns (address);

    /**
     * @dev Retrieves the current owner for a given guild within a organization.
     * @param _organizationId The organization to find the guild within
     * @param _guildId The guild to return the maxMembers of
     * @return The current maxMembers of the given guild within the given organization
     */
    function maxUsersForGuild(bytes32 _organizationId, uint32 _guildId) external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BBase64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in BBase64
library LibBBase64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory _data) internal pure returns (string memory) {
        if (_data.length == 0) return "";

        // load the _table into memory
        string memory _table = TABLE;

        // multiply by 4/3 rounded up
        uint256 _encodedLen = 4 * ((_data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory _result = new string(_encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(_result, _encodedLen)

            // prepare the lookup _table
            let tablePtr := add(_table, 1)

            // input ptr
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))

            // _result ptr, jump over length
            let resultPtr := add(_result, 32)

            // run over the input, 3 bytes at a time
            for { } lt(dataPtr, endPtr) { } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(_data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return _result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { MetaTxFacetStorage } from "src/metatx/MetaTxFacetStorage.sol";

/// @title Library for handling meta transactions with the EIP2771 standard
/// @notice The logic for getting msgSender and msgData are were copied from OpenZeppelin's
///  ERC2771ContextUpgradeable contract
library LibMeta {
    struct Layout {
        address trustedForwarder;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.metatx");

    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }

    // =============================================================
    //                      State Helpers
    // =============================================================

    function isTrustedForwarder(address _forwarder) internal view returns (bool isTrustedForwarder_) {
        isTrustedForwarder_ = layout().trustedForwarder == _forwarder;
    }

    // =============================================================
    //                      Meta Tx Helpers
    // =============================================================

    /**
     * @dev The only valid forwarding contract is the one that is going to run the executing function
     */
    function _msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender_ := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender_ = msg.sender;
        }
    }

    /**
     * @dev The only valid forwarding contract is the one that is going to run the executing function
     */
    function _msgData() internal view returns (bytes calldata data_) {
        if (msg.sender == address(this)) {
            data_ = msg.data[:msg.data.length - 20];
        } else {
            data_ = msg.data;
        }
    }

    function getMetaDelegateAddress() internal view returns (address delegateAddress_) {
        return address(MetaTxFacetStorage.layout().systemDelegateApprover);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PausableStorage } from "@openzeppelin/contracts-diamond/security/PausableStorage.sol";
import { StringsUpgradeable } from "@openzeppelin/contracts-diamond/utils/StringsUpgradeable.sol";
import { LibMeta } from "./LibMeta.sol";

library LibUtilities {
    event Paused(address account);
    event Unpaused(address account);

    error ArrayLengthMismatch(uint256 len1, uint256 len2);

    error IsPaused();
    error NotPaused();

    // =============================================================
    //                      Array Helpers
    // =============================================================

    function requireArrayLengthMatch(uint256 _length1, uint256 _length2) internal pure {
        if (_length1 != _length2) {
            revert ArrayLengthMismatch(_length1, _length2);
        }
    }

    function asSingletonArray(uint256 _item) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](1);
        array_[0] = _item;
    }

    function asSingletonArray(string memory _item) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = _item;
    }

    // =============================================================
    //                     Misc Functions
    // =============================================================

    function compareStrings(string memory _a, string memory _b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((_a))) == keccak256(abi.encodePacked((_b))));
    }

    function setPause(bool _paused) internal {
        PausableStorage.layout()._paused = _paused;
        if (_paused) {
            emit Paused(LibMeta._msgSender());
        } else {
            emit Unpaused(LibMeta._msgSender());
        }
    }

    function paused() internal view returns (bool) {
        return PausableStorage.layout()._paused;
    }

    function requirePaused() internal view {
        if (!paused()) {
            revert NotPaused();
        }
    }

    function requireNotPaused() internal view {
        if (paused()) {
            revert IsPaused();
        }
    }

    function toString(uint256 _value) internal pure returns (string memory) {
        return StringsUpgradeable.toString(_value);
    }

    /**
     * @notice This function takes the first 4 MSB of the given bytes32 and converts them to _a bytes4
     * @dev This function is useful for grabbing function selectors from calldata
     * @param _inBytes The bytes to convert to bytes4
     */
    function convertBytesToBytes4(bytes memory _inBytes) internal pure returns (bytes4 outBytes4_) {
        if (_inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4_ := mload(add(_inBytes, 32))
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibBBase64 } from "src/libraries/LibBBase64.sol";
import { IGuildManager } from "src/interfaces/IGuildManager.sol";

/**
 * @notice The contract that handles validating meta transaction delegate approvals
 * @dev References to 'System' are synonymous with 'Organization'
 */
interface ISystemDelegateApprover {
    function isDelegateApprovedForSystem(
        address _account,
        bytes32 _systemId,
        address _delegate
    ) external view returns (bool);
    function setDelegateApprovalForSystem(bytes32 _systemId, address _delegate, bool _approved) external;
    function setDelegateApprovalForSystemBySignature(
        bytes32 _systemId,
        address _delegate,
        bool _approved,
        address _signer,
        uint256 _nonce,
        bytes calldata _signature
    ) external;
}

/**
 * @notice The struct used for signing and validating meta transactions
 * @dev from+nonce is packed to a single storage slot to save calldata gas on rollups
 * @param from The address that is being called on behalf of
 * @param nonce The nonce of the transaction. Used to prevent replay attacks
 * @param organizationId The id of the invoking organization
 * @param data The calldata of the function to be called
 */
struct ForwardRequest {
    address from;
    uint96 nonce;
    bytes32 organizationId;
    bytes data;
}

/**
 * @dev The typehash of the ForwardRequest struct used when signing the meta transaction
 *  This must match the ForwardRequest struct, and must not have extra whitespace or it will invalidate the signature
 */
bytes32 constant FORWARD_REQ_TYPEHASH =
    keccak256("ForwardRequest(address from,uint96 nonce,bytes32 organizationId,bytes data)");

library MetaTxFacetStorage {
    /**
     * @dev Emitted when an invalid delegate approver is provided or not allowed.
     */
    error InvalidDelegateApprover();

    /**
     * @dev Emitted when the `execute` function is called recursively, which is not allowed.
     */
    error CannotCallExecuteFromExecute();

    /**
     * @dev Emitted when the session organization ID is not consumed or processed as expected.
     */
    error SessionOrganizationIdNotConsumed();

    /**
     * @dev Emitted when there is a mismatch between the session organization ID and the function organization ID.
     * @param sessionOrganizationId The session organization ID
     * @param functionOrganizationId The function organization ID
     */
    error SessionOrganizationIdMismatch(bytes32 sessionOrganizationId, bytes32 functionOrganizationId);

    /**
     * @dev Emitted when a nonce has already been used for a specific sender address.
     * @param sender The address of the sender
     * @param nonce The nonce that has already been used
     */
    error NonceAlreadyUsedForSender(address sender, uint256 nonce);

    /**
     * @dev Emitted when the signer is not authorized to sign on behalf of the sender address.
     * @param signer The address of the signer
     * @param sender The address of the sender
     */
    error UnauthorizedSignerForSender(address signer, address sender);

    struct Layout {
        /**
         * @notice The delegate approver that tracks which wallet can run txs on behalf of the real sending account
         * @dev References to 'System' are synonymous with 'Organization'
         */
        ISystemDelegateApprover systemDelegateApprover;
        /**
         * @notice Tracks which nonces have been used by the from address. Prevents replay attacks.
         * @dev Key1: from address, Key2: nonce, Value: used or not
         */
        mapping(address => mapping(uint256 => bool)) nonces;
        /**
         * @dev The organization id of the session. Set before invoking a meta transaction and requires the function to clear it
         *  to ensure the session organization matches the function organizationId
         */
        bytes32 sessionOrganizationId;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.facet.metatx");

    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUpgradeable } from "@openzeppelin/contracts-diamond/utils/AddressUpgradeable.sol";
import { InitializableStorage } from "@openzeppelin/contracts-diamond/proxy/utils/InitializableStorage.sol";
import { FacetInitializableStorage } from "./FacetInitializableStorage.sol";
import { LibUtilities } from "../libraries/LibUtilities.sol";

/**
 * @title Initializable using DiamondStorage pattern and supporting facet-specific initializers
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract FacetInitializable {
    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     * Name changed to prevent collision with OZ contracts
     */
    modifier facetInitializer(bytes32 _facetId) {
        // Allow infinite constructor initializations to support multiple inheritance.
        // Otherwise, this contract/facet must not have been previously initialized.
        if (
            InitializableStorage.layout()._initializing
                ? !_isConstructor()
                : FacetInitializableStorage.getState().initialized[_facetId]
        ) {
            revert FacetInitializableStorage.AlreadyInitialized(_facetId);
        }
        bool _isTopLevelCall = !InitializableStorage.layout()._initializing;
        // Always set facet initialized regardless of if top level call or not.
        // This is so that we can run through facetReinitializable() if needed, and lower level functions can protect themselves
        FacetInitializableStorage.getState().initialized[_facetId] = true;

        if (_isTopLevelCall) {
            InitializableStorage.layout()._initializing = true;
        }

        _;

        if (_isTopLevelCall) {
            InitializableStorage.layout()._initializing = false;
        }
    }

    /**
     * @dev Modifier to trick internal functions that use onlyInitializing / onlyFacetInitializing into thinking
     *  that the contract is being initialized.
     *  This should only be called via a diamond initialization script and makes a lot of assumptions.
     *  Handle with care.
     */
    modifier facetReinitializable() {
        InitializableStorage.layout()._initializing = true;
        _;
        InitializableStorage.layout()._initializing = false;
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyFacetInitializing() {
        require(InitializableStorage.layout()._initializing, "FacetInit: not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Storage to track facets in a diamond that have been initialized.
 * Needed to prevent accidental re-initializations
 * Name changed to prevent collision with OZ contracts
 * OZ's Initializable storage handles all of the _initializing state, which isn't facet-specific
 */
library FacetInitializableStorage {
    error AlreadyInitialized(bytes32 facetId);

    struct Layout {
        /*
         * @dev Indicates that the contract/facet has been initialized.
         * bytes32 is the contract/facetId (keccak of the contract name)
         * bool is whether or not the contract/facet has been initialized
         */
        mapping(bytes32 => bool) initialized;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("spellcaster.storage.utils.FacetInitializable");

    function getState() internal pure returns (Layout storage l_) {
        bytes32 _position = STORAGE_SLOT;
        assembly {
            l_.slot := _position
        }
    }

    function isInitialized(bytes32 _facetId) internal view returns (bool isInitialized_) {
        isInitialized_ = getState().initialized[_facetId];
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      This is a reduced version of the library.
 */
pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
    uint256 private constant freeMemoryPtr = 0x40;
    uint256 private constant maskModulo32 = 0x1f;
    /**
     * Size of word read by `mload` instruction.
     */
    uint256 private constant memoryWord = 32;
    uint256 internal constant uint8Size = 1;
    uint256 internal constant uint16Size = 2;
    uint256 internal constant uint32Size = 4;
    uint256 internal constant uint64Size = 8;
    uint256 internal constant uint128Size = 16;
    uint256 internal constant uint256Size = 32;
    uint256 internal constant addressSize = 20;
    /**
     * Bits in 12 bytes.
     */
    uint256 private constant bytes12Bits = 96;

    function slice(bytes memory buffer, uint256 startIndex, uint256 length) internal pure returns (bytes memory) {
        unchecked {
            require(length + 31 >= length, "slice_overflow");
        }
        require(buffer.length >= startIndex + length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly ("memory-safe") {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(freeMemoryPtr)

            switch iszero(length)
            case 0 {
                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(length, maskModulo32)
                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let startOffset := add(lengthmod, mul(memoryWord, iszero(lengthmod)))

                let dst := add(tempBytes, startOffset)
                let end := add(dst, length)

                for { let src := add(add(buffer, startOffset), startIndex) } lt(dst, end) {
                    dst := add(dst, memoryWord)
                    src := add(src, memoryWord)
                } { mstore(dst, mload(src)) }

                // Update free-memory pointer
                // allocating the array padded to 32 bytes like the compiler does now
                // Note that negating bitwise the `maskModulo32` produces a mask that aligns addressing to 32 bytes.
                mstore(freeMemoryPtr, and(add(dst, maskModulo32), not(maskModulo32)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default { mstore(freeMemoryPtr, add(tempBytes, memoryWord)) }

            // Store the length of the buffer
            // We need to do it even if the length is zero because Solidity does not garbage collect
            mstore(tempBytes, length)
        }

        return tempBytes;
    }

    function toAddress(bytes memory buffer, uint256 startIndex) internal pure returns (address) {
        require(buffer.length >= startIndex + addressSize, "toAddress_outOfBounds");
        address tempAddress;

        assembly ("memory-safe") {
            // We want to shift into the lower 12 bytes and leave the upper 12 bytes clear.
            tempAddress := shr(bytes12Bits, mload(add(add(buffer, memoryWord), startIndex)))
        }

        return tempAddress;
    }

    function toUint8(bytes memory buffer, uint256 startIndex) internal pure returns (uint8) {
        require(buffer.length > startIndex, "toUint8_outOfBounds");

        // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
        uint256 startOffset = startIndex + uint8Size;
        uint8 tempUint;
        assembly ("memory-safe") {
            tempUint := mload(add(buffer, startOffset))
        }
        return tempUint;
    }

    function toUint16(bytes memory buffer, uint256 startIndex) internal pure returns (uint16) {
        uint256 endIndex = startIndex + uint16Size;
        require(buffer.length >= endIndex, "toUint16_outOfBounds");

        uint16 tempUint;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempUint := mload(add(buffer, endIndex))
        }
        return tempUint;
    }

    function toUint32(bytes memory buffer, uint256 startIndex) internal pure returns (uint32) {
        uint256 endIndex = startIndex + uint32Size;
        require(buffer.length >= endIndex, "toUint32_outOfBounds");

        uint32 tempUint;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempUint := mload(add(buffer, endIndex))
        }
        return tempUint;
    }

    function toUint64(bytes memory buffer, uint256 startIndex) internal pure returns (uint64) {
        uint256 endIndex = startIndex + uint64Size;
        require(buffer.length >= endIndex, "toUint64_outOfBounds");

        uint64 tempUint;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempUint := mload(add(buffer, endIndex))
        }
        return tempUint;
    }

    function toUint128(bytes memory buffer, uint256 startIndex) internal pure returns (uint128) {
        uint256 endIndex = startIndex + uint128Size;
        require(buffer.length >= endIndex, "toUint128_outOfBounds");

        uint128 tempUint;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempUint := mload(add(buffer, endIndex))
        }
        return tempUint;
    }

    function toUint256(bytes memory buffer, uint256 startIndex) internal pure returns (uint256) {
        uint256 endIndex = startIndex + uint256Size;
        require(buffer.length >= endIndex, "toUint256_outOfBounds");

        uint256 tempUint;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempUint := mload(add(buffer, endIndex))
        }
        return tempUint;
    }

    function toBytes32(bytes memory buffer, uint256 startIndex) internal pure returns (bytes32) {
        uint256 endIndex = startIndex + uint256Size;
        require(buffer.length >= endIndex, "toBytes32_outOfBounds");

        bytes32 tempBytes32;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempBytes32 := mload(add(buffer, endIndex))
        }
        return tempBytes32;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGen0 {
    function isStaked(uint256 tokenId) external view returns (bool);
    function stakeNft(uint256 tokenId) external;
    function unstakeNft(uint256 tokenId) external;

    event Staked(uint256 indexed tokenId);
    event Unstaked(uint256 indexed tokenId);

    event AllowUnstakingChanged(bool allow);
    event AllowStakingChanged(bool allow);
    event BaseUriChanged(string baseUri);
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.19;

interface IWormhole {
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;

        uint32 guardianSetIndex;
        Signature[] signatures;

        bytes32 hash;
    }

    struct ContractUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        address newContract;
    }

    struct GuardianSetUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        GuardianSet newGuardianSet;
        uint32 newGuardianSetIndex;
    }

    struct SetMessageFee {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 messageFee;
    }

    struct TransferFees {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 amount;
        bytes32 recipient;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;

        uint256 evmChainId;
        uint16 newChainId;
    }

    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);
    event ContractUpgraded(address indexed oldContract, address indexed newContract);
    event GuardianSetAdded(uint32 indexed index);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function initialize() external;

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (VM memory vm, bool valid, string memory reason);

    function verifyVM(VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Signature[] memory signatures, GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason);

    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

    function quorum(uint numGuardians) external pure returns (uint numSignaturesRequiredForQuorum);

    function getGuardianSet(uint32 index) external view returns (GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);

    function evmChainId() external view returns (uint256);

    function nextSequence(address emitter) external view returns (uint64);

    function parseContractUpgrade(bytes memory encodedUpgrade) external pure returns (ContractUpgrade memory cu);

    function parseGuardianSetUpgrade(bytes memory encodedUpgrade) external pure returns (GuardianSetUpgrade memory gsu);

    function parseSetMessageFee(bytes memory encodedSetMessageFee) external pure returns (SetMessageFee memory smf);

    function parseTransferFees(bytes memory encodedTransferFees) external pure returns (TransferFees memory tf);

    function parseRecoverChainId(bytes memory encodedRecoverChainId) external pure returns (RecoverChainId memory rci);

    function submitContractUpgrade(bytes memory _vm) external;

    function submitSetMessageFee(bytes memory _vm) external;

    function submitNewGuardianSet(bytes memory _vm) external;

    function submitTransferFees(bytes memory _vm) external;

    function submitRecoverChainId(bytes memory _vm) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IGen0 } from "@spellcaster-core/misc/kaijucards/IGen0.sol";
import { LibKaijuCardsGen0Storage } from "@spellcaster-core/misc/kaijucards/LibKaijuCardsGen0Storage.sol";
import { NftBurnBridgingBase, IWormhole } from "@spellcaster-core/misc/kaijucards/NftBurnBridgingBase.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC721/ERC721Upgradeable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-diamond/access/Ownable2StepUpgradeable.sol";
import { StringsUpgradeable } from "@openzeppelin/contracts-diamond/utils/StringsUpgradeable.sol";
import { FacetInitializable } from "@spellcaster/utils/FacetInitializable.sol";

contract KaijuCardsGen0 is IGen0, ERC721Upgradeable, NftBurnBridgingBase, Ownable2StepUpgradeable {
    // Disable implementation contract
    constructor() facetInitializer(keccak256("KaijuCardsGen0_init")) {}

    function KaijuCardsGen0_init(
        IWormhole _wormhole,
        uint16 _emitterChainId,
        bytes32 _emitterAddress
    ) external facetInitializer(keccak256("KaijuCardsGen0_init")) {
        __NftBurnBridgingBase_init(_wormhole, _emitterChainId, _emitterAddress);
        __ERC721_init("KaijuCardsGen0", "KC0");
        __Ownable2Step_init();

        LibKaijuCardsGen0Storage.Layout storage _l = LibKaijuCardsGen0Storage.layout();
        _l.allowStaking = true;
        _l.allowUnstaking = false;
        _l.baseUri = "https://assets.kaijucards.io/json/";
    }

    function isStaked(uint256 _tokenId) external view override returns (bool) {
        return LibKaijuCardsGen0Storage.layout().tokenIsStaked[_tokenId];
    }

    function stakeNft(uint256 _tokenId) public {
        LibKaijuCardsGen0Storage.Layout storage _l = LibKaijuCardsGen0Storage.layout();
        bool _isStaked = _l.tokenIsStaked[_tokenId];
        address owner = _ownerOf(_tokenId);

        require(_l.allowStaking, "Staking is not allowed at this time.");
        require(!_isStaked, "KaijuCardsGen0: token is already staked.");
        require(owner == msg.sender, "KaijuCardsGen0: caller is not owner.");

        _l.tokenIsStaked[_tokenId] = true;
        emit Staked(_tokenId);
    }

    function unstakeNft(uint256 _tokenId) public {
        LibKaijuCardsGen0Storage.Layout storage _l = LibKaijuCardsGen0Storage.layout();
        bool _isStaked = _l.tokenIsStaked[_tokenId];
        address owner = _ownerOf(_tokenId);

        require(_isStaked, "KaijuCardsGen0: token is not staked.");
        require(owner == msg.sender, "KaijuCardsGen0: caller is not owner.");
        require(_l.allowUnstaking, "Unstaking is not yet allowed at this time.");

        _l.tokenIsStaked[_tokenId] = false;
        emit Unstaked(_tokenId);
    }

    function batchStakeNfts(uint256[] calldata _tokenIds) external {
        uint256 _numTokens = _tokenIds.length;
        for (uint256 i = 0; i < _numTokens; i++) {
            stakeNft(_tokenIds[i]);
        }
    }

    function batchUnstakeNfts(uint256[] calldata _tokenIds) external {
        uint256 _numTokens = _tokenIds.length;
        for (uint256 i = 0; i < _numTokens; i++) {
            unstakeNft(_tokenIds[i]);
        }
    }

    function setAllowUnstaking(bool _allow) external onlyOwner {
        LibKaijuCardsGen0Storage.layout().allowUnstaking = _allow;
        emit AllowUnstakingChanged(_allow);
    }

    function setAllowStaking(bool _allow) external onlyOwner {
        LibKaijuCardsGen0Storage.layout().allowStaking = _allow;
        emit AllowStakingChanged(_allow);
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        LibKaijuCardsGen0Storage.layout().baseUri = _uri;
        emit BaseUriChanged(_uri);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory tokenUri_) {
        string memory _charPrefix = getCharPrefixFromId(_tokenId);
        uint256 _reducedTokenId = _tokenId % LibKaijuCardsGen0Storage.CHARACTER_TOKEN_OFFSET_AMOUNT;
        tokenUri_ = string.concat(LibKaijuCardsGen0Storage.layout().baseUri, _charPrefix, "-", StringsUpgradeable.toString(_reducedTokenId), ".json");
    }

    function supportsInterface(bytes4 _interfaceId) public view override returns (bool) {
        return _interfaceId == type(IGen0).interfaceId || super.supportsInterface(_interfaceId);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _firstTokenId,
        uint256 _batchSize
    ) internal override {
        LibKaijuCardsGen0Storage.Layout storage _l = LibKaijuCardsGen0Storage.layout();
        // Will most likely be called with _batchSize = 1, however if needed it will support the consecutive token transfers
        for (uint i = 0; i < _batchSize; i++) {
            if(_l.tokenIsStaked[_firstTokenId + i]) {
                revert LibKaijuCardsGen0Storage.TokenIsStaked(_firstTokenId + i);
            }
        }

        super._beforeTokenTransfer(_from, _to, _firstTokenId, _batchSize);
    }

    function _safeMint(address _to, uint256 _tokenId) internal virtual override(ERC721Upgradeable, NftBurnBridgingBase) {
        ERC721Upgradeable._safeMint(_to, _tokenId);
    }

    function getCharPrefixFromId(uint256 _tokenId) internal pure returns (string memory charPrefix_) {
        uint256 _charPrefixOffset = _tokenId / LibKaijuCardsGen0Storage.CHARACTER_TOKEN_OFFSET_AMOUNT;
        if(_charPrefixOffset == 1) {
            charPrefix_ = "bd";
        } else if(_charPrefixOffset == 2) {
            charPrefix_ = "bo";
        } else if(_charPrefixOffset == 3) {
            charPrefix_ = "bs";
        } else if(_charPrefixOffset == 4) {
            charPrefix_ = "bu";
        } else if(_charPrefixOffset == 5) {
            charPrefix_ = "fk";
        } else if(_charPrefixOffset == 6) {
            charPrefix_ = "fw";
        } else if(_charPrefixOffset == 7) {
            charPrefix_ = "gd";
        } else if(_charPrefixOffset == 8) {
            charPrefix_ = "gh";
        } else if(_charPrefixOffset == 9) {
            charPrefix_ = "gj";
        } else if(_charPrefixOffset == 10) {
            charPrefix_ = "gw";
        } else if(_charPrefixOffset == 11) {
            charPrefix_ = "je";
        } else if(_charPrefixOffset == 12) {
            charPrefix_ = "ll";
        } else if(_charPrefixOffset == 13) {
            charPrefix_ = "mf";
        } else if(_charPrefixOffset == 14) {
            charPrefix_ = "mgc";
        } else if(_charPrefixOffset == 15) {
            charPrefix_ = "mi";
        } else if(_charPrefixOffset == 16) {
            charPrefix_ = "nb";
        } else if(_charPrefixOffset == 17) {
            charPrefix_ = "ow";
        } else if(_charPrefixOffset == 18) {
            charPrefix_ = "pk";
        } else if(_charPrefixOffset == 19) {
            charPrefix_ = "sn";
        } else if(_charPrefixOffset == 20) {
            charPrefix_ = "sawo";
        } else if(_charPrefixOffset == 21) {
            charPrefix_ = "sw";
        } else if(_charPrefixOffset == 22) {
            charPrefix_ = "th";
        } else if(_charPrefixOffset == 23) {
            charPrefix_ = "tof";
        } else if(_charPrefixOffset == 24) {
            charPrefix_ = "wa";
        } else if(_charPrefixOffset == 25) {
            charPrefix_ = "wg";
        } else {
            revert LibKaijuCardsGen0Storage.UnknownTokenId(_tokenId);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LibKaijuCardsGen0Storage library
 * @notice This library contains the storage layout and events/errors for the KaijuCardsGen0Facet contract.
 */
library LibKaijuCardsGen0Storage {
    struct Layout {
        /**
         * @dev Mapping of token ID to staked status
         */
        mapping(uint256 => bool) tokenIsStaked;
        /**
         * @dev Whether staking can be performed
         */
        bool allowStaking;
        /**
         * @dev Whether unstaking can be performed
         */
        bool allowUnstaking;
        /**
         * @dev Base URI for token URIs
         */
        string baseUri;
    }

    uint256 internal constant CHARACTER_TOKEN_OFFSET_AMOUNT = 100_000;

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.bridging.KaijuCardsGen0");

    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }

    error TokenIsStaked(uint256 tokenId);
    error UnknownTokenId(uint256 tokenId);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@spellcaster-core/misc/kaijucards/IWormhole.sol";

/**
 * @title LibNftBurnBridgingBaseStorage library
 * @notice This library contains the storage layout and events/errors for the NftBurnBridgingBaseFacet contract.
 */
library LibNftBurnBridgingBaseStorage {
    struct Layout {
        //Core layer Wormhole contract
        IWormhole wormhole;
        //Only VAAs emitted from this Wormhole chain id can mint NFTs
        uint16 emitterChainId;
        //Only VAAs from this emitter can mint NFTs
        bytes32 emitterAddress;
        //VAA hash => claimed flag dictionary to prevent minting from the same VAA twice
        // (e.g. to prevent mint -> burn -> remint)
        mapping(bytes32 => bool) claimedVaas;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.bridging.NftBurnBridgingBase");

    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }

    error WrongEmitterChainId();
    error WrongEmitterAddress();
    error FailedVaaParseAndVerification(string reason);
    error VaaAlreadyClaimed();
    error InvalidMessageLength();

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@spellcaster-core/misc/kaijucards/IWormhole.sol";
import "@spellcaster-core/misc/kaijucards/BytesLib.sol";

import { FacetInitializable } from "@spellcaster/utils/FacetInitializable.sol";
import { LibNftBurnBridgingBaseStorage } from "@spellcaster-core/misc/kaijucards/LibNftBurnBridgingBaseStorage.sol";

/**
 * @title  A minimal contract that sets up and implements the Wormhole messaging bridge to 1-way mint an NFT that is assumed to have been burned on the source chain.
 * @notice Modified version of https://github.com/wormhole-foundation/wormhole-scaffolding/blob/main/evm/src/03_nft_burn_bridging/NftBurnBridging.sol
 *  to not need the ERC721 definition and change the size of the tokenIds being passed in
 */
abstract contract NftBurnBridgingBase is FacetInitializable {
    using BytesLib for bytes;

    function __NftBurnBridgingBase_init(IWormhole _wormhole, uint16 _emitterChainId, bytes32 _emitterAddress) internal {
        LibNftBurnBridgingBaseStorage.Layout storage _l = LibNftBurnBridgingBaseStorage.layout();
        _l.wormhole = _wormhole;
        _l.emitterChainId = _emitterChainId;
        _l.emitterAddress = _emitterAddress;
    }

    /**
     * @dev Assuming that the NFT contract will implement this function to avoid a lot of NFT context in what is effectively a wormhole messaging library
     * @param _to The recipient of the NFT that was parsed from the vaa
     * @param _tokenId The token ID of the NFT that was parsed from the vaa
     */
    function _safeMint(address _to, uint256 _tokenId) internal virtual;

    /**
     * @dev The emitter address is the derived public key related to the vaa message. This is to avoid using unexpected vaa messages to mint NFTs
     * @param _wormholeChainId The chain ID of the Wormhole contract that emitted the VAA
     */
    function getEmitterAddress(uint16 _wormholeChainId) external view returns (bytes32) {
        LibNftBurnBridgingBaseStorage.Layout storage _l = LibNftBurnBridgingBaseStorage.layout();
        return (_wormholeChainId == _l.emitterChainId) ? _l.emitterAddress : bytes32(0);
    }

    /**
     * @dev Validates the VAA against our saved emitter address, then assumes the message is comprised of 32 bits for the tokenId and 160 bits for the recipient address
     * @param _vaa The VAA that was emitted by the Wormhole contract. Needs to be parsed to get the message emitter to validate authenticity of the message
     */
    function receiveAndMint(bytes calldata _vaa) external {
        LibNftBurnBridgingBaseStorage.Layout storage _l = LibNftBurnBridgingBaseStorage.layout();
        (IWormhole.VM memory _vm, bool _valid, string memory _reason) = _l.wormhole.parseAndVerifyVM(_vaa);

        if (!_valid) {
            revert LibNftBurnBridgingBaseStorage.FailedVaaParseAndVerification(_reason);
        }

        if (_vm.emitterChainId != _l.emitterChainId) {
            revert LibNftBurnBridgingBaseStorage.WrongEmitterChainId();
        }

        if (_vm.emitterAddress != _l.emitterAddress) {
            revert LibNftBurnBridgingBaseStorage.WrongEmitterAddress();
        }

        if (_l.claimedVaas[_vm.hash]) {
            revert LibNftBurnBridgingBaseStorage.VaaAlreadyClaimed();
        }

        _l.claimedVaas[_vm.hash] = true;

        (uint256 _tokenId, address _evmRecipient) = parsePayload(_vm.payload);
        _safeMint(_evmRecipient, _tokenId);
    }

    /**
     * @dev Validates that the message size is exactly 192 bits (32 bits for the tokenId and 160 bits for the recipient address)
     * @param _message The message that was parsed from the VAA
     * @return tokenId_ The tokenId that was parsed from the message
     * @return evmRecipient_ The recipient address that was parsed from the message
     */
    function parsePayload(bytes memory _message) internal pure returns (uint256 tokenId_, address evmRecipient_) {
        if (_message.length != BytesLib.uint32Size + BytesLib.addressSize) {
            revert LibNftBurnBridgingBaseStorage.InvalidMessageLength();
        }

        tokenId_ = _message.toUint32(0);
        evmRecipient_ = _message.toAddress(BytesLib.uint32Size);
    }
}