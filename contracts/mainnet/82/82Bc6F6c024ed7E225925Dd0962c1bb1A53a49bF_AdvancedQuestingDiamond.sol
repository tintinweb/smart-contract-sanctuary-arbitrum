// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./AdvancedQuestingDiamondState.sol";
import "./IAdvancedQuestingInternal.sol";

contract AdvancedQuestingDiamond is Initializable, AdvancedQuestingDiamondState {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function initialize() external initializer {
        AdvancedQuestingDiamondState.__AdvancedQuestingDiamondState_init();
    }

    function startAdvancedQuesting(LibAdvancedQuestingDiamond.StartQuestParams[] calldata _params)
    external
    whenNotPaused
    onlyEOA
    {
        require(_params.length > 0, "No start quest params given");

        for(uint256 i = 0; i < _params.length; i++) {
            _startAdvancedQuesting(_params[i], false);
        }
    }

    function _startAdvancedQuesting(LibAdvancedQuestingDiamond.StartQuestParams memory _startQuestParams, bool _isRestarting) private {
        uint256 _legionId = _startQuestParams.legionId;

        require(!isLegionQuesting(_legionId), "Legion is already questing");
        require(isValidZone(_startQuestParams.zoneName), "Invalid zone");

        LegionMetadata memory _legionMetadata = appStorage.legionMetadataStore.metadataForLegion(_legionId);

        if(_legionMetadata.legionGeneration == LegionGeneration.RECRUIT) {
            _startAdvancedQuestingRecruit(_startQuestParams, _isRestarting);
        } else {
            _startAdvancedQuestingRegular(_startQuestParams, _isRestarting, _legionMetadata);
        }
    }

    function _startAdvancedQuestingRecruit(LibAdvancedQuestingDiamond.StartQuestParams memory _startQuestParams, bool _isRestarting) private {
        require(_startQuestParams.advanceToPart == 1, "Bad recruit part");

        require(_startQuestParams.treasureIds.length == 0 && _startQuestParams.treasureAmounts.length == 0,
            "Recruits cannot take treasures");

        uint256 _requestId = _createRequestAndSaveData(_startQuestParams);

        _transferLegionAndTreasures(_startQuestParams, _isRestarting);

        appStorage.numRecruitsQuesting++;

        emit AdvancedQuestStarted(
            msg.sender,
            _requestId,
            _startQuestParams);
    }

    function _startAdvancedQuestingRegular(LibAdvancedQuestingDiamond.StartQuestParams memory _startQuestParams, bool _isRestarting, LegionMetadata memory _legionMetadata) private {

        uint256 _numberOfParts = appStorage.zoneNameToInfo[_startQuestParams.zoneName].parts.length;
        require(_startQuestParams.advanceToPart > 0 && _startQuestParams.advanceToPart <= _numberOfParts,
            "Invalid advance to part");

        bool _willPlayTreasureTriad = false;

        // Need to check that they have the correct level to advance through the given parts of the quest.
        for(uint256 i = 0; i < _startQuestParams.advanceToPart; i++) {
            uint8 _levelRequirement = appStorage.zoneNameToInfo[_startQuestParams.zoneName].parts[i].questingLevelRequirement;

            require(_legionMetadata.questLevel >= _levelRequirement, "Legion not high enough questing level");

            bool _treasureTriadOnThisPart = appStorage.zoneNameToInfo[_startQuestParams.zoneName].parts[i].playTreasureTriad;

            _willPlayTreasureTriad = _willPlayTreasureTriad || _treasureTriadOnThisPart;

            // Also, if a part has a treasure triad game and it is not the last part, they cannot auto advance past it.
            if(i < _startQuestParams.advanceToPart - 1 && _treasureTriadOnThisPart) {

                revert("Cannot advanced past a part that requires treasure triad");
            }
        }

        require(_startQuestParams.treasureIds.length == _startQuestParams.treasureAmounts.length
            && (!_willPlayTreasureTriad || _startQuestParams.treasureIds.length > 0),
            "Bad treasure lengths");

        uint256 _totalTreasureAmounts = 0;
        uint8 _maxConstellationRank = _maxConstellationRankForLegionAndZone(_startQuestParams.zoneName, _legionMetadata);

        for(uint256 i = 0; i < _startQuestParams.treasureIds.length; i++) {
            require(_startQuestParams.treasureIds[i] > 0 && _startQuestParams.treasureAmounts[i] > 0);

            _totalTreasureAmounts += _startQuestParams.treasureAmounts[i];

            require(_totalTreasureAmounts <= _maxConstellationRank, "Too many treasures");
        }

        uint256 _requestId = _createRequestAndSaveData(_startQuestParams);

        _saveStakedTreasures(_startQuestParams);

        _transferLegionAndTreasures(_startQuestParams, _isRestarting);

        appStorage.numQuesting++;

        emit AdvancedQuestStarted(
            msg.sender,
            _requestId,
            _startQuestParams);
    }

    function _transferLegionAndTreasures(LibAdvancedQuestingDiamond.StartQuestParams memory _startQuestParams, bool _isRestarting) private {
        if(_isRestarting) {
            return;
        }

        // Transfer legion and treasure to this contract.
        appStorage.legion.adminSafeTransferFrom(msg.sender, address(this), _startQuestParams.legionId);

        if(_startQuestParams.treasureIds.length > 0) {
            appStorage.treasure.safeBatchTransferFrom(
                msg.sender,
                address(this),
                _startQuestParams.treasureIds,
                _startQuestParams.treasureAmounts,
                "");
        }
    }

    function _createRequestAndSaveData(LibAdvancedQuestingDiamond.StartQuestParams memory _startQuestParams) private returns(uint256) {
        uint256 _legionId = _startQuestParams.legionId;
        uint256 _requestId = appStorage.randomizer.requestRandomNumber();

        appStorage.legionIdToLegionQuestingInfoV2[_legionId].startTime = uint120(block.timestamp);
        appStorage.legionIdToLegionQuestingInfoV2[_legionId].requestId = uint80(_requestId);
        appStorage.legionIdToLegionQuestingInfoV2[_legionId].zoneName = _startQuestParams.zoneName;
        appStorage.legionIdToLegionQuestingInfoV2[_legionId].owner = msg.sender;
        appStorage.legionIdToLegionQuestingInfoV2[_legionId].advanceToPart = _startQuestParams.advanceToPart;
        appStorage.legionIdToLegionQuestingInfoV2[_legionId].currentPart = 0;
        appStorage.legionIdToLegionQuestingInfoV2[_legionId].corruptionAmount = appStorage.corruption.balanceOf(address(this));
        delete appStorage.legionIdToLegionQuestingInfoV2[_legionId].timeTriadWasPlayed;
        delete appStorage.legionIdToLegionQuestingInfoV2[_legionId].corruptedCellsRemainingForCurrentPart;
        delete appStorage.legionIdToLegionQuestingInfoV2[_legionId].cardsFlipped;

        return _requestId;
    }

    function _saveStakedTreasures(
        LibAdvancedQuestingDiamond.StartQuestParams memory _startQuestParams)
    private
    {
        LibAdvancedQuestingDiamond.Treasures memory _treasures;

        uint256 _numberOfTreasures = _startQuestParams.treasureIds.length;
        _treasures.numberOfTypesOfTreasures = uint8(_numberOfTreasures);

        if(_numberOfTreasures > 0) {
            _treasures.treasure1Id = uint16(_startQuestParams.treasureIds[0]);
            _treasures.treasure1Amount = uint8(_startQuestParams.treasureAmounts[0]);
        }
        if(_numberOfTreasures > 1) {
            _treasures.treasure2Id = uint16(_startQuestParams.treasureIds[1]);
            _treasures.treasure2Amount = uint8(_startQuestParams.treasureAmounts[1]);
        }
        if(_numberOfTreasures > 2) {
            _treasures.treasure3Id = uint16(_startQuestParams.treasureIds[2]);
            _treasures.treasure3Amount = uint8(_startQuestParams.treasureAmounts[2]);
        }
        if(_numberOfTreasures > 3) {
            _treasures.treasure4Id = uint16(_startQuestParams.treasureIds[3]);
            _treasures.treasure4Amount = uint8(_startQuestParams.treasureAmounts[3]);
        }
        if(_numberOfTreasures > 4) {
            _treasures.treasure5Id = uint16(_startQuestParams.treasureIds[4]);
            _treasures.treasure5Amount = uint8(_startQuestParams.treasureAmounts[4]);
        }
        if(_numberOfTreasures > 5) {
            _treasures.treasure6Id = uint16(_startQuestParams.treasureIds[5]);
            _treasures.treasure6Amount = uint8(_startQuestParams.treasureAmounts[5]);
        }
        if(_numberOfTreasures > 6) {
            _treasures.treasure7Id = uint16(_startQuestParams.treasureIds[6]);
            _treasures.treasure7Amount = uint8(_startQuestParams.treasureAmounts[6]);
        }

        for(uint256 i = 0; i < _numberOfTreasures; i++) {
            for(uint256 j = i + 1; j < _numberOfTreasures; j++) {
                require(_startQuestParams.treasureIds[i] != _startQuestParams.treasureIds[j],
                    "Duplicate treasure id in array");
            }
        }

        appStorage.legionIdToLegionQuestingInfoV2[_startQuestParams.legionId].treasures = _treasures;
    }

    // Ends questing at the current part. Must have played triad if triad is required on current part.
    function endQuesting(
        uint256[] calldata _legionIds,
        bool[] calldata _restartQuesting)
    external
    whenNotPaused
    onlyEOA
    nonZeroLength(_legionIds)
    {
        require(_legionIds.length == _restartQuesting.length, "Bad array lengths");
        for(uint256 i = 0; i < _legionIds.length; i++) {
            _endQuesting(_legionIds[i], _restartQuesting[i]);
        }
    }

    function _endQuesting(uint256 _legionId, bool _restartQuesting) private {
        bool _usingOldSchema = _isUsingOldSchema(_legionId);

        string memory _zoneName = _activeZoneForLegion(_usingOldSchema, _legionId);

        LegionMetadata memory _legionMetadata = appStorage.legionMetadataStore.metadataForLegion(_legionId);
        LibAdvancedQuestingDiamond.ZoneInfo storage _zoneInfo = appStorage.zoneNameToInfo[_zoneName];

        require(_ownerForLegion(_usingOldSchema, _legionId) == msg.sender, "Legion is not yours");

        uint256 _randomNumber = appStorage.randomizer.revealRandomNumber(_requestIdForLegion(_usingOldSchema, _legionId));

        _ensureDoneWithCurrentPart(_legionId, _zoneName, _usingOldSchema, _legionMetadata, _zoneInfo, _randomNumber, true);

        _endQuestingPostValidation(_legionId, _usingOldSchema, _legionMetadata, _zoneInfo, _randomNumber, _restartQuesting);
    }

    function _endQuestingPostValidation(
        uint256 _legionId,
        bool _usingOldSchema,
        LegionMetadata memory _legionMetadata,
        LibAdvancedQuestingDiamond.ZoneInfo storage _zoneInfo,
        uint256 _randomNumber,
        bool _isRestarting)
    private
    {
        uint8 _endingPart = _advanceToPartForLegion(_usingOldSchema, _legionId);

        AdvancedQuestReward[] memory _earnedRewards;
        if(_legionMetadata.legionGeneration == LegionGeneration.RECRUIT) {
            // Level up recruit
            LibAdvancedQuestingDiamond.RecruitPartInfo storage _recruitPartInfo = appStorage.zoneNameToPartIndexToRecruitPartInfo[_activeZoneForLegion(_usingOldSchema, _legionId)][_endingPart - 1];

            if(_recruitPartInfo.recruitXPGained > 0) {
                appStorage.recruitLevel.increaseRecruitExp(_legionId, _recruitPartInfo.recruitXPGained);
            }

            _earnedRewards = _getRecruitEarnedRewards(_recruitPartInfo, _randomNumber, _legionId);

            appStorage.numRecruitsQuesting--;
        } else {
            appStorage.questing.processQPGainAndLevelUp(_legionId, _legionMetadata.questLevel, appStorage.endingPartToQPGained[_endingPart]);

            _earnedRewards = _getEarnedRewards(
                _legionId,
                _usingOldSchema,
                _endingPart,
                _zoneInfo,
                _legionMetadata,
                _randomNumber);

            if(_startTimeForLegion(_usingOldSchema, _legionId) > appStorage.timePoolsFirstSet) {
                appStorage.numQuesting--;
            }
        }

        // Only need to delete the start time to save on gas. Acts as a flag if the legion is questing.
        // When startQuesting is called all LegionQuestingInfo fields will be overridden.
        if(_usingOldSchema) {
            delete appStorage.legionIdToLegionQuestingInfoV1[_legionId].startTime;
        } else {
            delete appStorage.legionIdToLegionQuestingInfoV2[_legionId].startTime;
        }

        if(!_isRestarting) {
            // Send back legion and treasure
            appStorage.legion.adminSafeTransferFrom(address(this), msg.sender, _legionId);
        }

        (uint256[] memory _treasureIds, uint256[] memory _treasureAmounts) = IAdvancedQuestingInternal(address(this)).unstakeTreasures(_legionId, _usingOldSchema, _isRestarting, msg.sender);

        emit AdvancedQuestEnded(msg.sender, _legionId, _earnedRewards);

        if(_isRestarting) {
            _startAdvancedQuesting(LibAdvancedQuestingDiamond.StartQuestParams(_legionId, _activeZoneForLegion(_usingOldSchema, _legionId), _endingPart, _treasureIds, _treasureAmounts), _isRestarting);
        }
    }

    function _getRecruitEarnedRewards(LibAdvancedQuestingDiamond.RecruitPartInfo storage _recruitPartInfo, uint256 _randomNumber, uint256 _legionId) private returns(AdvancedQuestReward[] memory) {
        // The returned random number was used for stasis calculations. Scramble the number with a constant.
        _randomNumber = uint256(keccak256(abi.encode(_randomNumber,
            7647295972771752179227871979083739911846583376458796885201641052640283607576)));

        AdvancedQuestReward[] memory _rewards = new AdvancedQuestReward[](4);

        if(_recruitPartInfo.numEoS > 0) {
            appStorage.consumable.mint(msg.sender, EOS_ID, _recruitPartInfo.numEoS);

            _rewards[0].consumableId = EOS_ID;
            _rewards[0].consumableAmount = _recruitPartInfo.numEoS;
        }

        if(_recruitPartInfo.numShards > 0) {
            appStorage.consumable.mint(msg.sender, PRISM_SHARD_ID, _recruitPartInfo.numShards);

            _rewards[1].consumableId = PRISM_SHARD_ID;
            _rewards[1].consumableAmount = _recruitPartInfo.numShards;
        }

        RecruitType _recruitType = appStorage.recruitLevel.recruitType(_legionId);

        (,, uint32 _positiveTreasureBonus, uint32 _negativeTreasureBonus) = _getCorruptionEffects(appStorage.legionIdToLegionQuestingInfoV2[_legionId].corruptionAmount);

        bool _fragmentReceived = appStorage.masterOfInflation.tryMintFromPool(MintFromPoolParams(
            appStorage.tierToRecruitPoolId[5],
            1,
            (_recruitType != RecruitType.NONE ? appStorage.cadetRecruitFragmentBoost : 0) + _positiveTreasureBonus,
            _recruitPartInfo.fragmentId,
            _randomNumber,
            msg.sender,
            _negativeTreasureBonus
        ));

        if(_fragmentReceived) {
            _rewards[2].treasureFragmentId = _recruitPartInfo.fragmentId;
        }

        if(_recruitPartInfo.chanceUniversalLock > 0) {
            _randomNumber = uint256(keccak256(abi.encodePacked(_randomNumber, _randomNumber)));

            uint256 _result = _randomNumber % 100000;

            if(_result < _recruitPartInfo.chanceUniversalLock) {
                appStorage.consumable.mint(msg.sender, 10, 1);

                _rewards[3].consumableId = 10;
                _rewards[3].consumableAmount = 1;
            }
        }

        return _rewards;
    }

    // A helper method. Was running into stack too deep errors.
    // Helps remove some of the local variables. Just enough to compile.
    function _getEarnedRewards(
        uint256 _legionId,
        bool _usingOldSchema,
        uint8 _endingPart,
        LibAdvancedQuestingDiamond.ZoneInfo storage _zoneInfo,
        LegionMetadata memory _legionMetadata,
        uint256 _randomNumber)
    private
    returns(AdvancedQuestReward[] memory)
    {
        return _distributeRewards(
            _activeZoneForLegion(_usingOldSchema, _legionId),
            _endingPart - 1,
            _zoneInfo.parts[_endingPart - 1],
            _legionMetadata,
            _randomNumber,
            _cardsFlippedForLegion(_usingOldSchema, _legionId),
            appStorage.legionIdToLegionQuestingInfoV2[_legionId].corruptionAmount
        );
    }

    function _distributeRewards(
        string memory _zoneName,
        uint256 _partIndex,
        LibAdvancedQuestingDiamond.ZonePart storage _endingPart,
        LegionMetadata memory _legionMetadata,
        uint256 _randomNumber,
        uint8 _cardsFlipped,
        uint256 _corruptionBalance)
    private
    returns(AdvancedQuestReward[] memory)
    {
        // The returned random number was used for stasis calculations. Scramble the number with a constant.
        _randomNumber = uint256(keccak256(abi.encode(_randomNumber,
            17647295972771752179227871979083739911846583376458796885201641052640283607576)));

        uint256 _legionGeneration = uint256(_legionMetadata.legionGeneration);
        uint256 _legionRarity = uint256(_legionMetadata.legionRarity);

        // Add 5 to the array length. 1 for the universal lock check, and 4 for potential rewards from multiple fragment tiers
        //
        AdvancedQuestReward[] memory _earnedRewards = new AdvancedQuestReward[](_endingPart.rewards.length + 5);
        uint256 _rewardIndexCur = 0;

        for(uint256 i = 0; i < _endingPart.rewards.length; i++) {
            LibAdvancedQuestingDiamond.ZoneReward storage _reward = _endingPart.rewards[i];

            uint256 _oddsBoost = uint256(_reward.generationToRarityToBoost[_legionGeneration][_legionRarity])
                + (uint256(_reward.boostPerFlippedCard) * uint256(_cardsFlipped))
                + appStorage.zoneNameToPartIndexToRewardIndexToQuestBoosts[_zoneName][_partIndex][i][_legionMetadata.questLevel];

            // This is the treasure fragment reward.
            // Go to the master of inflation contract instead of using the base odds here.
            //
            if(_reward.rewardOptions[0].treasureFragmentId > 0) {
                for(uint256 j = 0; j < _reward.rewardOptions.length; j++) {
                    if(_tryMintFragment(
                        _reward.rewardOptions[j].treasureFragmentId,
                        _oddsBoost,
                        _randomNumber,
                        msg.sender,
                        _corruptionBalance
                    ))
                    {
                        _earnedRewards[_rewardIndexCur] = AdvancedQuestReward(0, 0, _reward.rewardOptions[j].treasureFragmentId, 0);
                        if(j != _reward.rewardOptions.length - 1) {
                            _rewardIndexCur++;
                        }
                    }

                    _randomNumber = uint256(keccak256(abi.encodePacked(_randomNumber, _randomNumber)));
                }
            } else {
                uint256 _odds = uint256(_reward.baseRateRewardOdds) + _oddsBoost;

                bool _hitReward;

                if(_odds >= 255) {
                    _hitReward = true;
                } else if(_odds > 0) {
                    if(_randomNumber % 256 < _odds) {
                        _hitReward = true;
                    }
                    _randomNumber >>= 8;
                }

                if(_hitReward) {
                    _earnedRewards[_rewardIndexCur] = _mintHitReward(_pickRewardFromOptions(_randomNumber, _reward), _randomNumber, msg.sender);

                    _randomNumber >>= 8;
                }
            }

            _rewardIndexCur++;
        }

        // Check for universal lock win
        if(appStorage.chanceUniversalLock > 0) {
            _randomNumber = uint256(keccak256(abi.encodePacked(_randomNumber, _randomNumber)));

            uint256 _result = _randomNumber % 100000;

            if(_result < appStorage.chanceUniversalLock) {
                appStorage.consumable.mint(msg.sender, 10, 1);

                _earnedRewards[_earnedRewards.length - 1] = AdvancedQuestReward(10, 1, 0, 0);
            }
        }

        return _earnedRewards;
    }

    function _tryMintFragment(
        uint256 _treasureFragmentId,
        uint256 _oddsBoost,
        uint256 _randomNumber,
        address _owner,
        uint256 _corruptionBalance
    ) private returns(bool) {
        (,, uint32 _positiveTreasureBonus, uint32 _negativeTreasureBonus) = _getCorruptionEffects(_corruptionBalance);

        return appStorage.masterOfInflation.tryMintFromPool(MintFromPoolParams(
            appStorage.tierToPoolId[getTierForFragmentId(_treasureFragmentId)],
            1,
            // Odds boost is out of 256, but masterOfInflation expected out of 100,000
            uint32((_oddsBoost * 100000) / 256) + _positiveTreasureBonus,
            _treasureFragmentId,
            _randomNumber,
            _owner,
            _negativeTreasureBonus
        ));
    }

    function _mintHitReward(
        LibAdvancedQuestingDiamond.ZoneRewardOption storage _zoneRewardOption,
        uint256 _randomNumber,
        address _owner)
    private
    returns(AdvancedQuestReward memory _earnedReward)
    {
        if(_zoneRewardOption.consumableId > 0 && _zoneRewardOption.consumableAmount > 0) {
            _earnedReward.consumableId = _zoneRewardOption.consumableId;
            _earnedReward.consumableAmount = _zoneRewardOption.consumableAmount;

            appStorage.consumable.mint(
                _owner,
                _zoneRewardOption.consumableId,
                _zoneRewardOption.consumableAmount);
        }

        if(_zoneRewardOption.treasureFragmentId > 0) {
            _earnedReward.treasureFragmentId = _zoneRewardOption.treasureFragmentId;

            appStorage.treasureFragment.mint(
                _owner,
                _zoneRewardOption.treasureFragmentId,
                1);
        }

        if(_zoneRewardOption.treasureTier > 0) {
            uint256 _treasureId = appStorage.treasureMetadataStore.getRandomTreasureForTierAndCategory(
                _zoneRewardOption.treasureTier,
                _zoneRewardOption.treasureCategory,
                _randomNumber);

            _earnedReward.treasureId = _treasureId;

            appStorage.treasure.mint(
                _owner,
                _treasureId,
                1);
        }
    }

    function _pickRewardFromOptions(
        uint256 _randomNumber,
        LibAdvancedQuestingDiamond.ZoneReward storage _zoneReward)
    private
    view
    returns(LibAdvancedQuestingDiamond.ZoneRewardOption storage)
    {
        // Gas optimization. Only run random calculations for rewards with more than 1 option.
        if(_zoneReward.rewardOptions.length == 1) {
            return _zoneReward.rewardOptions[0];
        }

        uint256 _result = _randomNumber % 256;
        uint256 _topRange = 0;

        _randomNumber >>= 8;

        for(uint256 j = 0; j < _zoneReward.rewardOptions.length; j++) {
            LibAdvancedQuestingDiamond.ZoneRewardOption storage _zoneRewardOption = _zoneReward.rewardOptions[j];
            _topRange += _zoneRewardOption.rewardOdds;

            if(_result < _topRange) {
                // Got this reward!
                return _zoneRewardOption;
            }
        }

        revert("Bad odds for zone reward");
    }

    function playTreasureTriad(
        PlayTreasureTriadParams[] calldata _params)
    external
    whenNotPaused
    onlyEOA
    {
        require(_params.length > 0, "Bad array length");
        for(uint256 i = 0; i < _params.length; i++) {
            _playTreasureTriad(_params[i].legionId, _params[i].playerMoves, _params[i].restartQuestIfPossible);
        }
    }

    function _playTreasureTriad(uint256 _legionId, UserMove[] calldata _playerMoves, bool _restartQuestingIfPossible) private {

        bool _usingOldSchema = _isUsingOldSchema(_legionId);
        string memory _zoneName = _activeZoneForLegion(_usingOldSchema, _legionId);

        LegionMetadata memory _legionMetadata = appStorage.legionMetadataStore.metadataForLegion(_legionId);
        LibAdvancedQuestingDiamond.ZoneInfo storage _zoneInfo = appStorage.zoneNameToInfo[_zoneName];

        require(_ownerForLegion(_usingOldSchema, _legionId) == msg.sender, "Legion is not yours");

        uint256 _randomNumber = appStorage.randomizer.revealRandomNumber(_requestIdForLegion(_usingOldSchema, _legionId));

        // Don't check for triad as they will be playing it right now.
        _ensureDoneWithCurrentPart(_legionId, _zoneName, _usingOldSchema, _legionMetadata, _zoneInfo, _randomNumber, false);

        _validatePlayerHasTreasuresForMoves(_playerMoves, _usingOldSchema, _legionId);

        GameOutcome memory _outcome = appStorage.treasureTriad.generateBoardAndPlayGame(
            _legionId,
            _legionMetadata.legionClass,
            _playerMoves);

        // Timestamp used to verify they have played and to calculate the length of stasis post game.
        if(_usingOldSchema) {
            appStorage.legionIdToLegionQuestingInfoV1[_legionId].triadOutcome.timeTriadWasPlayed = block.timestamp;
            appStorage.legionIdToLegionQuestingInfoV1[_legionId].triadOutcome.corruptedCellsRemainingForCurrentPart = _outcome.numberOfCorruptedCardsLeft;
            appStorage.legionIdToLegionQuestingInfoV1[_legionId].triadOutcome.cardsFlipped = _outcome.numberOfFlippedCards;
        } else {
            appStorage.legionIdToLegionQuestingInfoV2[_legionId].timeTriadWasPlayed = uint120(block.timestamp);
            appStorage.legionIdToLegionQuestingInfoV2[_legionId].corruptedCellsRemainingForCurrentPart = _outcome.numberOfCorruptedCardsLeft;
            appStorage.legionIdToLegionQuestingInfoV2[_legionId].cardsFlipped = _outcome.numberOfFlippedCards;
        }

        emit TreasureTriadPlayed(msg.sender, _legionId, _outcome.playerWon, _outcome.numberOfFlippedCards, _outcome.numberOfCorruptedCardsLeft);

        // If there are any corrupted cards left, they will be stuck in stasis and cannot end now.
        if(_outcome.numberOfCorruptedCardsLeft == 0 || !appStorage.generationToCanHaveStasis[_legionMetadata.legionGeneration]) {
            _endQuestingPostValidation(_legionId, _usingOldSchema, _legionMetadata, _zoneInfo, _randomNumber, _restartQuestingIfPossible);
        }
    }

    function _validatePlayerHasTreasuresForMoves(
        UserMove[] calldata _playerMoves,
        bool _usingOldSchema,
        uint256 _legionId)
    private
    view
    {
        // Before sending to the treasure triad contract, ensure they have staked the treasures and can play them.
        // The treasure triad contract will handle the game logic, and validating that the player moves are valid.
        require(_playerMoves.length > 0 && _playerMoves.length < 4, "Bad number of treasure triad moves");

        // Worst case, they have 3 different treasures.
        Treasure[] memory _treasures = new Treasure[](_playerMoves.length);
        uint256 _treasureIndex = 0;

        for(uint256 i = 0; i < _playerMoves.length; i++) {
            uint256 _treasureIdForMove = _playerMoves[i].treasureId;

            uint256 _treasureAmountStaked = _getTreasureAmountStaked(_treasureIdForMove, _usingOldSchema, _legionId);

            bool _foundLocalTreasure = false;

            for(uint256 k = 0; k < _treasures.length; k++) {
                if(_treasures[k].id == _treasureIdForMove) {
                    _foundLocalTreasure = true;
                    if(_treasures[k].amount == 0) {
                        revert("Used more treasure than what was staked");
                    } else {
                        _treasures[k].amount--;
                    }
                    break;
                }
            }

            if(!_foundLocalTreasure) {
                _treasures[_treasureIndex] = Treasure(_treasureIdForMove, _treasureAmountStaked - 1);
                _treasureIndex++;
            }
        }
    }

    function _getTreasureAmountStaked(
        uint256 _treasureIdForMove,
        bool _usingOldSchema,
        uint256 _legionId)
    private
    view
    returns(uint256)
    {
        if(_usingOldSchema) {
            require(appStorage.legionIdToLegionQuestingInfoV1[_legionId].treasureIds.contains(_treasureIdForMove),
                "Cannot play treasure that was not staked");

            return appStorage.legionIdToLegionQuestingInfoV1[_legionId].treasureIdToAmount[_treasureIdForMove];
        } else {
            LibAdvancedQuestingDiamond.Treasures memory _treasures = appStorage.legionIdToLegionQuestingInfoV2[_legionId].treasures;

            require(_treasureIdForMove > 0);

            if(_treasures.treasure1Id == _treasureIdForMove) {
                return _treasures.treasure1Amount;
            } else if(_treasures.treasure2Id == _treasureIdForMove) {
                return _treasures.treasure2Amount;
            } else if(_treasures.treasure3Id == _treasureIdForMove) {
                return _treasures.treasure3Amount;
            } else if(_treasures.treasure4Id == _treasureIdForMove) {
                return _treasures.treasure4Amount;
            } else if(_treasures.treasure5Id == _treasureIdForMove) {
                return _treasures.treasure5Amount;
            } else if(_treasures.treasure6Id == _treasureIdForMove) {
                return _treasures.treasure6Amount;
            } else if(_treasures.treasure7Id == _treasureIdForMove) {
                return _treasures.treasure7Amount;
            } else {
                revert("Cannot play treasure that was not staked");
            }
        }
    }

    function endTimeForLegions(uint256[] calldata _legionIds) external view returns(uint256[] memory _endTimes) {
        _endTimes = new uint256[](_legionIds.length);

        for(uint256 i = 0; i < _legionIds.length; i++) {
           (uint256 _endTime,) = endTimeForLegion(_legionIds[i]);
           _endTimes[i] = _endTime;
        }
    }

    // Returns the end time for the legion and the number of stasis hit in all the parts of the zone.
    // If the legion is waiting through stasis caused by corrupt cards in treasure triad, the second number will be the number of cards remaining.
    function endTimeForLegion(uint256 _legionId) public view returns(uint256, uint8) {
        LegionMetadata memory _legionMetadata = appStorage.legionMetadataStore.metadataForLegion(_legionId);

        bool _usingOldSchema = _isUsingOldSchema(_legionId);

        uint8 _maxConstellationRank = _maxConstellationRankForLegionAndZone(
            _activeZoneForLegion(_usingOldSchema, _legionId),
            _legionMetadata);

        uint256 _randomNumber = appStorage.randomizer.revealRandomNumber(_requestIdForLegion(_usingOldSchema, _legionId));

        return _endTimeForLegion(_legionId, _usingOldSchema, _activeZoneForLegion(_usingOldSchema, _legionId), _legionMetadata, _maxConstellationRank, _randomNumber);
    }

    function getN(uint64 _poolId) external view returns(uint256) {
        if(appStorage.tierToRecruitPoolId[5] == _poolId) {
            return appStorage.numRecruitsQuesting;
        } else {
            return appStorage.numQuesting;
        }
    }

    function getTierForFragmentId(uint256 _fragmentId) private pure returns(uint8 _tier) {
        _tier = uint8(_fragmentId % 5);

        if(_tier == 0) {
            _tier = 5;
        }
    }
}

