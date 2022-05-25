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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IBadgez is IERC1155Upgradeable {

    function mintIfNeeded(address _to, uint256 _id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IBugz is IERC20Upgradeable {

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./CraftingSettings.sol";

contract Crafting is Initializable, CraftingSettings {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function initialize() external initializer {
        CraftingSettings.__CraftingSettings_init();
    }

    // Called by World. Returns if the crafting immediately finished for the toad.
    function startCraftingForToad(
        StartCraftingParams calldata _startCraftingParams,
        address _owner)
    external
    whenNotPaused
    contractsAreSet
    worldIsCaller
    returns(bool)
    {
        return _startAndOptionallyFinishCrafting(_startCraftingParams, _owner, true);
    }

    function endCraftingForToad(
        uint256 _toadId,
        address _owner)
    external
    whenNotPaused
    contractsAreSet
    worldIsCaller
    {
        uint256 _craftingId = toadIdToCraftingId[_toadId];
        require(_craftingId > 0, "Toad is not crafting");

        _endCrafting(_craftingId, _owner, true);
    }

    function startOrEndCraftingNoToad(
        uint256[] calldata _craftingIdsToEnd,
        StartCraftingParams[] calldata _startCraftingParams)
    external
    whenNotPaused
    contractsAreSet
    onlyEOA
    {
        require(_craftingIdsToEnd.length > 0 || _startCraftingParams.length > 0, "No inputs provided");

        for(uint256 i = 0; i < _craftingIdsToEnd.length; i++) {
            _endCrafting(_craftingIdsToEnd[i], msg.sender, false);
        }

        for(uint256 i = 0; i < _startCraftingParams.length; i++) {
            _startAndOptionallyFinishCrafting(_startCraftingParams[i], msg.sender, false);
        }
    }

    // Returns if the crafting was immediately finished.
    function _startAndOptionallyFinishCrafting(
        StartCraftingParams calldata _craftingParams,
        address _owner,
        bool _shouldHaveToad)
    private
    returns(bool)
    {
        (uint256 _craftingId, bool _isRecipeInstant) = _startCrafting(_craftingParams, _owner, _shouldHaveToad);
        if(_isRecipeInstant) {
            // No random is required if _isRecipeInstant == true.
            // Safe to pass in 0.
            _endCraftingPostValidation(_craftingId, 0, _owner);
        }
        return _isRecipeInstant;
    }

    // Verifies recipe info, inputs, and transfers those inputs.
    // Returns if this recipe can be completed instantly
    function _startCrafting(
        StartCraftingParams calldata _craftingParams,
        address _owner,
        bool _shouldHaveToad)
    private
    returns(uint256, bool)
    {
        require(_isValidRecipeId(_craftingParams.recipeId), "Unknown recipe");

        CraftingRecipe storage _craftingRecipe = recipeIdToRecipe[_craftingParams.recipeId];
        require(block.timestamp >= _craftingRecipe.recipeStartTime &&
            (_craftingRecipe.recipeStopTime == 0
            || _craftingRecipe.recipeStopTime > block.timestamp), "Recipe has not started or stopped");
        require(!_craftingRecipe.requiresToad || _craftingParams.toadId > 0, "Recipe requires Toad");

        CraftingRecipeInfo storage _craftingRecipeInfo = recipeIdToInfo[_craftingParams.recipeId];
        require(_craftingRecipe.maxCraftsGlobally == 0
            || _craftingRecipe.maxCraftsGlobally > _craftingRecipeInfo.currentCraftsGlobally,
            "Recipe has reached max number of crafts");

        _craftingRecipeInfo.currentCraftsGlobally++;

        uint256 _craftingId = craftingIdCur;
        craftingIdCur++;

        uint64 _totalTimeReduction;
        uint256 _totalBugzReduction;
        (_totalTimeReduction,
            _totalBugzReduction) = _validateAndTransferInputs(
                _craftingRecipe,
                _craftingParams,
                _craftingId,
                _owner
            );

        _burnBugz(_craftingRecipe, _owner, _totalBugzReduction);

        _validateAndStoreToad(_craftingRecipe, _craftingParams.toadId, _craftingId, _shouldHaveToad);

        UserCraftingInfo storage _userCrafting = craftingIdToUserCraftingInfo[_craftingId];

        if(_craftingRecipe.timeToComplete > _totalTimeReduction) {
            _userCrafting.timeOfCompletion
                = uint128(block.timestamp + _craftingRecipe.timeToComplete - _totalTimeReduction);
        }

        if(_craftingRecipeInfo.isRandomRequired) {
            _userCrafting.requestId = uint64(randomizer.requestRandomNumber());
        }

        _userCrafting.recipeId = _craftingParams.recipeId;
        _userCrafting.toadId = _craftingParams.toadId;

        // Indicates if this recipe will complete in the same txn as the startCrafting txn.
        bool _isRecipeInstant = !_craftingRecipeInfo.isRandomRequired && _userCrafting.timeOfCompletion == 0;

        if(!_isRecipeInstant) {
            userToCraftsInProgress[_owner].add(_craftingId);
        }

        _emitCraftingStartedEvent(_craftingId, _owner, _craftingParams);

        return (_craftingId, _isRecipeInstant);
    }

    function _emitCraftingStartedEvent(uint256 _craftingId, address _owner, StartCraftingParams calldata _craftingParams) private {
        emit CraftingStarted(
            _owner,
            _craftingId,
            craftingIdToUserCraftingInfo[_craftingId].timeOfCompletion,
            craftingIdToUserCraftingInfo[_craftingId].recipeId,
            craftingIdToUserCraftingInfo[_craftingId].requestId,
            craftingIdToUserCraftingInfo[_craftingId].toadId,
            _craftingParams.inputs);
    }

    function _validateAndStoreToad(
        CraftingRecipe storage _craftingRecipe,
        uint256 _toadId,
        uint256 _craftingId,
        bool _shouldHaveToad)
    private
    {
        require(_craftingRecipe.requiresToad == _shouldHaveToad, "Bad method to start recipe");
        if(_craftingRecipe.requiresToad) {
            require(_toadId > 0, "No toad supplied");
            toadIdToCraftingId[_toadId] = _craftingId;
        } else {
            require(_toadId == 0, "No toad should be supplied");
        }
    }

    function _burnBugz(
        CraftingRecipe storage _craftingRecipe,
        address _owner,
        uint256 _totalBugzReduction)
    private
    {
        uint256 _totalBugz;
        if(_craftingRecipe.bugzCost > _totalBugzReduction) {
            _totalBugz = _craftingRecipe.bugzCost - _totalBugzReduction;
        }

        if(_totalBugz > 0) {
            bugz.burn(_owner, _totalBugz);
        }
    }

    // Ensures all inputs are valid and provided if required.
    function _validateAndTransferInputs(
        CraftingRecipe storage _craftingRecipe,
        StartCraftingParams calldata _craftingParams,
        uint256 _craftingId,
        address _owner)
    private
    returns(uint64 _totalTimeReduction, uint256 _totalBugzReduction)
    {
        // Because the inputs can have a given "amount" of inputs that must be supplied,
        // the input index provided, and those in the recipe may not be identical.
        uint8 _paramInputIndex;

        for(uint256 i = 0; i < _craftingRecipe.inputs.length; i++) {
            RecipeInput storage _recipeInput = _craftingRecipe.inputs[i];

            for(uint256 j = 0; j < _recipeInput.amount; j++) {
                require(_paramInputIndex < _craftingParams.inputs.length, "Bad number of inputs");
                ItemInfo calldata _startCraftingItemInfo = _craftingParams.inputs[_paramInputIndex];
                _paramInputIndex++;
                // J must equal 0. If they are trying to skip an optional amount, it MUST be the first input supplied for the RecipeInput
                if(j == 0 && _startCraftingItemInfo.itemId == 0 && !_recipeInput.isRequired) {
                    // Break out of the amount loop. They are not providing any of the input
                    break;
                } else if(_startCraftingItemInfo.itemId == 0) {
                    revert("Supplied no input to required input");
                } else {
                    uint256 _optionIndex = recipeIdToInputIndexToItemIdToOptionIndex[_craftingParams.recipeId][i][_startCraftingItemInfo.itemId];
                    RecipeInputOption storage _inputOption = _recipeInput.inputOptions[_optionIndex];

                    require(_inputOption.itemInfo.amount > 0
                        && _inputOption.itemInfo.amount == _startCraftingItemInfo.amount
                        && _inputOption.itemInfo.itemId == _startCraftingItemInfo.itemId, "Bad item input given");

                    // Add to reductions
                    _totalTimeReduction += _inputOption.timeReduction;
                    _totalBugzReduction += _inputOption.bugzReduction;

                    craftingIdToUserCraftingInfo[_craftingId]
                        .itemIdToInput[_inputOption.itemInfo.itemId].itemAmount += _inputOption.itemInfo.amount;
                    craftingIdToUserCraftingInfo[_craftingId]
                        .itemIdToInput[_inputOption.itemInfo.itemId].wasBurned = _inputOption.isBurned;

                    // Only need to save off non-burned inputs. These will be reminted when the recipe is done. Saves
                    // gas over transferring to this contract.
                    if(!_inputOption.isBurned) {
                        craftingIdToUserCraftingInfo[_craftingId].nonBurnedInputs.push(_inputOption.itemInfo);
                    }

                    _mintOrBurnItem(
                        _inputOption.itemInfo,
                        _owner,
                        true);
                }
            }
        }
    }

    function _endCrafting(uint256 _craftingId, address _owner, bool _shouldHaveToad) private {
        require(userToCraftsInProgress[_owner].contains(_craftingId), "Invalid crafting id for user");

        // Remove crafting from users in progress crafts.
        userToCraftsInProgress[_owner].remove(_craftingId);

        UserCraftingInfo storage _userCraftingInfo = craftingIdToUserCraftingInfo[_craftingId];
        require(block.timestamp >= _userCraftingInfo.timeOfCompletion, "Crafting is not complete");

        require(_shouldHaveToad == (_userCraftingInfo.toadId > 0), "Bad method to end crafting");

        uint256 _randomNumber;
        if(_userCraftingInfo.requestId > 0) {
            _randomNumber = randomizer.revealRandomNumber(_userCraftingInfo.requestId);
        }

        _endCraftingPostValidation(_craftingId, _randomNumber, _owner);
    }

    function _endCraftingPostValidation(uint256 _craftingId, uint256 _randomNumber, address _owner) private {
        UserCraftingInfo storage _userCraftingInfo = craftingIdToUserCraftingInfo[_craftingId];
        CraftingRecipe storage _craftingRecipe = recipeIdToRecipe[_userCraftingInfo.recipeId];

        uint256 _bugzRewarded;

        CraftingItemOutcome[] memory _itemOutcomes = new CraftingItemOutcome[](_craftingRecipe.outputs.length);

        for(uint256 i = 0; i < _craftingRecipe.outputs.length; i++) {
            // If needed, get a fresh random for the next output decision.
            if(i != 0 && _randomNumber != 0) {
                _randomNumber = uint256(keccak256(abi.encodePacked(_randomNumber, _randomNumber)));
            }

            (uint256 _bugzForOutput, CraftingItemOutcome memory _outcome) = _determineAndMintOutputs(
                _craftingRecipe.outputs[i],
                _userCraftingInfo,
                _owner,
                _randomNumber);

            _bugzRewarded += _bugzForOutput;
            _itemOutcomes[i] = _outcome;
        }

        for(uint256 i = 0; i < _userCraftingInfo.nonBurnedInputs.length; i++) {
            ItemInfo storage _userCraftingInput = _userCraftingInfo.nonBurnedInputs[i];

            _mintOrBurnItem(
                _userCraftingInput,
                _owner,
                false);
        }

        if(_userCraftingInfo.toadId > 0) {
            delete toadIdToCraftingId[_userCraftingInfo.toadId];
        }

        emit CraftingEnded(_craftingId, _bugzRewarded, _itemOutcomes);
    }

    function _determineAndMintOutputs(
        RecipeOutput storage _recipeOutput,
        UserCraftingInfo storage _userCraftingInfo,
        address _owner,
        uint256 _randomNumber)
    private
    returns(uint256 _bugzForOutput, CraftingItemOutcome memory _outcome)
    {
        uint8 _outputAmount = _determineOutputAmount(
            _recipeOutput,
            _userCraftingInfo,
            _randomNumber);

        // Just in case the output amount needed a random. Only would need 16 bits (one random roll).
        _randomNumber >>= 16;

        uint64[] memory _itemIds = new uint64[](_outputAmount);
        uint64[] memory _itemAmounts = new uint64[](_outputAmount);

        for(uint256 i = 0; i < _outputAmount; i++) {
            if(i != 0 && _randomNumber != 0) {
                _randomNumber = uint256(keccak256(abi.encodePacked(_randomNumber, _randomNumber)));
            }

            RecipeOutputOption memory _selectedOption = _determineOutputOption(
                _recipeOutput,
                _userCraftingInfo,
                _randomNumber);
            _randomNumber >>= 16;

            uint64 _itemAmount;
            if(_selectedOption.itemAmountMin == _selectedOption.itemAmountMax) {
                _itemAmount = _selectedOption.itemAmountMax;
            } else {
                uint64 _rangeSelection = uint64(_randomNumber
                    % (_selectedOption.itemAmountMax - _selectedOption.itemAmountMin + 1));

                _itemAmount = _selectedOption.itemAmountMin + _rangeSelection;
            }

            _bugzForOutput += _selectedOption.bugzAmount;
            _itemIds[i] = _selectedOption.itemId;
            _itemAmounts[i] = _itemAmount;

            _mintOutputOption(_selectedOption, _itemAmount, _owner);
        }

        _outcome.itemIds = _itemIds;
        _outcome.itemAmounts = _itemAmounts;
    }

    function _determineOutputOption(
        RecipeOutput storage _recipeOutput,
        UserCraftingInfo storage _userCraftingInfo,
        uint256 _randomNumber)
    private
    view
    returns(RecipeOutputOption memory)
    {
        RecipeOutputOption memory _selectedOption;
        if(_recipeOutput.outputOptions.length == 1) {
            _selectedOption = _recipeOutput.outputOptions[0];
        } else {
            uint256 _outputOptionResult = _randomNumber % 100000;
            uint32 _topRange = 0;
            for(uint256 j = 0; j < _recipeOutput.outputOptions.length; j++) {
                RecipeOutputOption storage _outputOption = _recipeOutput.outputOptions[j];
                uint32 _adjustedOdds = _adjustOutputOdds(_outputOption.optionOdds, _userCraftingInfo);
                _topRange += _adjustedOdds;
                if(_outputOptionResult < _topRange) {
                    _selectedOption = _outputOption;
                    break;
                }
            }
        }

        return _selectedOption;
    }

    // Determines how many "rolls" the user has for the passed in output.
    function _determineOutputAmount(
        RecipeOutput storage _recipeOutput,
        UserCraftingInfo storage _userCraftingInfo,
        uint256 _randomNumber
    ) private view returns(uint8) {
        uint8 _outputAmount;
        if(_recipeOutput.outputAmount.length == 1) {
            _outputAmount = _recipeOutput.outputAmount[0];
        } else {
            uint256 _outputResult = _randomNumber % 100000;
            uint32 _topRange = 0;

            for(uint256 i = 0; i < _recipeOutput.outputAmount.length; i++) {
                uint32 _adjustedOdds = _adjustOutputOdds(_recipeOutput.outputOdds[i], _userCraftingInfo);
                _topRange += _adjustedOdds;
                if(_outputResult < _topRange) {
                    _outputAmount = _recipeOutput.outputAmount[i];
                    break;
                }
            }
        }
        return _outputAmount;
    }

    function _mintOutputOption(
        RecipeOutputOption memory _selectedOption,
        uint256 _itemAmount,
        address _owner)
    private
    {
        if(_itemAmount > 0 && _selectedOption.itemId > 0) {
            itemz.mint(
                _owner,
                _selectedOption.itemId,
                _itemAmount);
        }
        if(_selectedOption.bugzAmount > 0) {
            bugz.mint(
                _owner,
                _selectedOption.bugzAmount);
        }
        if(_selectedOption.badgeId > 0) {
            badgez.mintIfNeeded(
                _owner,
                _selectedOption.badgeId);
        }
    }

    function _adjustOutputOdds(
        OutputOdds storage _outputOdds,
        UserCraftingInfo storage _userCraftingInfo)
    private
    view
    returns(uint32)
    {
        if(_outputOdds.boostItemIds.length == 0) {
            return _outputOdds.baseOdds;
        }

        int32 _trueOdds = int32(_outputOdds.baseOdds);

        for(uint256 i = 0; i < _outputOdds.boostItemIds.length; i++) {
            uint64 _itemId = _outputOdds.boostItemIds[i];
            if(_userCraftingInfo.itemIdToInput[_itemId].itemAmount == 0) {
                continue;
            }

            _trueOdds += _outputOdds.boostOddChanges[i];
        }

        if(_trueOdds > 100000) {
            return 100000;
        } else if(_trueOdds < 0) {
            return 0;
        } else {
            return uint32(_trueOdds);
        }
    }

    function _mintOrBurnItem(
        ItemInfo memory _itemInfo,
        address _owner,
        bool _burn)
    private
    {
        if(_burn) {
            itemz.burn(_owner, _itemInfo.itemId, _itemInfo.amount);
        } else {
            itemz.mint(_owner, _itemInfo.itemId, _itemInfo.amount);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./CraftingState.sol";

abstract contract CraftingContracts is Initializable, CraftingState {

    function __CraftingContracts_init() internal initializer {
        CraftingState.__CraftingState_init();
    }

    function setContracts(
        address _bugzAddress,
        address _itemzAddress,
        address _randomizerAddress,
        address _toadzAddress,
        address _worldAddress,
        address _badgezAddress)
    external
    onlyAdminOrOwner
    {
        bugz = IBugz(_bugzAddress);
        itemz = IItemz(_itemzAddress);
        randomizer = IRandomizer(_randomizerAddress);
        toadz = IToadz(_toadzAddress);
        world = IWorld(_worldAddress);
        badgez = IBadgez(_badgezAddress);
    }

    modifier contractsAreSet() {
        require(areContractsSet(), "Contracts aren't set");
        _;
    }

    modifier worldIsCaller() {
        require(msg.sender == address(world), "Must be called by world");
        _;
    }

    function areContractsSet() public view returns(bool) {
        return address(bugz) != address(0)
            && address(itemz) != address(0)
            && address(randomizer) != address(0)
            && address(toadz) != address(0)
            && address(world) != address(0)
            && address(badgez) != address(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./CraftingContracts.sol";

abstract contract CraftingSettings is Initializable, CraftingContracts {

    function __CraftingSettings_init() internal initializer {
        CraftingContracts.__CraftingContracts_init();
    }

    function addCraftingRecipe(
        CraftingRecipe calldata _craftingRecipe)
    external
    onlyAdminOrOwner
    {
        require(_craftingRecipe.recipeStartTime > 0 &&
            (_craftingRecipe.recipeStopTime == 0  || _craftingRecipe.recipeStopTime > _craftingRecipe.recipeStartTime)
            && recipeNameToRecipeId[_craftingRecipe.recipeName] == 0,
            "Bad crafting recipe");

        uint64 _recipeId = recipeIdCur;
        recipeIdCur++;

        recipeNameToRecipeId[_craftingRecipe.recipeName] = _recipeId;

        // Input validation.
        for(uint256 i = 0; i < _craftingRecipe.inputs.length; i++) {
            RecipeInput calldata _input = _craftingRecipe.inputs[i];

            require(_input.inputOptions.length > 0, "Input must have options");

            for(uint256 j = 0; j < _input.inputOptions.length; j++) {
                RecipeInputOption calldata _inputOption = _input.inputOptions[j];

                require(_inputOption.itemInfo.amount > 0, "Bad amount");

                recipeIdToInputIndexToItemIdToOptionIndex[_recipeId][i][_inputOption.itemInfo.itemId] = j;
            }
        }

        // Output validation.
        require(_craftingRecipe.outputs.length > 0, "Recipe requires outputs");

        bool _isRandomRequiredForRecipe;
        for(uint256 i = 0; i < _craftingRecipe.outputs.length; i++) {
            RecipeOutput calldata _output = _craftingRecipe.outputs[i];

            require(_output.outputAmount.length > 0
                && _output.outputAmount.length == _output.outputOdds.length
                && _output.outputOptions.length > 0,
                "Bad output info");

            // If there is a variable amount for this RecipeOutput or multiple options,
            // a random is required.
            _isRandomRequiredForRecipe = _isRandomRequiredForRecipe
                || _output.outputAmount.length > 1
                || _output.outputOptions.length > 1;

            for(uint256 j = 0; j < _output.outputOptions.length; j++) {
                RecipeOutputOption calldata _outputOption = _output.outputOptions[j];

                // If there is an amount range, a random is required.
                _isRandomRequiredForRecipe = _isRandomRequiredForRecipe
                    || _outputOption.itemAmountMin != _outputOption.itemAmountMax;
            }
        }

        recipeIdToRecipe[_recipeId] = _craftingRecipe;
        recipeIdToInfo[_recipeId].isRandomRequired = _isRandomRequiredForRecipe;

        emit RecipeAdded(_recipeId, _craftingRecipe);
    }

    function deleteRecipe(
        uint64 _recipeId)
    external
    onlyAdminOrOwner
    {
        require(_isValidRecipeId(_recipeId), "Unknown recipe Id");
        recipeIdToRecipe[_recipeId].recipeStopTime = recipeIdToRecipe[_recipeId].recipeStartTime;

        emit RecipeDeleted(_recipeId);
    }

    function _isValidRecipeId(uint64 _recipeId) internal view returns(bool) {
        return recipeIdToRecipe[_recipeId].recipeStartTime > 0;
    }

    function recipeIdForName(string calldata _recipeName) external view returns(uint64) {
        return recipeNameToRecipeId[_recipeName];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./ICrafting.sol";
import "../itemz/IItemz.sol";
import "../badgez/IBadgez.sol";
import "../bugz/IBugz.sol";
import "../../shared/randomizer/IRandomizer.sol";
import "../toadz/IToadz.sol";
import "../world/IWorld.sol";
import "../../shared/AdminableUpgradeable.sol";

abstract contract CraftingState is ICrafting, ERC721HolderUpgradeable, ERC1155HolderUpgradeable, AdminableUpgradeable {

    event RecipeAdded(
        uint64 indexed _recipeId,
        CraftingRecipe _craftingRecipe
    );
    event RecipeDeleted(
        uint64 indexed _recipeId
    );

    event CraftingStarted(
        address indexed _user,
        uint256 indexed _craftingId,
        uint128 _timeOfCompletion,
        uint64 _recipeId,
        uint64 _requestId,
        uint64 _tokenId,
        ItemInfo[] suppliedInputs
    );
    event CraftingEnded(
        uint256 _craftingId,
        uint256 _bugzRewarded,
        CraftingItemOutcome[] _itemOutcomes
    );

    IBugz public bugz;
    IItemz public itemz;
    IRandomizer public randomizer;
    IToadz public toadz;
    IWorld public world;
    IBadgez public badgez;

    uint64 public recipeIdCur;

    mapping(string => uint64) public recipeNameToRecipeId;

    mapping(uint64 => CraftingRecipe) public recipeIdToRecipe;
    mapping(uint64 => CraftingRecipeInfo) public recipeIdToInfo;
    // Ugly type signature.
    // This allows an O(1) lookup if a given combination is an option for an input and the exact amount and index of that option.
    mapping(uint64 => mapping(uint256 => mapping(uint256 => uint256))) internal recipeIdToInputIndexToItemIdToOptionIndex;

    mapping(address => EnumerableSetUpgradeable.UintSet) internal userToCraftsInProgress;

    uint256 public craftingIdCur;
    mapping(uint256 => UserCraftingInfo) internal craftingIdToUserCraftingInfo;

    // For a given toad, gives the current crafting instance it belongs to.
    mapping(uint256 => uint256) public toadIdToCraftingId;

    function __CraftingState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
        ERC1155HolderUpgradeable.__ERC1155Holder_init();
        ERC721HolderUpgradeable.__ERC721Holder_init();

        craftingIdCur = 1;
        recipeIdCur = 1;
    }
}

struct UserCraftingInfo {
    uint128 timeOfCompletion;
    uint64 recipeId;
    uint64 requestId;
    uint64 toadId;
    ItemInfo[] nonBurnedInputs;
    mapping(uint256 => UserCraftingInput) itemIdToInput;
}

struct UserCraftingInput {
    uint64 itemAmount;
    bool wasBurned;
}

struct CraftingRecipe {
    string recipeName;
    // The time at which this recipe becomes available. Must be greater than 0.
    //
    uint256 recipeStartTime;
    // The time at which this recipe ends. If 0, there is no end.
    //
    uint256 recipeStopTime;
    // The cost of bugz, if any, to craft this recipe.
    //
    uint256 bugzCost;
    // The number of times this recipe can be crafted globally.
    //
    uint64 maxCraftsGlobally;
    // The amount of time this recipe takes to complete. May be 0, in which case the recipe could be instant (if it does not require a random).
    //
    uint64 timeToComplete;
    // If this requires a toad.
    //
    bool requiresToad;
    // The inputs for this recipe.
    //
    RecipeInput[] inputs;
    // The outputs for this recipe.
    //
    RecipeOutput[] outputs;
}

// The info stored in the following struct is either:
// - Calculated at the time of recipe creation
// - Modified as the recipe is crafted over time
//
struct CraftingRecipeInfo {
    // The number of times this recipe has been crafted.
    //
    uint64 currentCraftsGlobally;
    // Indicates if the crafting recipe requires a random number. If it does, it will
    // be split into two transactions. The recipe may still be split into two txns if the crafting recipe takes time.
    //
    bool isRandomRequired;
}

// This struct represents a single input requirement for a recipe.
// This may have multiple inputs that can satisfy the "input".
//
struct RecipeInput {
    RecipeInputOption[] inputOptions;
    // Indicates the number of this input that must be provided.
    // i.e. 11 options to choose from. Any 3 need to be provided.
    // If isRequired is false, the user can ignore all 3 provided options.
    uint8 amount;
    // Indicates if this input MUST be satisifed.
    //
    bool isRequired;
}

// This struct represents a single option for a given input requirement for a recipe.
//
struct RecipeInputOption {
    // The item that can be supplied
    //
    ItemInfo itemInfo;
    // Indicates if this input is burned or not.
    //
    bool isBurned;
    // The amount of time using this input will reduce the recipe time by.
    //
    uint64 timeReduction;
    // The amount of bugz using this input will reduce the cost by.
    //
    uint256 bugzReduction;
}

// Represents an output of a recipe. This output may have multiple options within it.
// It also may have a chance associated with it.
//
struct RecipeOutput {
    RecipeOutputOption[] outputOptions;
    // This array will indicate how many times the outputOptions are rolled.
    // This may have 0, indicating that this RecipeOutput may not be received.
    //
    uint8[] outputAmount;
    // This array will indicate the odds for each individual outputAmount.
    //
    OutputOdds[] outputOdds;
}

// An individual option within a given output.
//
struct RecipeOutputOption {
    // May be 0.
    //
    uint64 itemId;
    // The min and max for item amount, if different, is a linear odd with no boosting.
    //
    uint64 itemAmountMin;
    uint64 itemAmountMax;
    // If not 0, indicates the badge the user may get for this recipe output.
    //
    uint64 badgeId;
    uint128 bugzAmount;
    // The odds this option is picked out of the RecipeOutput group.
    //
    OutputOdds optionOdds;
}

// This is a generic struct to represent the odds for any output. This could be the odds of how many outputs would be rolled,
// or the odds for a given option.
//
struct OutputOdds {
    uint32 baseOdds;
    // The itemIds to boost these odds. If this shows up ANYWHERE in the inputs, it will be boosted.
    //
    uint64[] boostItemIds;
    // For each boost item, this the change in odds from the base odds.
    //
    int32[] boostOddChanges;
}

// For event
struct CraftingItemOutcome {
    uint64[] itemIds;
    uint64[] itemAmounts;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICrafting {
    function startCraftingForToad(StartCraftingParams calldata _startCraftingParams, address _owner) external returns(bool);

    function endCraftingForToad(uint256 _toadId, address _owner) external;
}

struct StartCraftingParams {
    uint64 toadId;
    uint64 recipeId;
    ItemInfo[] inputs;
}

struct ItemInfo {
    uint64 itemId;
    uint64 amount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IItemz is IERC1155Upgradeable {

    function mint(address _to, uint256 _id, uint256 _amount) external;

    function mintBatch(address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;

    function burn(address _from, uint256 _id, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ToadTraitConstants {

    string constant public SVG_HEADER = '<svg id="toad" width="100%" height="100%" version="1.1" viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string constant public SVG_FOOTER = '<style>#toad{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>';

    string constant public RARITY = "Rarity";
    string constant public BACKGROUND = "Background";
    string constant public MUSHROOM = "Mushroom";
    string constant public SKIN = "Skin";
    string constant public CLOTHES = "Clothes";
    string constant public MOUTH = "Mouth";
    string constant public EYES = "Eyes";
    string constant public ITEM = "Item";
    string constant public HEAD = "Head";
    string constant public ACCESSORY = "Accessory";

    string constant public RARITY_COMMON = "Common";
    string constant public RARITY_1_OF_1 = "1 of 1";
}

enum ToadRarity {
    COMMON,
    ONE_OF_ONE
}

enum ToadBackground {
    GREY,
    PURPLE,
    GREEN,
    BROWN,
    YELLOW,
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
    GOLDEN,
    DARK_PURPLE
}

enum ToadMushroom {
    COMMON,
    ORANGE,
    BROWN,
    RED_SPOTS,
    GREEN,
    BLUE,
    YELLOW,
    GREY,
    PINK,
    ICE,
    GOLDEN,
    RADIOACTIVE,
    CRYSTAL,
    ROBOT
}

enum ToadSkin {
    OG_GREEN,
    BROWN,
    DARK_GREEN,
    ORANGE,
    GREY,
    BLUE,
    PURPLE,
    PINK,
    RAINBOW,
    GOLDEN,
    RADIOACTIVE,
    CRYSTAL,
    SKELETON,
    ROBOT,
    SKIN
}

enum ToadClothes {
    NONE,
    TURTLENECK_BLUE,
    TURTLENECK_GREY,
    T_SHIRT_ROCKET_GREY,
    T_SHIRT_ROCKET_BLUE,
    T_SHIRT_FLY_GREY,
    T_SHIRT_FLY_BLUE,
    T_SHIRT_FLY_RED,
    T_SHIRT_HEART_BLACK,
    T_SHIRT_HEART_PINK,
    T_SHIRT_RAINBOW,
    T_SHIRT_SKULL,
    HOODIE_GREY,
    HOODIE_PINK,
    HOODIE_LIGHT_BLUE,
    HOODIE_DARK_BLUE,
    HOODIE_WHITE,
    T_SHIRT_CAMO,
    HOODIE_CAMO,
    CONVICT,
    ASTRONAUT,
    FARMER,
    RED_OVERALLS,
    GREEN_OVERALLS,
    ZOMBIE,
    SAMURI,
    SAIAN,
    HAWAIIAN_SHIRT,
    SUIT_BLACK,
    SUIT_RED,
    ROCKSTAR,
    PIRATE,
    ASTRONAUT_SUIT,
    CHICKEN_COSTUME,
    DINOSAUR_COSTUME,
    SMOL,
    STRAW_HAT,
    TRACKSUIT
}

enum ToadMouth {
    SMILE,
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
    BLUNT,
    MEH,
    GUM,
    FIRE,
    NONE
}

enum ToadEyes {
    RIGHT_UP,
    RIGHT_DOWN,
    TIRED,
    EYE_ROLL,
    WIDE_UP,
    CONTENTFUL,
    LASERS,
    CROAKED,
    SUSPICIOUS,
    WIDE_DOWN,
    BORED,
    STONED,
    HEARTS,
    WINK,
    GLASSES_HEART,
    GLASSES_3D,
    GLASSES_SUN,
    EYE_PATCH_LEFT,
    EYE_PATCH_RIGHT,
    EYE_PATCH_BORED_LEFT,
    EYE_PATCH_BORED_RIGHT,
    EXCITED,
    NONE
}

enum ToadItem {
    NONE,
    LIGHTSABER_RED,
    LIGHTSABER_GREEN,
    LIGHTSABER_BLUE,
    SWORD,
    WAND_LEFT,
    WAND_RIGHT,
    FIRE_SWORD,
    ICE_SWORD,
    AXE_LEFT,
    AXE_RIGHT
}

enum ToadHead {
    NONE,
    CAP_BROWN,
    CAP_BLACK,
    CAP_RED,
    CAP_PINK,
    CAP_MUSHROOM,
    STRAW_HAT,
    SAILOR_HAT,
    PIRATE_HAT,
    WIZARD_PURPLE_HAT,
    WIZARD_BROWN_HAT,
    CAP_KIDS,
    TOP_HAT,
    PARTY_HAT,
    CROWN,
    BRAIN,
    MOHAWK_PURPLE,
    MOHAWK_GREEN,
    MOHAWK_PINK,
    AFRO,
    BACK_CAP_WHITE,
    BACK_CAP_RED,
    BACK_CAP_BLUE,
    BANDANA_PURPLE,
    BANDANA_RED,
    BANDANA_BLUE,
    BEANIE_GREY,
    BEANIE_BLUE,
    BEANIE_YELLOW,
    HALO,
    COOL_CAT_HEAD,
    FIRE
}

enum ToadAccessory {
    NONE,
    FLIES,
    GOLD_CHAIN,
    NECKTIE_RED,
    NECKTIE_BLUE,
    NECKTIE_PINK
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../libraries/ToadTraitConstants.sol";
import "../toadzmetadata/IToadzMetadata.sol";

interface IToadz is IERC721Upgradeable {

    function mint(address _to, ToadTraits calldata _traits) external;

    function adminSafeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/ToadTraitConstants.sol";

interface IToadzMetadata {
    function tokenURI(uint256 _tokenId) external view returns(string memory);

    function setMetadataForToad(uint256 _tokenId, ToadTraits calldata _traits) external;
}

// Immutable Traits.
// Do not change.
struct ToadTraits {
    ToadRarity rarity;
    ToadBackground background;
    ToadMushroom mushroom;
    ToadSkin skin;
    ToadClothes clothes;
    ToadMouth mouth;
    ToadEyes eyes;
    ToadItem item;
    ToadHead head;
    ToadAccessory accessory;
}

struct ToadTraitStrings {
    string rarity;
    string background;
    string mushroom;
    string skin;
    string clothes;
    string mouth;
    string eyes;
    string item;
    string head;
    string accessory;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWorld {

    function ownerForStakedToad(uint256 _tokenId) external view returns(address);

    function locationForStakedToad(uint256 _tokenId) external view returns(Location);

    function balanceOf(address _owner) external view returns (uint256);
}

enum Location {
    NOT_STAKED,
    WORLD,
    HUNTING_GROUNDS,
    CRAFTING
}