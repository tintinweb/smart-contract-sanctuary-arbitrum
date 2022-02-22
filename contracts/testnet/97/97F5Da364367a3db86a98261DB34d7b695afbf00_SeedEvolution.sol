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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IBalancerCrystal is IERC1155Upgradeable {

    function mint(address _to, uint256 _id, uint256 _amount) external;

    function adminSafeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount)
    external;

    function adminSafeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts)
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IMagic is IERC20Upgradeable {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface ISeedOfLife is IERC1155Upgradeable {

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

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../seedevolution/ISeedEvolution.sol";

interface IImbuedSoul is IERC721Upgradeable {

    function safeMint(
        address _to,
        uint256 _generation,
        LifeformClass _lifeformClass,
        OffensiveSkill _offensiveSkill,
        SecondarySkill[] calldata _secondarySkills,
        bool _isLandOwner) external;

    function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISeedEvolution {

}

enum LifeformRealm {
    VESPER,
    SHERWOOD,
    THOUSAND_ISLES,
    TUL_NIELOHG_DESERT,
    DULKHAN_MOUNTAINS,
    MOLTANIA,
    NETHEREALM,
    MAGINCIA
}

enum LifeformClass {
    WARRIOR,
    MAGE,
    PRIEST,
    SHARPSHOOTER,
    SUMMONER,
    PALADIN,
    ASURA,
    SLAYER
}

enum OffensiveSkill {
    NONE,
    BERSERKER,
    METEOR_SWARM,
    HOLY_ARROW,
    MULTISHOT,
    SUMMON_MINION,
    THORS_HAMMER,
    MINDBURN,
    BACKSTAB
}

enum Path {
    NO_MAGIC,
    MAGIC,
    MAGIC_AND_BC
}

enum SecondarySkill {
    POTION_OF_SWIFTNESS,
    POTION_OF_RECOVERY,
    POTION_OF_GLUTTONY,
    BEGINNER_GARDENING_KIT,
    INTERMEDIATE_GARDENING_KIT,
    EXPERT_GARDENING_KIT,
    SHADOW_WALK,
    SHADOW_ASSAULT,
    SHADOW_OVERLORD,
    SPEAR_OF_FIRE,
    SPEAR_OF_FLAME,
    SPEAR_OF_INFERNO,
    SUMMON_BROWN_BEAR,
    SUMMON_LESSER_DAEMON,
    SUMMON_ANCIENT_WYRM,
    HOUSING_DEED_SMALL_COTTAGE,
    HOUSING_DEED_MEDIUM_TOWER,
    HOUSING_DEED_LARGE_CASTLE,
    DEMONIC_BLAST,
    DEMONIC_WAVE,
    DEMONIC_NOVA,
    RADIANT_BLESSING,
    DIVING_BLESSING,
    CELESTIAL_BLESSING
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./SeedEvolutionSettings.sol";

contract SeedEvolution is Initializable, SeedEvolutionSettings {

    using SafeERC20Upgradeable for IMagic;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function initialize() external initializer {
        SeedEvolutionSettings.__SeedEvolutionSettings_init();
    }

    function stakeSoLs(
        StakeSoLParameters[] calldata _solsToStake)
    external
    whenNotPaused
    contractsAreSet
    onlyEOA
    {
        require(_solsToStake.length > 0, "SeedEvolution: No SoL sent");

        uint256 _totalMagicNeeded = 0;
        uint256 _totalBCNeeded = 0;
        uint256 _totalSol1 = 0;
        uint256 _totalSol2 = 0;

        for(uint256 i = 0; i < _solsToStake.length; i++) {
            StakeSoLParameters memory _solToStake = _solsToStake[i];

            require(_solToStake.treasureIds.length == _solToStake.treasureAmounts.length,
                "SeedEvolution: Treasure id and amount array have bad lengths");

            if(_solToStake.solId == seedOfLife1Id) {
                _totalSol1++;
            } else if(_solToStake.solId == seedOfLife2Id) {
                _totalSol2++;
            } else {
                revert("SeedEvolution: Invalid SoL ID");
            }

            if(_solToStake.path == Path.MAGIC) {
                _totalMagicNeeded += magicCost;
            } else if(_solToStake.path == Path.MAGIC_AND_BC) {
                _totalMagicNeeded += magicCost;
                _totalBCNeeded += balancerCrystalStakeAmount;
            }

            _createLifeform(_solToStake);

            if(_solToStake.treasureIds.length > 0) {
                treasure.safeBatchTransferFrom(
                    msg.sender,
                    address(this),
                    _solToStake.treasureIds,
                    _solToStake.treasureAmounts,
                    "");
            }
        }

        if(_totalSol1 > 0) {
            seedOfLife.safeTransferFrom(msg.sender, address(this), seedOfLife1Id, _totalSol1, "");
        }
        if(_totalSol2 > 0) {
            seedOfLife.safeTransferFrom(msg.sender, address(this), seedOfLife2Id, _totalSol2, "");
        }
        if(_totalMagicNeeded > 0) {
            magic.safeTransferFrom(msg.sender, treasuryAddress, _totalMagicNeeded);
        }
        if(_totalBCNeeded > 0) {
            balancerCrystal.adminSafeTransferFrom(msg.sender, address(this), balancerCrystalId, _totalBCNeeded);
        }
    }

    function _createLifeform(StakeSoLParameters memory _solToStake) private {
        require(_solToStake.firstRealm != _solToStake.secondRealm, "SeedEvolution: First and second realm must differ");

        require(_solToStake.path != Path.NO_MAGIC || _solToStake.treasureIds.length == 0, "SeedEvolution: No magic path cannot stake treasures");

        uint256 _requestId = randomizer.requestRandomNumber();

        uint256 _lifeformId = lifeformIdCur;
        lifeformIdCur++;

        uint256 _totalTreasureBoost = 0;

        for(uint256 i = 0; i < _solToStake.treasureIds.length; i++) {
            require(_solToStake.treasureAmounts[i] > 0, "SeedEvolution: 0 treasure amount");

            TreasureMetadata memory _treasureMetadata = treasureMetadataStore.getMetadataForTreasureId(_solToStake.treasureIds[i]);

            uint256 _treasureBoost = treasureTierToBoost[_treasureMetadata.tier];
            require(_treasureBoost > 0, "SeedEvolution: Boost for tier is 0");

            _totalTreasureBoost += _treasureBoost * _solToStake.treasureAmounts[i];
        }

        userToLifeformIds[msg.sender].add(_lifeformId);
        lifeformIdToInfo[_lifeformId] = LifeformInfo(
            block.timestamp,
            _requestId,
            msg.sender,
            _solToStake.path,
            _solToStake.firstRealm,
            _solToStake.secondRealm,
            _totalTreasureBoost,
            0,
            _solToStake.treasureIds,
            _solToStake.treasureAmounts
        );

        emit LifeformCreated(_lifeformId, lifeformIdToInfo[_lifeformId]);
    }

    function startClaimingImbuedSouls(
        uint256[] calldata _lifeformIds)
    external
    whenNotPaused
    contractsAreSet
    onlyEOA
    nonZeroLength(_lifeformIds)
    {
        for(uint256 i = 0; i < _lifeformIds.length; i++) {
            _startClaimingImbuedSoul(_lifeformIds[i]);
        }
    }

    function _startClaimingImbuedSoul(uint256 _lifeformId) private {
        require(userToLifeformIds[msg.sender].contains(_lifeformId), "SeedEvolution: User does not own this lifeform");

        LifeformInfo storage _info = lifeformIdToInfo[_lifeformId];

        require(block.timestamp >= _info.startTime + timeUntilDeath, "SeedEvolution: Too early to start claiming imbued soul");

        require(_info.unstakingRequestId == 0, "SeedEvolution: Already began claiming imbued soul");

        _info.unstakingRequestId = randomizer.requestRandomNumber();

        emit StartedClaimingImbuedSoul(_lifeformId, _info.unstakingRequestId);
    }

    function finishClaimingImbuedSouls(
        uint256[] calldata _lifeformIds)
    external
    whenNotPaused
    contractsAreSet
    onlyEOA
    nonZeroLength(_lifeformIds)
    {
        for(uint256 i = 0; i < _lifeformIds.length; i++) {
            _finishClaimingImbuedSoul(_lifeformIds[i]);
        }
    }

    function _finishClaimingImbuedSoul(uint256 _lifeformId) private {
        require(userToLifeformIds[msg.sender].contains(_lifeformId), "SeedEvolution: User does not own this lifeform");

        userToLifeformIds[msg.sender].remove(_lifeformId);

        LifeformInfo storage _info = lifeformIdToInfo[_lifeformId];

        require(_info.unstakingRequestId != 0, "SeedEvolution: Claiming for lifeform has not started");
        require(randomizer.isRandomReady(_info.unstakingRequestId), "SeedEvolution: Random is not ready for lifeform");

        uint256 _randomNumber = randomizer.revealRandomNumber(_info.unstakingRequestId);

        _distributePotionsAndTreasures(_info, _randomNumber);

        // Send back BC if needed.
        if(_info.path == Path.MAGIC_AND_BC) {
            balancerCrystal.safeTransferFrom(address(this), msg.sender, balancerCrystalId, balancerCrystalStakeAmount, "");
        }

        LifeformClass _class = classForLifeform(_lifeformId);
        OffensiveSkill _offensiveSkill = offensiveSkillForLifeform(_lifeformId);
        SecondarySkill[] memory _secondarySkills = secondarySkillsForLifeform(_lifeformId);

        // Mint the imbued soul from generation 0
        imbuedSoul.safeMint(msg.sender,
            0,
            _class,
            _offensiveSkill,
            _secondarySkills,
            _info.path == Path.MAGIC_AND_BC);

        emit ImbuedSoulClaimed(msg.sender, _lifeformId);
    }

    function _distributePotionsAndTreasures(LifeformInfo storage _info, uint256 _randomNumber) private returns(uint256) {
        if(_info.path == Path.NO_MAGIC) {
            return 0;
        }

        uint256 _odds = pathToBasePotionPercent[_info.path];
        _odds += _info.treasureBoost;

        uint256 _staminaPotionAmount;

        if(_odds >= 100000) {
            _staminaPotionAmount = staminaPotionRewardAmount;
        } else {
            uint256 _potionResult = _randomNumber % 100000;
            if(_potionResult < _odds) {
                _staminaPotionAmount = staminaPotionRewardAmount;
            }
        }

        if(_staminaPotionAmount > 0) {
            solItem.mint(msg.sender, staminaPotionId, _staminaPotionAmount);
        }

        if(_info.stakedTreasureIds.length > 0) {
            treasure.safeBatchTransferFrom(address(this), msg.sender, _info.stakedTreasureIds, _info.stakedTreasureAmounts, "");
        }

        return _staminaPotionAmount;
    }

    function startUnstakeTreasure(
        uint256 _lifeformId)
    external
    whenNotPaused
    contractsAreSet
    onlyEOA
    {
        require(userToUnstakingTreasure[msg.sender].requestId == 0, "SeedEvolution: Unstaking treasure in progress for user");
        require(userToLifeformIds[msg.sender].contains(_lifeformId), "SeedEvolution: User does not own this lifeform");

        LifeformInfo storage _info = lifeformIdToInfo[_lifeformId];

        require(_info.unstakingRequestId == 0, "SeedEvolution: Can't unstake treasure while claiming imbued soul");
        require(_info.stakedTreasureIds.length > 0, "SeedEvolution: No treasure to unstake");

        uint256 _requestId = randomizer.requestRandomNumber();

        userToUnstakingTreasure[msg.sender] = UnstakingTreasure(
            _requestId,
            _info.stakedTreasureIds,
            _info.stakedTreasureAmounts);

        delete _info.stakedTreasureIds;
        delete _info.stakedTreasureAmounts;
        delete _info.treasureBoost;

        emit StartedUnstakingTreasure(_lifeformId, _requestId);
    }

    function finishUnstakeTreasure()
    external
    whenNotPaused
    contractsAreSet
    onlyEOA
    {
        UnstakingTreasure storage _unstakingTreasure = userToUnstakingTreasure[msg.sender];
        require(_unstakingTreasure.requestId != 0, "SeedEvolution: Unstaking treasure not in progress for user");
        require(randomizer.isRandomReady(_unstakingTreasure.requestId), "SeedEvolution: Random not ready for unstaking treasure");

        uint256 _randomNumber = randomizer.revealRandomNumber(_unstakingTreasure.requestId);

        uint256[] memory _unstakingTreasureIds = _unstakingTreasure.unstakingTreasureIds;
        uint256[] memory _unstakingTreasureAmounts = _unstakingTreasure.unstakingTreasureAmounts;

        uint256[] memory _brokenTreasureAmounts = new uint256[](_unstakingTreasureIds.length);

        delete userToUnstakingTreasure[msg.sender];

        for(uint256 i = 0; i < _unstakingTreasureIds.length; i++) {

            uint256 _amount = _unstakingTreasureAmounts[i];
            for(uint256 j = 0; j < _amount; j++) {
                if(i != 0 || j != 0) {
                    _randomNumber = uint256(keccak256(abi.encode(_randomNumber, 4677567)));
                }

                uint256 _breakResult = _randomNumber % 100000;

                if(_breakResult < treasureBreakOdds) {
                    _unstakingTreasureAmounts[i]--;
                    _brokenTreasureAmounts[i]++;
                }
            }
        }

        treasure.safeBatchTransferFrom(address(this), treasuryAddress, _unstakingTreasureIds, _brokenTreasureAmounts, "");
        treasure.safeBatchTransferFrom(address(this), msg.sender, _unstakingTreasureIds, _unstakingTreasureAmounts, "");

        emit FinishedUnstakingTreasure(msg.sender, _unstakingTreasureIds, _unstakingTreasureAmounts);
    }

    function metadataForLifeforms(uint256[] calldata _lifeformIds) external view returns(LifeformMetadata[] memory) {
        LifeformMetadata[] memory _metadatas = new LifeformMetadata[](_lifeformIds.length);

        for(uint256 i = 0; i < _lifeformIds.length; i++) {
            _metadatas[i] = LifeformMetadata(
                classForLifeform(_lifeformIds[i]),
                offensiveSkillForLifeform(_lifeformIds[i]),
                secondarySkillsForLifeform(_lifeformIds[i])
            );
        }

        return _metadatas;
    }

    function lifeformIdsForUser(address _user) external view returns(uint256[] memory) {
        return userToLifeformIds[_user].values();
    }

    function classForLifeform(uint256 _lifeformId) public view returns(LifeformClass) {
        require(lifeformIdCur > _lifeformId && _lifeformId != 0, "SeedEvolution: Invalid lifeformId");

        uint256 _requestId = lifeformIdToInfo[_lifeformId].requestId;
        require(randomizer.isRandomReady(_requestId), "SeedEvolution: Random is not ready");

        uint256 _randomNumber = randomizer.revealRandomNumber(_requestId);

        uint256 _classResult = _randomNumber % 100000;
        uint256 _topRange = 0;

        for(uint256 i = 0; i < availableClasses.length; i++) {
            _topRange += classToOdds[availableClasses[i]];
            if(_classResult < _topRange) {
                return availableClasses[i];
            }
        }

        revert("SeedEvolution: The class odds are broke");
    }

    function offensiveSkillForLifeform(uint256 _lifeformId) public view returns(OffensiveSkill) {
        LifeformClass _class = classForLifeform(_lifeformId);

        if(block.timestamp < lifeformIdToInfo[_lifeformId].startTime + timeUntilOffensiveSkill) {
            return OffensiveSkill.NONE;
        }

        return classToOffensiveSkill[_class];
    }

    function secondarySkillsForLifeform(uint256 _lifeformId) public view returns(SecondarySkill[] memory) {
        LifeformInfo storage _lifeformInfo = lifeformIdToInfo[_lifeformId];

        if(_lifeformInfo.path == Path.NO_MAGIC) {
            return new SecondarySkill[](0);
        }

        if(block.timestamp < _lifeformInfo.startTime + timeUntilFirstSecondarySkill) {
            return new SecondarySkill[](0);
        }

        uint256 _randomNumber = randomizer.revealRandomNumber(_lifeformInfo.requestId);

        // Unmodified random was used to pick class. Create "fresh" seed here.
        _randomNumber = uint256(keccak256(abi.encode(_randomNumber, _randomNumber)));

        SecondarySkill _firstSkill = _pickSecondarySkillFromRealm(_randomNumber, _lifeformInfo.firstRealm);

        SecondarySkill[] memory _skills;

        if(block.timestamp < _lifeformInfo.startTime + timeUntilSecondSecondarySkill) {
            _skills = new SecondarySkill[](1);
            _skills[0] = _firstSkill;
            return _skills;
        }

        _randomNumber = uint256(keccak256(abi.encode(_randomNumber, _randomNumber)));

        SecondarySkill _secondSkill = _pickSecondarySkillFromRealm(_randomNumber, _lifeformInfo.secondRealm);

        _skills = new SecondarySkill[](2);
        _skills[0] = _firstSkill;
        _skills[1] = _secondSkill;
        return _skills;
    }

    function _pickSecondarySkillFromRealm(uint256 _randomNumber, LifeformRealm _realm) private view returns(SecondarySkill) {
        SecondarySkill[] storage _availableSkills = realmToSecondarySkills[_realm];

        uint256 _skillResult = _randomNumber % 100000;
        uint256 _topRange = 0;

        for(uint256 i = 0; i < _availableSkills.length; i++) {
            _topRange += secondarySkillToOdds[_availableSkills[i]];

            if(_skillResult < _topRange) {
                return _availableSkills[i];
            }
        }

        revert("SeedEvolution: Bad odds for secondary skills");
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./SeedEvolutionState.sol";

abstract contract SeedEvolutionContracts is Initializable, SeedEvolutionState {

    function __SeedEvolutionContracts_init() internal initializer {
        SeedEvolutionState.__SeedEvolutionState_init();
    }

    function setContracts(
        address _randomizerAddress,
        address _seedOfLifeAddress,
        address _balancerCrystalAddress,
        address _magicAddress,
        address _treasuryAddress,
        address _imbuedSoulAddress,
        address _treasureMetadataStoreAddress,
        address _treasureAddress,
        address _solItemAddress)
    external
    onlyAdminOrOwner
    {
        randomizer = IRandomizer(_randomizerAddress);
        seedOfLife = ISeedOfLife(_seedOfLifeAddress);
        balancerCrystal = IBalancerCrystal(_balancerCrystalAddress);
        magic = IMagic(_magicAddress);
        treasuryAddress = _treasuryAddress;
        imbuedSoul = IImbuedSoul(_imbuedSoulAddress);
        treasureMetadataStore = ITreasureMetadataStore(_treasureMetadataStoreAddress);
        treasure = ITreasure(_treasureAddress);
        solItem = ISoLItem(_solItemAddress);
    }

    modifier contractsAreSet() {
        require(areContractsSet(), "SeedEvolution: Contracts aren't set");
        _;
    }

    function areContractsSet() public view returns(bool) {
        return address(randomizer) != address(0)
            && address(seedOfLife) != address(0)
            && address(balancerCrystal) != address(0)
            && address(magic) != address(0)
            && treasuryAddress != address(0)
            && address(imbuedSoul) != address(0)
            && address(treasureMetadataStore) != address(0)
            && address(treasure) != address(0)
            && address(solItem) != address(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./SeedEvolutionContracts.sol";

abstract contract SeedEvolutionSettings is Initializable, SeedEvolutionContracts {

    function __SeedEvolutionSettings_init() internal initializer {
        SeedEvolutionContracts.__SeedEvolutionContracts_init();
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

import "../../shared/randomizer/IRandomizer.sol";
import "./ISeedEvolution.sol";
import "../external/ISeedOfLife.sol";
import "../external/IMagic.sol";
import "../balancercrystal/IBalancerCrystal.sol";
import "../imbuedsoul/IImbuedSoul.sol";
import "../../shared/AdminableUpgradeable.sol";
import "../../symbolic_links/treasuremetadatastore/ITreasureMetadataStore.sol";
import "../external/ITreasure.sol";
import "../solitem/ISoLItem.sol";

abstract contract SeedEvolutionState is Initializable, ISeedEvolution, ERC1155HolderUpgradeable, AdminableUpgradeable {

    event LifeformCreated(uint256 indexed _lifeformId, LifeformInfo _evolutionInfo);

    event StartedUnstakingTreasure(uint256 _lifeformId, uint256 _requestId);
    event FinishedUnstakingTreasure(address _owner, uint256[] _brokenTreasureIds, uint256[] _brokenTreasureAmounts);

    event StartedClaimingImbuedSoul(uint256 _lifeformId, uint256 _claimRequestId);
    event ImbuedSoulClaimed(address _owner, uint256 _lifeformId);

    IRandomizer public randomizer;
    ISeedOfLife public seedOfLife;
    IBalancerCrystal public balancerCrystal;
    IMagic public magic;
    IImbuedSoul public imbuedSoul;
    ITreasureMetadataStore public treasureMetadataStore;
    ITreasure public treasure;
    ISoLItem public solItem;

    address public treasuryAddress;

    uint256 public balancerCrystalId;
    uint256 public magicCost;
    uint256 public balancerCrystalStakeAmount;
    uint256 public seedOfLife1Id;
    uint256 public seedOfLife2Id;

    uint256 public timeUntilOffensiveSkill;
    uint256 public timeUntilFirstSecondarySkill;
    uint256 public timeUntilSecondSecondarySkill;
    uint256 public timeUntilLandDeed;
    uint256 public timeUntilDeath;

    LifeformClass[] public availableClasses;
    mapping(LifeformClass => uint256) public classToOdds;

    mapping(LifeformClass => OffensiveSkill) public classToOffensiveSkill;

    mapping(LifeformRealm => SecondarySkill[]) public realmToSecondarySkills;
    mapping(SecondarySkill => uint256) public secondarySkillToOdds;

    uint256 public lifeformIdCur;

    mapping(address => EnumerableSetUpgradeable.UintSet) internal userToLifeformIds;
    mapping(uint256 => LifeformInfo) public lifeformIdToInfo;

    mapping(uint8 => uint256) public treasureTierToBoost;

    uint256 public staminaPotionId;
    uint256 public staminaPotionRewardAmount;
    mapping(Path => uint256) public pathToBasePotionPercent;

    mapping(address => UnstakingTreasure) userToUnstakingTreasure;

    uint256 public treasureBreakOdds;

    function __SeedEvolutionState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
        ERC1155HolderUpgradeable.__ERC1155Holder_init();

        balancerCrystalId = 1;
        lifeformIdCur = 1;
        magicCost = 25 ether;
        balancerCrystalStakeAmount = 1;
        seedOfLife1Id = 142;
        seedOfLife2Id = 143;

        timeUntilOffensiveSkill = 3 weeks;
        timeUntilFirstSecondarySkill = 4 weeks;
        timeUntilSecondSecondarySkill = 6 weeks;
        timeUntilLandDeed = 7 weeks;
        timeUntilDeath = 8 weeks;

        availableClasses.push(LifeformClass.WARRIOR);
        availableClasses.push(LifeformClass.MAGE);
        availableClasses.push(LifeformClass.PRIEST);
        availableClasses.push(LifeformClass.SHARPSHOOTER);
        availableClasses.push(LifeformClass.SUMMONER);
        availableClasses.push(LifeformClass.PALADIN);
        availableClasses.push(LifeformClass.ASURA);
        availableClasses.push(LifeformClass.SLAYER);

        classToOdds[LifeformClass.WARRIOR] = 30000;
        classToOdds[LifeformClass.MAGE] = 30000;
        classToOdds[LifeformClass.PRIEST] = 12500;
        classToOdds[LifeformClass.SHARPSHOOTER] = 12500;
        classToOdds[LifeformClass.SUMMONER] = 5000;
        classToOdds[LifeformClass.PALADIN] = 5000;
        classToOdds[LifeformClass.ASURA] = 2500;
        classToOdds[LifeformClass.SLAYER] = 2500;

        classToOffensiveSkill[LifeformClass.WARRIOR] = OffensiveSkill.BERSERKER;
        classToOffensiveSkill[LifeformClass.MAGE] = OffensiveSkill.METEOR_SWARM;
        classToOffensiveSkill[LifeformClass.PRIEST] = OffensiveSkill.HOLY_ARROW;
        classToOffensiveSkill[LifeformClass.SHARPSHOOTER] = OffensiveSkill.MULTISHOT;
        classToOffensiveSkill[LifeformClass.SUMMONER] = OffensiveSkill.SUMMON_MINION;
        classToOffensiveSkill[LifeformClass.PALADIN] = OffensiveSkill.THORS_HAMMER;
        classToOffensiveSkill[LifeformClass.ASURA] = OffensiveSkill.MINDBURN;
        classToOffensiveSkill[LifeformClass.SLAYER] = OffensiveSkill.BACKSTAB;

		realmToSecondarySkills[LifeformRealm.VESPER].push(SecondarySkill.POTION_OF_SWIFTNESS);
		realmToSecondarySkills[LifeformRealm.VESPER].push(SecondarySkill.POTION_OF_RECOVERY);
		realmToSecondarySkills[LifeformRealm.VESPER].push(SecondarySkill.POTION_OF_GLUTTONY);
		realmToSecondarySkills[LifeformRealm.SHERWOOD].push(SecondarySkill.BEGINNER_GARDENING_KIT);
		realmToSecondarySkills[LifeformRealm.SHERWOOD].push(SecondarySkill.INTERMEDIATE_GARDENING_KIT);
		realmToSecondarySkills[LifeformRealm.SHERWOOD].push(SecondarySkill.EXPERT_GARDENING_KIT);
		realmToSecondarySkills[LifeformRealm.THOUSAND_ISLES].push(SecondarySkill.SHADOW_WALK);
		realmToSecondarySkills[LifeformRealm.THOUSAND_ISLES].push(SecondarySkill.SHADOW_ASSAULT);
		realmToSecondarySkills[LifeformRealm.THOUSAND_ISLES].push(SecondarySkill.SHADOW_OVERLORD);
		realmToSecondarySkills[LifeformRealm.TUL_NIELOHG_DESERT].push(SecondarySkill.SPEAR_OF_FIRE);
		realmToSecondarySkills[LifeformRealm.TUL_NIELOHG_DESERT].push(SecondarySkill.SPEAR_OF_FLAME);
		realmToSecondarySkills[LifeformRealm.TUL_NIELOHG_DESERT].push(SecondarySkill.SPEAR_OF_INFERNO);
		realmToSecondarySkills[LifeformRealm.DULKHAN_MOUNTAINS].push(SecondarySkill.SUMMON_BROWN_BEAR);
		realmToSecondarySkills[LifeformRealm.DULKHAN_MOUNTAINS].push(SecondarySkill.SUMMON_LESSER_DAEMON);
		realmToSecondarySkills[LifeformRealm.DULKHAN_MOUNTAINS].push(SecondarySkill.SUMMON_ANCIENT_WYRM);
		realmToSecondarySkills[LifeformRealm.MOLTANIA].push(SecondarySkill.HOUSING_DEED_SMALL_COTTAGE);
		realmToSecondarySkills[LifeformRealm.MOLTANIA].push(SecondarySkill.HOUSING_DEED_MEDIUM_TOWER);
		realmToSecondarySkills[LifeformRealm.MOLTANIA].push(SecondarySkill.HOUSING_DEED_LARGE_CASTLE);
		realmToSecondarySkills[LifeformRealm.NETHEREALM].push(SecondarySkill.DEMONIC_BLAST);
		realmToSecondarySkills[LifeformRealm.NETHEREALM].push(SecondarySkill.DEMONIC_WAVE);
		realmToSecondarySkills[LifeformRealm.NETHEREALM].push(SecondarySkill.DEMONIC_NOVA);
		realmToSecondarySkills[LifeformRealm.MAGINCIA].push(SecondarySkill.RADIANT_BLESSING);
		realmToSecondarySkills[LifeformRealm.MAGINCIA].push(SecondarySkill.DIVING_BLESSING);
		realmToSecondarySkills[LifeformRealm.MAGINCIA].push(SecondarySkill.CELESTIAL_BLESSING);

		secondarySkillToOdds[SecondarySkill.POTION_OF_SWIFTNESS] = 80000;
		secondarySkillToOdds[SecondarySkill.POTION_OF_RECOVERY] = 15000;
		secondarySkillToOdds[SecondarySkill.POTION_OF_GLUTTONY] = 5000;
		secondarySkillToOdds[SecondarySkill.BEGINNER_GARDENING_KIT] = 80000;
		secondarySkillToOdds[SecondarySkill.INTERMEDIATE_GARDENING_KIT] = 15000;
		secondarySkillToOdds[SecondarySkill.EXPERT_GARDENING_KIT] = 5000;
		secondarySkillToOdds[SecondarySkill.SHADOW_WALK] = 80000;
		secondarySkillToOdds[SecondarySkill.SHADOW_ASSAULT] = 15000;
		secondarySkillToOdds[SecondarySkill.SHADOW_OVERLORD] = 5000;
		secondarySkillToOdds[SecondarySkill.SPEAR_OF_FIRE] = 80000;
		secondarySkillToOdds[SecondarySkill.SPEAR_OF_FLAME] = 15000;
		secondarySkillToOdds[SecondarySkill.SPEAR_OF_INFERNO] = 5000;
		secondarySkillToOdds[SecondarySkill.SUMMON_BROWN_BEAR] = 80000;
		secondarySkillToOdds[SecondarySkill.SUMMON_LESSER_DAEMON] = 15000;
		secondarySkillToOdds[SecondarySkill.SUMMON_ANCIENT_WYRM] = 5000;
		secondarySkillToOdds[SecondarySkill.HOUSING_DEED_SMALL_COTTAGE] = 80000;
		secondarySkillToOdds[SecondarySkill.HOUSING_DEED_MEDIUM_TOWER] = 15000;
		secondarySkillToOdds[SecondarySkill.HOUSING_DEED_LARGE_CASTLE] = 5000;
		secondarySkillToOdds[SecondarySkill.DEMONIC_BLAST] = 80000;
		secondarySkillToOdds[SecondarySkill.DEMONIC_WAVE] = 15000;
		secondarySkillToOdds[SecondarySkill.DEMONIC_NOVA] = 5000;
		secondarySkillToOdds[SecondarySkill.RADIANT_BLESSING] = 80000;
		secondarySkillToOdds[SecondarySkill.DIVING_BLESSING] = 15000;
		secondarySkillToOdds[SecondarySkill.CELESTIAL_BLESSING] = 5000;

        treasureTierToBoost[4] = 3000;
        treasureTierToBoost[5] = 1000;

        staminaPotionId = 1;
        staminaPotionRewardAmount = 3;

        pathToBasePotionPercent[Path.MAGIC] = 1000;
        pathToBasePotionPercent[Path.MAGIC_AND_BC] = 5000;

        treasureBreakOdds = 15000;
    }
}

// Do not change.
struct LifeformInfo {
    uint256 startTime;
    // Used for class/skill decisions
    uint256 requestId;
    address owner;
    Path path;
    LifeformRealm firstRealm;
    LifeformRealm secondRealm;
    // Calculated based on the staked treasures.
    // 100% == 100,000, but could be higher.
    uint256 treasureBoost;
    // Once set, we will know this lifeform is in the process of unstaking. We can then block certain actions from taking place,
    // such as unstaking treasures or trying to start unstaking again.
    uint256 unstakingRequestId;
    uint256[] stakedTreasureIds;
    uint256[] stakedTreasureAmounts;
}

struct UnstakingTreasure {
    uint256 requestId;
    uint256[] unstakingTreasureIds;
    uint256[] unstakingTreasureAmounts;
}

// Can change, only used for a function return parameter.
struct LifeformMetadata {
    LifeformClass lifeformClass;
    OffensiveSkill offensiveSkill;
    SecondarySkill[] secondarySkills;
}

// Can change, used as parameter to function
struct StakeSoLParameters {
    uint256 solId;
    Path path;
    LifeformRealm firstRealm;
    LifeformRealm secondRealm;
    uint256[] treasureIds;
    uint256[] treasureAmounts;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface ISoLItem is IERC1155Upgradeable {

    function mint(address _to, uint256 _id, uint256 _amount) external;
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

    function __TreasureMetadataStoreState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
    }
}