struct Treasure {
    uint256 id;
    uint256 amount;
}

struct PlayTreasureTriadParams {
    uint256 legionId;
    UserMove[] playerMoves;
    bool restartQuestIfPossible;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

import "../../shared/randomizer/IRandomizer.sol";
import "./IAdvancedQuestingDiamond.sol";
import "../../shared/AdminableUpgradeable.sol";
import "./LibAdvancedQuestingDiamond.sol";

abstract contract AdvancedQuestingDiamondState is Initializable, AdminableUpgradeable, ERC721HolderUpgradeable, ERC1155HolderUpgradeable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    event AdvancedQuestStarted(address _owner, uint256 _requestId, LibAdvancedQuestingDiamond.StartQuestParams _startQuestParams);
    event AdvancedQuestContinued(address _owner, uint256 _legionId, uint256 _requestId, uint8 _toPart);
    event TreasureTriadPlayed(address _owner, uint256 _legionId, bool _playerWon, uint8 _numberOfCardsFlipped, uint8 _numberOfCorruptedCardsRemaining);
    event AdvancedQuestEnded(address _owner, uint256 _legionId, AdvancedQuestReward[] _rewards);
    event QPForEndingPart(uint8 _endingPart, uint256 _qpGained);

    // Recruit events
    event SetCadetRecruitFragmentBoost(uint32 _cadetRecruitFragmentBoost);
    event SetSuccessSensitivityRecruitFragments(uint256 _successSensitivityRecruitFragments);
    event SetRecruitFragmentsDivider(uint256 _recruitFragmentsDivider);
    event SetRecruitPartInfo(string _zoneName, uint256 _zonePart, LibAdvancedQuestingDiamond.RecruitPartInfo _partInfo);

    // Used for event. Free to change
    struct AdvancedQuestReward {
        uint256 consumableId;
        uint256 consumableAmount;
        uint256 treasureFragmentId; // Assumed to be 1.
        uint256 treasureId; // Assumed to be 1.
    }

    uint256 constant EOS_ID = 8;
    uint256 constant PRISM_SHARD_ID = 9;

    LibAdvancedQuestingDiamond.AppStorage internal appStorage;

    function __AdvancedQuestingDiamondState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
        ERC721HolderUpgradeable.__ERC721Holder_init();
        ERC1155HolderUpgradeable.__ERC1155Holder_init();

        appStorage.stasisLengthForCorruptedCard = 1 days;

        appStorage.generationToCanHaveStasis[LegionGeneration.GENESIS] = false;
        appStorage.generationToCanHaveStasis[LegionGeneration.AUXILIARY] = true;

        appStorage.maxConstellationRankToReductionInStasis[1] = 10;
        appStorage.maxConstellationRankToReductionInStasis[2] = 15;
        appStorage.maxConstellationRankToReductionInStasis[3] = 20;
        appStorage.maxConstellationRankToReductionInStasis[4] = 23;
        appStorage.maxConstellationRankToReductionInStasis[5] = 38;
        appStorage.maxConstellationRankToReductionInStasis[6] = 51;
        appStorage.maxConstellationRankToReductionInStasis[7] = 64;

        appStorage.endingPartToQPGained[1] = 10;
        appStorage.endingPartToQPGained[2] = 20;
        appStorage.endingPartToQPGained[3] = 40;
        emit QPForEndingPart(1, 10);
        emit QPForEndingPart(2, 20);
        emit QPForEndingPart(3, 40);
    }

    function isValidZone(string memory _zoneName) public view returns(bool) {
        return appStorage.zoneNameToInfo[_zoneName].zoneStartTime > 0;
    }

    function _isUsingOldSchema(uint256 _legionId) internal view returns(bool) {
        return appStorage.legionIdToLegionQuestingInfoV1[_legionId].startTime > 0;
    }

    function _activeZoneForLegion(bool _useOldSchema, uint256 _legionId) internal view returns(string storage) {
        return _useOldSchema
            ? appStorage.legionIdToLegionQuestingInfoV1[_legionId].zoneName
            : appStorage.legionIdToLegionQuestingInfoV2[_legionId].zoneName;
    }

    function _ownerForLegion(bool _useOldSchema, uint256 _legionId) internal view returns(address) {
        return _useOldSchema
            ? appStorage.legionIdToLegionQuestingInfoV1[_legionId].owner
            : appStorage.legionIdToLegionQuestingInfoV2[_legionId].owner;
    }

    function _requestIdForLegion(bool _useOldSchema, uint256 _legionId) internal view returns(uint256) {
        return _useOldSchema
            ? appStorage.legionIdToLegionQuestingInfoV1[_legionId].requestId
            : appStorage.legionIdToLegionQuestingInfoV2[_legionId].requestId;
    }

    function _advanceToPartForLegion(bool _useOldSchema, uint256 _legionId) internal view returns(uint8) {
        return _useOldSchema
            ? appStorage.legionIdToLegionQuestingInfoV1[_legionId].advanceToPart
            : appStorage.legionIdToLegionQuestingInfoV2[_legionId].advanceToPart;
    }

    function _hasTreasuresStakedForLegion(bool _useOldSchema, uint256 _legionId) internal view returns(bool) {
        return _useOldSchema
            ? appStorage.legionIdToLegionQuestingInfoV1[_legionId].treasureIds.length() > 0
            : appStorage.legionIdToLegionQuestingInfoV2[_legionId].treasures.treasure1Id > 0;
    }

    function isLegionQuesting(uint256 _legionId) public view returns(bool) {
        return appStorage.legionIdToLegionQuestingInfoV1[_legionId].startTime > 0
            || appStorage.legionIdToLegionQuestingInfoV2[_legionId].startTime > 0;
    }

    // Ensures the legion is done with the current part they are on.
    // This includes checking the end time and making sure they played treasure triad.
    function _ensureDoneWithCurrentPart(
        uint256 _legionId,
        string memory _zoneName,
        bool _usingOldSchema,
        LegionMetadata memory _legionMetadata,
        LibAdvancedQuestingDiamond.ZoneInfo storage _zoneInfo,
        uint256 _randomNumber,
        bool _checkPlayedTriad)
    internal
    view
    {
        uint8 _maxConstellationRank = _maxConstellationRankForLegionAndZone(
            _zoneName,
            _legionMetadata);

        // Handles checking if the legion is questing or not. Will revert if not.
        // Handles checking if stasis random is ready. Will revert if not.
        (uint256 _endTime,) = _endTimeForLegion(_legionId, _usingOldSchema, _zoneName, _legionMetadata, _maxConstellationRank, _randomNumber);
        require(block.timestamp >= _endTime, "Legion has not finished this part of the zone yet");

        // Triad played check. Only need to check the last part as _startAdvancedQuesting would have reverted
        // if they tried to skip past a triad played check.
        if(_checkPlayedTriad
            && _zoneInfo.parts[_advanceToPartForLegion(_usingOldSchema, _legionId) - 1].playTreasureTriad
            && _triadPlayTimeForLegion(_usingOldSchema, _legionId) == 0) {

            revert("Has not played treasure triad for current part");
        }
    }

    function _endTimeForLegion(
        uint256 _legionId,
        bool _usingOldSchema,
        string memory _zoneName,
        LegionMetadata memory _legionMetadata,
        uint8 _maxConstellationRank,
        uint256 _randomNumber)
    internal
    view
    returns(uint256 _endTime, uint8 _stasisHitCount)
    {
        require(isLegionQuesting(_legionId), "Legion is not questing");

        uint256 _triadPlayTime = _triadPlayTimeForLegion(_usingOldSchema, _legionId);
        uint8 _corruptCellsRemaining = _corruptedCellsRemainingForLegion(_usingOldSchema, _legionId);

        // If this part requires treasure triad, and the user has already played it for this part,
        // AND the use had a corrupted card... the end time will be based on that stasis.
        if(appStorage.zoneNameToInfo[_zoneName].parts[_advanceToPartForLegion(_usingOldSchema, _legionId) - 1].playTreasureTriad
            && _triadPlayTime > 0
            && _corruptCellsRemaining > 0
            && appStorage.generationToCanHaveStasis[_legionMetadata.legionGeneration])
        {
            return (_triadPlayTime + (_corruptCellsRemaining * appStorage.stasisLengthForCorruptedCard), _corruptCellsRemaining);
        }

        uint256 _totalLength;

        (_totalLength, _stasisHitCount) = _calculateStasis(
            appStorage.zoneNameToInfo[_zoneName],
            _legionMetadata,
            _randomNumber,
            _maxConstellationRank,
            _legionId,
            _usingOldSchema
        );

        _endTime = _startTimeForLegion(_usingOldSchema, _legionId) + _totalLength;
    }

    function _currentPartForLegion(bool _useOldSchema, uint256 _legionId) internal view returns(uint8) {
        return _useOldSchema
            ? appStorage.legionIdToLegionQuestingInfoV1[_legionId].currentPart
            : appStorage.legionIdToLegionQuestingInfoV2[_legionId].currentPart;
    }

    function _triadPlayTimeForLegion(bool _useOldSchema, uint256 _legionId) internal view returns(uint256) {
        return _useOldSchema
            ? appStorage.legionIdToLegionQuestingInfoV1[_legionId].triadOutcome.timeTriadWasPlayed
            : appStorage.legionIdToLegionQuestingInfoV2[_legionId].timeTriadWasPlayed;
    }

    function _cardsFlippedForLegion(bool _useOldSchema, uint256 _legionId) internal view returns(uint8) {
        return _useOldSchema
            ? appStorage.legionIdToLegionQuestingInfoV1[_legionId].triadOutcome.cardsFlipped
            : appStorage.legionIdToLegionQuestingInfoV2[_legionId].cardsFlipped;
    }

    function _corruptedCellsRemainingForLegion(bool _useOldSchema, uint256 _legionId) internal view returns(uint8) {
        return _useOldSchema
            ? appStorage.legionIdToLegionQuestingInfoV1[_legionId].triadOutcome.corruptedCellsRemainingForCurrentPart
            : appStorage.legionIdToLegionQuestingInfoV2[_legionId].corruptedCellsRemainingForCurrentPart;
    }

    function _startTimeForLegion(bool _useOldSchema, uint256 _legionId) internal view returns(uint256) {
        return _useOldSchema
            ? appStorage.legionIdToLegionQuestingInfoV1[_legionId].startTime
            : appStorage.legionIdToLegionQuestingInfoV2[_legionId].startTime;
    }

    function _maxConstellationRankForLegionAndZone(
        string memory _zoneName,
        LegionMetadata memory _legionMetadata)
    internal
    view
    returns(uint8)
    {
        uint8 _rankConstellation1 = _legionMetadata.constellationRanks[uint256(appStorage.zoneNameToInfo[_zoneName].constellation1)];
        uint8 _rankConstellation2 = _legionMetadata.constellationRanks[uint256(appStorage.zoneNameToInfo[_zoneName].constellation2)];
        if(_rankConstellation1 > _rankConstellation2) {
            return _rankConstellation1;
        } else {
            return _rankConstellation2;
        }
    }

    function _calculateStasis(
        LibAdvancedQuestingDiamond.ZoneInfo storage _zoneInfo,
        LegionMetadata memory _legionMetadata,
        uint256 _randomNumber,
        uint8 _maxConstellationRank,
        uint256 _legionId,
        bool _usingOldSchema)
    private
    view
    returns(uint256 _totalLength, uint8 _stasisHitCount)
    {

        uint256 _corruptionBalance = appStorage.legionIdToLegionQuestingInfoV2[_legionId].corruptionAmount;

        (uint32 _additionalStasisAndQuestTime,,,) = _getCorruptionEffects(_corruptionBalance);
        uint8 _baseRateReduction = appStorage.maxConstellationRankToReductionInStasis[_maxConstellationRank];

        uint8 _currentPart = _currentPartForLegion(_usingOldSchema, _legionId);
        uint8 _advanceToPart = _advanceToPartForLegion(_usingOldSchema, _legionId);

        // For example, assume currentPart is 0 and they are advancing to part 1.
        // We will go through this for loop once. The first time, i = 0, which is also
        // the index of the parts array in the ZoneInfo object.
        for(uint256 i = _currentPart; i < _advanceToPart; i++) {
            _totalLength += _zoneInfo.parts[i].zonePartLength + _additionalStasisAndQuestTime;

            if(appStorage.generationToCanHaveStasis[_legionMetadata.legionGeneration]) {
                uint8 _baseRate = _zoneInfo.parts[i].stasisBaseRate;

                // If not greater than, no chance of stasis!
                if(_baseRate > _baseRateReduction) {
                    if(_randomNumber % 256 < _baseRate - _baseRateReduction) {
                        _stasisHitCount++;
                        _totalLength += _zoneInfo.parts[i].stasisLength + _additionalStasisAndQuestTime;
                    }

                    _randomNumber >>= 8;
                }
            }
        }
    }

    function _getCorruptionEffects(uint256 _corruptionBalance) internal pure returns(uint32 _additionalStasisAndQuestTime, uint8 _additionalCorruptedCells, uint32 _increasedDropRate, uint32 _reducedDropRate) {
        if(_corruptionBalance <= 100_000 ether) {
            _additionalStasisAndQuestTime = 0;
            _additionalCorruptedCells = 0;
            _increasedDropRate = 10000;
            _reducedDropRate = 0;
        } else if(_corruptionBalance <= 200_000 ether) {
            _additionalStasisAndQuestTime = 1 hours;
            _additionalCorruptedCells = 0;
            _increasedDropRate = 0;
            _reducedDropRate = 2000;
        } else if(_corruptionBalance <= 300_000 ether) {
            _additionalStasisAndQuestTime = 2 hours;
            _additionalCorruptedCells = 1;
            _increasedDropRate = 0;
            _reducedDropRate = 4000;
        } else if(_corruptionBalance <= 400_000 ether) {
            _additionalStasisAndQuestTime = 3 hours;
            _additionalCorruptedCells = 1;
            _increasedDropRate = 0;
            _reducedDropRate = 8000;
        } else if(_corruptionBalance <= 500_000 ether) {
            _additionalStasisAndQuestTime = 4 hours;
            _additionalCorruptedCells = 1;
            _increasedDropRate = 0;
            _reducedDropRate = 16000;
        } else if(_corruptionBalance <= 600_000 ether) {
            _additionalStasisAndQuestTime = 5 hours;
            _additionalCorruptedCells = 1;
            _increasedDropRate = 0;
            _reducedDropRate = 32000;
        } else {
            _additionalStasisAndQuestTime = 6 hours;
            _additionalCorruptedCells = 1;
            _increasedDropRate = 0;
            _reducedDropRate = 48000;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAdvancedQuestingDiamond {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAdvancedQuestingInternal {
    function unstakeTreasures(
        uint256 _legionId,
        bool _usingOldSchema,
        bool _isRestarting,
        address _owner)
    external
    returns(uint256[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/randomizer/IRandomizer.sol";
import "../questing/IQuesting.sol";
import "../legion/ILegion.sol";
import "../legionmetadatastore/ILegionMetadataStore.sol";
import "../external/ITreasure.sol";
import "../consumable/IConsumable.sol";
import "../treasuremetadatastore/ITreasureMetadataStore.sol";
import "../treasuretriad/ITreasureTriad.sol";
import "../treasurefragment/ITreasureFragment.sol";
import "../recruitlevel/IRecruitLevel.sol";
import "../masterofinflation/IMasterOfInflation.sol";
import "../masterofinflation/IPoolConfigProvider.sol";
import "../corruption/ICorruption.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibAdvancedQuestingDiamond {
    struct AppStorage {
        IRandomizer randomizer;
        IQuesting questing;
        ILegion legion;
        ILegionMetadataStore legionMetadataStore;
        ITreasure treasure;
        IConsumable consumable;
        ITreasureMetadataStore treasureMetadataStore;
        ITreasureTriad treasureTriad;
        ITreasureFragment treasureFragment;

        // The length of stasis per corrupted card.
        uint256 stasisLengthForCorruptedCard;

        // The name of the zone to all of
        mapping(string => ZoneInfo) zoneNameToInfo;

        // For a given generation, returns if they can experience stasis.
        mapping(LegionGeneration => bool) generationToCanHaveStasis;

        // The highest constellation rank for the given zone to how much the chance of stasis is reduced.
        // The value that is stored is out of 256, as is the probability calculation.
        mapping(uint8 => uint8) maxConstellationRankToReductionInStasis;

        mapping(uint256 => LegionQuestingInfoV1) legionIdToLegionQuestingInfoV1;

        // The optimized version of the questing info struct.
        // Blunder on my part for not optimizing for gas better before launch.
        mapping(uint256 => LegionQuestingInfoV2) legionIdToLegionQuestingInfoV2;

        // The chance of a universal lock out of 100,000.
        uint256 chanceUniversalLock;

        // Putting this storage in ZoneInfo after the fact rekt it. A mapping will
        // be nice as if there are any out of bounds index, it will return 0.
        mapping(string => mapping(uint256 => mapping(uint256 => uint8[7]))) zoneNameToPartIndexToRewardIndexToQuestBoosts;

        mapping(uint8 => uint256) endingPartToQPGained;

        mapping(string => mapping(uint256 => RecruitPartInfo)) zoneNameToPartIndexToRecruitPartInfo;

        uint256 numQuesting;

        uint32 cadetRecruitFragmentBoost;

        IRecruitLevel recruitLevel;
        IMasterOfInflation masterOfInflation;

        // The time the fragment pools were first set. Used to start counting the
        // regular quests in progress. Do not want to consider quests that are happening mid-upgrade
        // for pool purposes.
        uint256 timePoolsFirstSet;
        mapping(uint8 => uint64) tierToPoolId;
        mapping(uint8 => uint64) tierToRecruitPoolId;

        uint256 numRecruitsQuesting;

        ICorruption corruption;
    }

    struct LegionQuestingInfoV1 {
        uint256 startTime;
        uint256 requestId;
        LegionTriadOutcomeV1 triadOutcome;
        EnumerableSetUpgradeable.UintSet treasureIds;
        mapping(uint256 => uint256) treasureIdToAmount;
        string zoneName;
        address owner;
        uint8 advanceToPart;
        uint8 currentPart;
    }

    struct LegionTriadOutcomeV1 {
        // If 0, triad has not been played for current part.
        uint256 timeTriadWasPlayed;
        // Indicates the number of corrupted cards that were left for the current part the legion is on.
        uint8 corruptedCellsRemainingForCurrentPart;
        // Number of cards flipped
        uint8 cardsFlipped;
    }

    struct LegionQuestingInfoV2 {
        // Will be 0 if not on a quest.
        // The time that the legion started the CURRENT part.
        uint120 startTime;
        // If 0, triad has not been played for current part.
        uint120 timeTriadWasPlayed;
        // Indicates the number of corrupted cards that were left for the current part the legion is on.
        uint8 corruptedCellsRemainingForCurrentPart;
        // Number of cards flipped
        uint8 cardsFlipped;
        // The owner of this questing. This value only should be trusted if startTime > 0 and the legion is staked here.
        address owner;
        // The current random request for the legion.
        // There may be multiple requests through the zone parts depending
        // on if they auto-advanced or not.
        uint80 requestId;
        // Indicates how far the legion wants to go automatically.
        uint8 advanceToPart;
        // Which part the legion is currently at. May be 0 if they have not made it to part 1.
        uint8 currentPart;
        // The zone they are currently at.
        string zoneName;
        // All the treasures that may be staked. Stored this way for effeciency.
        Treasures treasures;
        // The amount of corruption when the quest started
        uint256 corruptionAmount;
    }

    struct ZoneInfo {
        // The time this zone becomes active. If 0, zone does not exist.
        uint256 zoneStartTime;
        TreasureCategory categoryBoost1;
        TreasureCategory categoryBoost2;
        // The constellations that are considered for this zone.
        Constellation constellation1;
        Constellation constellation2;
        ZonePart[] parts;
    }

    struct ZonePart {
        // The length of time this zone takes to complete.
        uint256 zonePartLength;
        // The length of time added to the journey if the legion gets stasis.
        uint256 stasisLength;
        // The base rate of statis for the part of the zone. Out of 256.
        uint8 stasisBaseRate;
        // The quest level minimum required to proceed to this part of the zone.
        uint8 questingLevelRequirement;
        // DEPRECATED
        uint8 questingXpGained;
        // Indicates if the user needs to play treasure triad to complete this part of the journey.
        bool playTreasureTriad;
        // The different rewards given if the user ends their adventure on this part of the zone.
        ZoneReward[] rewards;
    }

    struct ZoneReward {
        // Out of 256 (255 max). How likely this reward group will be given to the user.
        uint8 baseRateRewardOdds;

        // Certain generations/rarities get a rate boost.
        // For example, only genesis legions are able to get full treasures from the zone.
        // And each rarity of legions (genesis and auxiliary) have a better chance for treasure pieces.
        uint8[][] generationToRarityToBoost;

        // Applies only when this zone part requires the user to play treasure triad.
        // This is the boost this reward gains per card that was flipped by the user.
        uint8 boostPerFlippedCard;

        // The different options for this reward.
        ZoneRewardOption[] rewardOptions;
    }

    struct ZoneRewardOption {
        // The consumable id associated with this reward option.
        // May be 0.
        uint256 consumableId;

        // The amount of the consumable given.
        uint256 consumableAmount;

        // ID associated to this treasure fragment. May be 0.
        uint256 treasureFragmentId;

        // The treasure tier if this option is to receive a full treasure.
        // May be 0 indicating no treasures
        uint8 treasureTier;

        // The category of treasure that will be minted for the given tier.
        TreasureCategory treasureCategory;

        // The odds out of 256 that this reward is picked from the options
        uint8 rewardOdds;
    }

    struct StartQuestParams {
        uint256 legionId;
        string zoneName;
        // What part to advance to. Should be between 1-maxParts.
        uint8 advanceToPart;
        // The treasures to stake with the legion.
        uint256[] treasureIds;
        uint256[] treasureAmounts;
    }

    // Pack the struct. 7 is the maximum number of treasures that can be staked.
    struct Treasures {
        uint8 numberOfTypesOfTreasures;
        uint16 treasure1Id;
        uint8 treasure1Amount;
        uint16 treasure2Id;
        uint8 treasure2Amount;
        uint16 treasure3Id;
        uint8 treasure3Amount;
        uint16 treasure4Id;
        uint8 treasure4Amount;
        uint16 treasure5Id;
        uint8 treasure5Amount;
        uint16 treasure6Id;
        uint8 treasure6Amount;
        uint16 treasure7Id;
        uint8 treasure7Amount;
    }

    struct RecruitPartInfo {
        uint8 numEoS;
        uint8 numShards;
        uint32 chanceUniversalLock;
        uint32 recruitXPGained;
        uint8 fragmentId;
        uint168 emptySpace;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IConsumable is IERC1155Upgradeable {

    function mint(address _to, uint256 _id, uint256 _amount) external;

    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;

    function adminSafeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount) external;

    function adminSafeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;

    function adminBurn(address account, uint256 id, uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ICorruption is IERC20Upgradeable {
    function burn(address _account, uint256 _amount) external;
    function setCorruptionStreamBoost(address _account, uint32 _boost) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasure {
    // Transfers the treasure at the given ID of the given amount.
    // Requires that the legions are pre-approved.
    //
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes memory data) external;

    // Transfers the treasure at the given ID of the given amount.
    //
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory data) external;

    // Admin only.
    //
    function mint(address _account, uint256 _tokenId, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

interface ILegion is IERC721MetadataUpgradeable {

    // Mints a legion to the given address. Returns the token ID.
    // Admin only.
    function safeMint(address _to) external returns(uint256);

    // Sets the URI for the given token id. Token must exist.
    // Admin only.
    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external;

    // Transfers the token to the given address. Does not need approval. _from still must be the owner of the token.
    // Admin only.
    function adminSafeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    // Burns the given legion. Ensures that the _from user is the owner.
    //
    function adminBurn(address _from, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LegionMetadataStoreState.sol";

interface ILegionMetadataStore {
    // Sets the intial metadata for a token id.
    // Admin only.
    function setInitialMetadataForLegion(address _owner, uint256 _tokenId, LegionGeneration _generation, LegionClass _class, LegionRarity _rarity, uint256 _oldId) external;

    // Increases the quest level by one. It is up to the calling contract to regulate the max quest level. No validation.
    // Admin only.
    function increaseQuestLevel(uint256 _tokenId) external;

    // Increases the craft level by one. It is up to the calling contract to regulate the max craft level. No validation.
    // Admin only.
    function increaseCraftLevel(uint256 _tokenId) external;

    // Increases the rank of the given constellation to the given number. It is up to the calling contract to regulate the max constellation rank. No validation.
    // Admin only.
    function increaseConstellationRank(uint256 _tokenId, Constellation _constellation, uint8 _to) external;

    // Returns the metadata for the given legion.
    function metadataForLegion(uint256 _tokenId) external view returns(LegionMetadata memory);

    // Returns the tokenUri for the given token.
    function tokenURI(uint256 _tokenId) external view returns(string memory);
}

// As this will likely change in the future, this should not be used to store state, but rather
// as parameters and return values from functions.
struct LegionMetadata {
    LegionGeneration legionGeneration;
    LegionClass legionClass;
    LegionRarity legionRarity;
    uint8 questLevel;
    uint8 craftLevel;
    uint8[6] constellationRanks;
    uint256 oldId;
}

enum Constellation {
    FIRE,
    EARTH,
    WIND,
    WATER,
    LIGHT,
    DARK
}

enum LegionRarity {
    LEGENDARY,
    RARE,
    SPECIAL,
    UNCOMMON,
    COMMON,
    RECRUIT
}

enum LegionClass {
    RECRUIT,
    SIEGE,
    FIGHTER,
    ASSASSIN,
    RANGED,
    SPELLCASTER,
    RIVERMAN,
    NUMERAIRE,
    ALL_CLASS,
    ORIGIN
}

enum LegionGeneration {
    GENESIS,
    AUXILIARY,
    RECRUIT
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../shared/AdminableUpgradeable.sol";
import "./ILegionMetadataStore.sol";

abstract contract LegionMetadataStoreState is Initializable, AdminableUpgradeable {

    event LegionQuestLevelUp(uint256 indexed _tokenId, uint8 _questLevel);
    event LegionCraftLevelUp(uint256 indexed _tokenId, uint8 _craftLevel);
    event LegionConstellationRankUp(uint256 indexed _tokenId, Constellation indexed _constellation, uint8 _rank);
    event LegionCreated(address indexed _owner, uint256 indexed _tokenId, LegionGeneration _generation, LegionClass _class, LegionRarity _rarity);

    mapping(uint256 => LegionGeneration) internal idToGeneration;
    mapping(uint256 => LegionClass) internal idToClass;
    mapping(uint256 => LegionRarity) internal idToRarity;
    mapping(uint256 => uint256) internal idToOldId;
    mapping(uint256 => uint8) internal idToQuestLevel;
    mapping(uint256 => uint8) internal idToCraftLevel;
    mapping(uint256 => uint8[6]) internal idToConstellationRanks;

    mapping(LegionGeneration => mapping(LegionClass => mapping(LegionRarity => mapping(uint256 => string)))) internal _genToClassToRarityToOldIdToUri;

    function __LegionMetadataStoreState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterOfInflation {
    function tryMintFromPool(
        MintFromPoolParams calldata _params
    ) external returns (bool _didMintItem);

    function itemRatePerSecond(uint64 _poolId) external view returns (uint256);
}

struct MintFromPoolParams {
    // Slot 1 (160/256)
    uint64 poolId;
    uint64 amount;
    // Extra odds (out of 100,000) of pulling the item. Will be multiplied against the base odds
    // (1 + bonus) * dynamicBaseOdds
    uint32 bonus;
    // Slot 2
    uint256 itemId;
    // Slot 3
    uint256 randomNumber;
    // Slot 4 (192/256)
    address user;
    uint32 negativeBonus;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolConfigProvider {
    // Returns the numerator in the dynamic rate formula.
    //
    function getN(uint64 _poolId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuesting {
    function processQPGainAndLevelUp(uint256 _tokenId, uint8 _currentQuestLevel, uint256 _qpGained) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRecruitLevel {
    function increaseRecruitExp(uint256 _tokenId, uint32 _expIncrease) external;
    function recruitType(uint256 _tokenId) external view returns(RecruitType);
    function getRecruitLevel(uint256 _tokenId) external view returns(uint16);
}

enum RecruitType {
    NONE,
    COGNITION,
    PARABOLICS,
    LETHALITY,
    SIEGE_APPRENTICE,
    FIGHTER_APPRENTICE,
    ASSASSIN_APPRENTICE,
    RANGED_APPRENTICE,
    SPELLCASTER_APPRENTICE
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface ITreasureFragment is IERC1155Upgradeable {

    function mint(address _to, uint256 _id, uint256 _amount) external;

    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;

    function adminSafeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount) external;

    function adminSafeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TreasureMetadataStoreState.sol";

interface ITreasureMetadataStore {
    // Sets the metadata for the given Ids.
    // Admin only.
    function setMetadataForIds(uint256[] calldata _ids, TreasureMetadata[] calldata _metadatas) external;

    // Returns if the given ID has metadata set.
    function hasMetadataForTreasureId(uint256 _treasureId) external view returns(bool);

    // Returns the metadata for the given ID. Reverts if no metadata for the ID is set.
    function getMetadataForTreasureId(uint256 _treasureId) external view returns(TreasureMetadata memory);

    // For the given tier, gets a random MINTABLE treasure id.
    function getRandomTreasureForTier(uint8 _tier, uint256 _randomNumber) external view returns(uint256);

    // For the given tier AND category, gets a random MINTABLE treasure id.
    function getRandomTreasureForTierAndCategory(
        uint8 _tier,
        TreasureCategory _category,
        uint256 _randomNumber)
    external view returns(uint256);

    // For the given tier, gets a random treasure id, MINTABLE OR NOT.
    function getAnyRandomTreasureForTier(uint8 _tier, uint256 _randomNumber) external view returns(uint256);
}

// Do not change. Stored in state.
struct TreasureMetadata {
    TreasureCategory category;
    uint8 tier;
    // Out of 100,000
    uint32 craftingBreakOdds;
    bool isMintable;
    uint256 consumableIdDropWhenBreak;
}

enum TreasureCategory {
    ALCHEMY,
    ARCANA,
    BREWING,
    ENCHANTER,
    LEATHERWORKING,
    SMITHING
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/AdminableUpgradeable.sol";
import "./ITreasureMetadataStore.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

abstract contract TreasureMetadataStoreState is AdminableUpgradeable {

    mapping(uint8 => EnumerableSetUpgradeable.UintSet) internal tierToMintableTreasureIds;
    mapping(uint256 => TreasureMetadata) internal treasureIdToMetadata;
    mapping(uint8 => mapping(TreasureCategory => EnumerableSetUpgradeable.UintSet)) internal tierToCategoryToMintableTreasureIds;
    mapping(uint8 => EnumerableSetUpgradeable.UintSet) internal tierToTreasureIds;

    function __TreasureMetadataStoreState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../treasuremetadatastore/ITreasureMetadataStore.sol";
import "../legionmetadatastore/ILegionMetadataStore.sol";

interface ITreasureTriad {
    function generateBoardAndPlayGame(
        uint256 _legionId,
        LegionClass _legionClass,
        UserMove[] calldata _userMoves)
    external
    view
    returns(GameOutcome memory);

}

enum PlayerType {
    NONE,
    NATURE,
    USER
}

// Represents the information contained in a single cell of the game grid.
struct GridCell {
    // The treasure played on this cell. May be 0 if PlayerType == NONE
    uint256 treasureId;

    // The type of player that has played on this cell.
    PlayerType playerType;

    // In the case that playerType == NATURE, if this is true, the player has flipped this card to their side.
    bool isFlipped;

    // Indicates if the cell is corrupted.
    // If the cell is empty, the player must place a card on it to make it uncorrupted.
    // If the cell has a contract/nature card, the player must flip the card to make it uncorrupted.
    bool isCorrupted;

    // Indicates if this cell has an affinity. If so, look at the affinity field.
    bool hasAffinity;

    // The affinity of this field. Only consider this field if hasAffinity is true.
    TreasureCategory affinity;
}

// Represents a move the end user will make.
struct UserMove {
    // The x coordinate of the location
    uint8 x;
    // The y coordinate of the location.
    uint8 y;
    // The treasure to place at this location.
    uint256 treasureId;
}

struct GameOutcome {
    uint8 numberOfFlippedCards;
    uint8 numberOfCorruptedCardsLeft;
    bool playerWon;
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

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomizer {

    // Sets the number of blocks that must pass between increment the commitId and seeding the random
    // Admin
    function setNumBlocksAfterIncrement(uint8 _numBlocksAfterIncrement) external;

    // Increments the commit id.
    // Admin
    function incrementCommitId() external;

    // Adding the random number needs to be done AFTER incrementing the commit id on a separate transaction. If
    // these are done together, there is a potential vulnerability to front load a commit when the bad actor
    // sees the value of the random number.
    function addRandomForCommit(uint256 _seed) external;

    // Returns a request ID for a random number. This is unique.
    function requestRandomNumber() external returns(uint256);

    // Returns the random number for the given request ID. Will revert
    // if the random is not ready.
    function revealRandomNumber(uint256 _requestId) external view returns(uint256);

    // Returns if the random number for the given request ID is ready or not. Call
    // before calling revealRandomNumber.
    function isRandomReady(uint256 _requestId) external view returns(bool);
}