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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solmate/src/utils/FixedPointMathLib.sol";
import "./CorruptionCryptsDiamondState.sol";
import "./ICorruptionCryptsInternal.sol";

contract CorruptionCryptsDiamond is CorruptionCryptsDiamondState {
    modifier onlyValidLegionSquadAndLegionSquadOwner(
        address _user,
        uint64 _legionSquadId
    ) {
        require(
            legionSquadIdToLegionSquadInfo[_legionSquadId].owner == _user &&
                legionSquadIdToLegionSquadInfo[_legionSquadId].exists,
            "You don't own this legion squad!"
        );
        _;
    }

    function advanceRound() internal {
        //Request new global randomness.
        globalRequestId = randomizer.requestRandomNumber();
        emit GlobalRandomnessRequested(globalRequestId, currentRoundId);

        //Increment round
        currentRoundId++;

        //Refresh the harvesters record.
        ICorruptionCryptsInternal(address(this)).updateHarvestersRecord();

        //Set num claimed to 0 for the board treasure.
        boardTreasure.numClaimed = 0;

        //Reset how many legions have reached the temple.
        numLegionsReachedTemple = 0;

        //Set round start time to now.
        roundStartTime = block.timestamp;
    }

    function claimMapTiles(address _user) internal {
        //How many are in hand
        uint256 currentMapTilesInHand = addressToUserData[_user]
            .mapTilesInHand
            .length;

        //Maximum that can fit in current hand
        uint256 maxCanClaim = gameConfig.maxMapTilesInHand -
            currentMapTilesInHand;

        //How much total are pending
        uint256 numPendingMapTiles = ICorruptionCryptsInternal(address(this))
            .calculateNumPendingMapTiles(_user);

        //How many of the pending to claim (that can fit)
        uint256 numToClaim = numPendingMapTiles > maxCanClaim
            ? maxCanClaim
            : numPendingMapTiles;

        //How many epochs to reimburse (if any)
        uint256 epochsToReimburse = numPendingMapTiles - numToClaim;

        //Set lastClaimed epoch and subtract reimbursements.
        addressToUserData[_user].roundIdToEpochLastClaimedMapTiles[
            currentRoundId
        ] =
            ICorruptionCryptsInternal(address(this)).currentEpoch() -
            epochsToReimburse;

        //Generate an array randomly of map tiles to add.
        MapTile[] memory mapTilesToAdd = ICorruptionCryptsInternal(
            address(this)
        ).generateMapTiles(numToClaim, _user);

        for (uint256 i = 0; i < numToClaim; i++) {
            //Loop through array of map tiles.
            MapTile memory thisMapTile = mapTilesToAdd[i];

            //Push their map tile into their hand.
            addressToUserData[_user].mapTilesInHand.push(thisMapTile);
        }

        //Emit event from subgraph
        emit MapTilesClaimed(_user, mapTilesToAdd, currentRoundId);
    }

    function removeMapTileFromHandByIndexAndUser(uint256 _index, address _user)
        internal
    {
        //Load map tiles into memory
        MapTile[] storage mapTiles = addressToUserData[_user].mapTilesInHand;

        //Get the map tile that's at the end
        MapTile memory MapTileAtEnd = mapTiles[mapTiles.length - 1];

        //Overwrite the target index with the end map tile.
        addressToUserData[_user].mapTilesInHand[_index] = MapTileAtEnd;

        //Remove the final map tile
        addressToUserData[_user].mapTilesInHand.pop();
    }

    function removeMapTileFromBoard(address _user, uint32 _mapTileIdToRemove)
        internal
    {
        uint32 _removedMapTileId;
        //If no id specified, pop from back
        if (_mapTileIdToRemove == 0) {
            _removedMapTileId = uint32(
                StructuredLinkedList.popBack(
                    addressToUserData[_user].mapTilesOnBoard
                )
            );
        } else {
            _removedMapTileId = uint32(
                StructuredLinkedList.remove(
                    addressToUserData[_user].mapTilesOnBoard,
                    _mapTileIdToRemove
                )
            );
        }
        //Get the coordinates of the removed tile
        Coordinate memory coordinateOfRemovedMapTile = addressToUserData[_user]
            .mapTileIdToCoordinate[_removedMapTileId];

        addressToUserData[_user]
        .currentBoard[coordinateOfRemovedMapTile.x][
            coordinateOfRemovedMapTile.y
        ].hasMapTile = false;

        addressToUserData[_user]
        .currentBoard[coordinateOfRemovedMapTile.x][
            coordinateOfRemovedMapTile.y
        ].mapTile = MapTile(0, 0, 0, false, false, false, false);

        //If a legion squad is currently on this tile, revert.
        require(
            !addressToUserData[_user]
            .currentBoard[coordinateOfRemovedMapTile.x][
                coordinateOfRemovedMapTile.y
            ].hasLegionSquad,
            "Has legion squad!"
        );
    }

    function placeMapTile(
        address _user,
        uint128 _mapTileId,
        Coordinate memory _coordinate
    ) internal {
        //Pull this cell into memory
        Cell memory thisCell = addressToUserData[_user].currentBoard[
            _coordinate.x
        ][_coordinate.y];

        //Require this cell has no map tile
        require(!thisCell.hasMapTile, "Already has map tile!");

        //Get this full map tile struct and index from storage.
        (
            MapTile memory thisMapTile,
            uint256 _index
        ) = ICorruptionCryptsInternal(address(this)).getMapTileByIDAndUser(
                _mapTileId,
                _user
            );

        //Delete this map tile from their hand.
        removeMapTileFromHandByIndexAndUser(_index, _user);

        //Overwrite the previous maptile on this cell, and record it as having a map tile. (empty)
        thisCell.mapTile = thisMapTile;
        thisCell.hasMapTile = true;

        //Store this cell on the board with adjusted data.
        addressToUserData[_user].currentBoard[_coordinate.x][
            _coordinate.y
        ] = thisCell;

        //Store the coordinates on this map tile.
        addressToUserData[_user].mapTileIdToCoordinate[
            thisMapTile.mapTileId
        ] = _coordinate;

        //Push this map tile into the front of the list
        StructuredLinkedList.pushFront(
            addressToUserData[_user].mapTilesOnBoard,
            thisMapTile.mapTileId
        );

        //Remove oldest maptile on board IF there are now 11 maptiles placed
        if (
            StructuredLinkedList.sizeOf(
                addressToUserData[_user].mapTilesOnBoard
            ) > gameConfig.maxMapTilesOnBoard
        ) {
            removeMapTileFromBoard(_user, 0);
        }

        //Emit event from subgraph
        emit MapTilePlaced(_user, thisMapTile, _coordinate, currentRoundId);
    }

    function enterTemple(address _user, uint64 _legionSquadId)
        internal
        onlyValidLegionSquadAndLegionSquadOwner(_user, _legionSquadId)
    {
        //Pull this legion squad into memory.
        LegionSquadInfo
            memory _legionSquadInfo = legionSquadIdToLegionSquadInfo[
                _legionSquadId
            ];

        uint16 _targetTemple = _legionSquadInfo.targetTemple;

        Temple[] memory _temples = ICorruptionCryptsInternal(address(this))
            .generateTemplePositions();
        Temple memory _targetTempleData;

        for (uint256 i = 0; i < _temples.length; i++) {
            if (_temples[i].templeId == _targetTemple) {
                _targetTempleData = _temples[i];
                break;
            }
        }

        //Ensure they are on this temple.
        require(
            _targetTempleData.coordinate.x == _legionSquadInfo.coordinate.x &&
                _targetTempleData.coordinate.y == _legionSquadInfo.coordinate.y,
            "Legion squad not at temple!"
        );

        //Ensure this is the temple they targeted.
        require(
            _legionSquadInfo.targetTemple == _targetTemple,
            "This was not the temple you targeted!"
        );

        require(_legionSquadInfo.onBoard, "Legion squad not on board!.");

        require(!_legionSquadInfo.inTemple, "Legion squad already in temple.");

        require(
            templeIdToTemples[uint16(_targetTemple)].latestRoundIdEnterable ==
                currentRoundId,
            "Temple is not enterable!"
        );

        //Record they entered a temple in this round
        legionSquadIdToLegionSquadInfo[_legionSquadId]
            .lastRoundEnteredTemple = uint32(currentRoundId);

        //Record them as being in a temple.
        legionSquadIdToLegionSquadInfo[_legionSquadId].inTemple = true;

        //add this many legions as finished
        numLegionsReachedTemple += _legionSquadInfo.legionIds.length;

        if (
            numLegionsReachedTemple >=
            gameConfig.numLegionsReachedTempleToAdvanceRound
        ) advanceRound();

        emit TempleEntered(
            _user,
            _legionSquadId,
            _targetTemple,
            currentRoundId
        );
    }

    function moveLegionSquad(
        address _user,
        uint64 _legionSquadId,
        uint128 _mapTileIdToBurn,
        Coordinate[] memory _coordinates
    ) internal onlyValidLegionSquadAndLegionSquadOwner(_user, _legionSquadId) {
        //This reverts if they do not have the tile.
        //Get this full map tile struct and index from storage.
        (
            MapTile memory thisMapTile,
            uint256 _index
        ) = ICorruptionCryptsInternal(address(this)).getMapTileByIDAndUser(
                _mapTileIdToBurn,
                _user
            );

        require(
            legionSquadIdToLegionSquadInfo[_legionSquadId].onBoard,
            "Legion squad not on board!."
        );

        Coordinate memory _startingCoordinate = legionSquadIdToLegionSquadInfo[
            _legionSquadId
        ].coordinate;

        Cell memory _finalCell = addressToUserData[_user].currentBoard[
            _coordinates[_coordinates.length - 1].x
        ][_coordinates[_coordinates.length - 1].y];

        Cell memory _startingCell = addressToUserData[_user].currentBoard[
            _startingCoordinate.x
        ][_startingCoordinate.y];

        removeMapTileFromHandByIndexAndUser(_index, _user);

        //If they are in a temple, check if they entered in this round or a previous round
        if (legionSquadIdToLegionSquadInfo[_legionSquadId].inTemple) {
            //If they entered this round, revert.
            require(
                currentRoundId ==
                    legionSquadIdToLegionSquadInfo[_legionSquadId]
                        .lastRoundEnteredTemple,
                "Have already entered a temple this round!"
            );

            //If it was a different round, set them as not being in a temple.
            legionSquadIdToLegionSquadInfo[_legionSquadId].inTemple = false;
        }

        //Require the moves on the maptile eq or gt coordinates length
        require(
            thisMapTile.moves >= _coordinates.length,
            "Not enough moves on this map tile!"
        );

        //Require they destination has no legion squad.
        require(
            !_finalCell.hasLegionSquad,
            "Target cell already has legion squad!"
        );

        //Require Legion squad on coordinate
        require(
            _startingCell.hasLegionSquad &&
                _startingCell.legionSquadId == _legionSquadId,
            "Legion squad not on this coordinate!"
        );

        //Require initial cell and first move are legal.
        require(
            ICorruptionCryptsInternal(address(this))
                .decideMovabilityBasedOnTwoCoordinates(
                    _user,
                    _startingCoordinate,
                    _coordinates[0]
                ),
            "MapTiles are not connected"
        );

        //If they claimed this round, don't try and find out if they can.
        bool hasClaimedTreasure = (
            legionSquadIdToLegionSquadInfo[_legionSquadId]
                .mostRecentRoundTreasureClaimed == currentRoundId
                ? true
                : false
        );

        BoardTreasure memory _boardTreasure = ICorruptionCryptsInternal(
            address(this)
        ).generateBoardTreasure();

        for (uint256 i = 0; i < _coordinates.length - 1; i++) {
            //Require i coordinate and i + 1 coordinate are legal.
            require(
                ICorruptionCryptsInternal(address(this))
                    .decideMovabilityBasedOnTwoCoordinates(
                        _user,
                        _coordinates[i],
                        _coordinates[i + 1]
                    ),
                "MapTiles are not connected"
            );

            //If they haven't claimed treasure, and they are on a treasure, claim it with a bypass.
            if (
                !hasClaimedTreasure &&
                (_coordinates[i].x == _boardTreasure.coordinate.x &&
                    _coordinates[i].y == _boardTreasure.coordinate.y)
            ) {
                hasClaimedTreasure = true;
                //Claim this treasure, with bypass true.
                claimTreasure(_user, _legionSquadId, true);
            }
        }

        //Remove legion squad from starting cell
        _startingCell.hasLegionSquad = false;
        _startingCell.legionSquadId = 0;

        //Set cell data to adjusted data.
        addressToUserData[_user].currentBoard[_startingCoordinate.x][
                _startingCoordinate.y
            ] = _startingCell;

        _finalCell.hasLegionSquad = true;
        _finalCell.legionSquadId = _legionSquadId;

        //Set this final cell as to having a legion squad
        addressToUserData[_user].currentBoard[
            _coordinates[_coordinates.length - 1].x
        ][_coordinates[_coordinates.length - 1].y] = _finalCell;

        //Set this legion squads location data to the final coordinate they submitted.
        legionSquadIdToLegionSquadInfo[_legionSquadId]
            .coordinate = _coordinates[_coordinates.length - 1];

        emit LegionSquadMoved(
            _user,
            _legionSquadId,
            _coordinates[_coordinates.length - 1]
        );
    }

    function claimTreasure(
        address _user,
        uint64 _legionSquadId,
        bool _bypassCoordinateCheck
    ) internal onlyValidLegionSquadAndLegionSquadOwner(_user, _legionSquadId) {
        BoardTreasure memory _boardTreasure = ICorruptionCryptsInternal(
            address(this)
        ).generateBoardTreasure();

        LegionSquadInfo
            memory _legionSquadInfo = legionSquadIdToLegionSquadInfo[
                _legionSquadId
            ];

        require(_legionSquadInfo.onBoard, "Legion squad not on board!.");

        //If this call is coming from a place that has already ensured they are allowed to claim it, bypass the coordinate check.
        //Not publically callable, so no chance of exploitation thru passing true when not allowed.
        if (!_bypassCoordinateCheck) {
            //Pull coordinate into memory.
            Coordinate memory _currentCoordinate = _legionSquadInfo.coordinate;

            //Require they are on the treasure.
            require(
                _currentCoordinate.x == _boardTreasure.coordinate.x &&
                    _currentCoordinate.y == _boardTreasure.coordinate.y,
                "You aren't on the treasure!"
            );
        }

        //Require max treasures haven't been claimed
        require(
            _boardTreasure.maxSupply > _boardTreasure.numClaimed,
            "Max treasures for this round claimed"
        );

        //Require they haven't claimed a fragment this round
        require(
            _legionSquadInfo.mostRecentRoundTreasureClaimed < currentRoundId,
            "You already claimed a treasure fragment in this round!"
        );

        //Record that they claimed this round
        legionSquadIdToLegionSquadInfo[_legionSquadId]
            .mostRecentRoundTreasureClaimed = uint32(currentRoundId);

        //increment num claimed.
        boardTreasure.numClaimed++;

        treasureFragment.mint(_user, boardTreasure.correspondingId, 1);

        //emit event
        emit TreasureClaimed(
            _user,
            _legionSquadId,
            _boardTreasure,
            currentRoundId
        );
    }

    function createLegionSquad(
        address _user,
        uint32[] memory _legionIds,
        uint256 _targetTemple,
        string memory _legionSquadName
    ) internal {
        require(
            _legionIds.length <= gameConfig.maximumLegionsInSquad,
            "Exceeds maximum legions in squad."
        );

        //Ensure they have less than X
        require(
            addressToUserData[_user].numberOfLegionSquadsOnBoard <
                gameConfig.maximumLegionSquadsOnBoard,
            "Already have maximum squads on field"
        );

        //Increment how many they have.
        addressToUserData[_user].numberOfLegionSquadsOnBoard++;

        //Ensure they own all the legions
        //Mark as staked
        for (uint256 i = 0; i < _legionIds.length; i++) {
            //Ensure they're not a recruit
            require(
                legionMetadataStore
                    .metadataForLegion(_legionIds[i])
                    .legionGeneration != LegionGeneration.RECRUIT,
                "Legion cannot be a recruit!"
            );

            //Transfer it to the staking contract
            legionContract.adminSafeTransferFrom(
                _user,
                address(this),
                _legionIds[i]
            );
        }

        //Ensure temple is currently enterable
        require(
            templeIdToTemples[uint16(_targetTemple)].latestRoundIdEnterable ==
                currentRoundId,
            "Temple is not active!"
        );

        uint64 thisLegionSquadId = legionSquadCurrentId;
        legionSquadCurrentId++;

        legionSquadIdToLegionSquadInfo[thisLegionSquadId] = LegionSquadInfo(
            //Owner
            msg.sender,
            //This id
            thisLegionSquadId,
            //Last round entered temple
            0,
            //Most recent round treasure claimed
            0,
            //Coordinate
            Coordinate(0, 0),
            //Target temple
            uint16(_targetTemple),
            //In temple
            false,
            //Exists
            true,
            //On board
            false,
            //Legion Ids
            _legionIds,
            //Legion Squad Name
            _legionSquadName
        );

        //Increment legion squad current Id
        legionSquadCurrentId++;

        emit LegionSquadStaked(
            _user,
            thisLegionSquadId,
            _legionIds,
            uint16(_targetTemple),
            _legionSquadName
        );
    }

    function placeLegionSquad(
        address _user,
        uint64 _legionSquadId,
        Coordinate memory _coordinate
    ) internal onlyValidLegionSquadAndLegionSquadOwner(_user, _legionSquadId) {
        //Ensure they do not have staking cooldown
        require(
            block.timestamp >= addressToUserData[_user].cooldownEnd,
            "cooldown hasn't ended!"
        );

        //Require they are currently off board
        require(
            !legionSquadIdToLegionSquadInfo[_legionSquadId].onBoard,
            "Legion squad already on board!"
        );

        //Require they are placing it >x distance from a temple.
        require(
            !ICorruptionCryptsInternal(address(this)).withinDistanceOfTemple(
                _coordinate
            ),
            "Placement is too close to a temple!"
        );

        //Pull this cell into memory
        Cell memory thisCell = addressToUserData[_user].currentBoard[
            _coordinate.x
        ][_coordinate.y];

        //Ensure this cell does not have a legion squad
        require(!thisCell.hasLegionSquad, "Cell already has legion squad!");

        //Ensure map tiles exists here
        require(thisCell.hasMapTile, "This cell has no map tile");

        //Set cell to containing this legion squad id
        thisCell.legionSquadId = _legionSquadId;

        //Set cell to containing a legion squad
        thisCell.hasLegionSquad = true;

        //Store cell.
        addressToUserData[_user].currentBoard[_coordinate.x][
            _coordinate.y
        ] = thisCell;

        //Store them on this coordinate
        legionSquadIdToLegionSquadInfo[_legionSquadId].coordinate = _coordinate;

        //Set them as on the board.
        legionSquadIdToLegionSquadInfo[_legionSquadId].onBoard = true;

        emit LegionSquadMoved(_user, _legionSquadId, _coordinate);
    }

    function removeLegionSquad(address _user, uint64 _legionSquadId)
        internal
        onlyValidLegionSquadAndLegionSquadOwner(_user, _legionSquadId)
    {
        LegionSquadInfo
            memory _legionSquadInfo = legionSquadIdToLegionSquadInfo[
                _legionSquadId
            ];

        require(_legionSquadInfo.onBoard, "Legion squad not on board!.");

        //Set their cooldown to now plus cooldown time.
        addressToUserData[_user].cooldownEnd =
            uint64(block.timestamp) +
            gameConfig.legionUnstakeCooldown;

        //Remove it from its cell.
        addressToUserData[_user]
        .currentBoard[_legionSquadInfo.coordinate.x][
            _legionSquadInfo.coordinate.y
        ].hasLegionSquad = false;

        //Record legion squad as 0
        addressToUserData[_user]
        .currentBoard[_legionSquadInfo.coordinate.x][
            _legionSquadInfo.coordinate.y
        ].legionSquadId = 0;

        //Mark as off board
        legionSquadIdToLegionSquadInfo[_legionSquadId].onBoard = false;

        emit LegionSquadRemoved(_user, _legionSquadId);
    }

    function dissolveLegionSquad(address _user, uint64 _legionSquadId)
        internal
        onlyValidLegionSquadAndLegionSquadOwner(_user, _legionSquadId)
    {
        LegionSquadInfo
            memory _legionSquadInfo = legionSquadIdToLegionSquadInfo[
                _legionSquadId
            ];

        require(!_legionSquadInfo.onBoard, "Legion squad on board!.");

        //Mark it as not existing.
        legionSquadIdToLegionSquadInfo[_legionSquadId].exists = false;

        //Decrement one from the count of legion squads on the board.
        addressToUserData[_user].numberOfLegionSquadsOnBoard--;

        //Loop their legions and set as unstaked.
        for (uint256 i = 0; i < _legionSquadInfo.legionIds.length; i++) {
            //Transfer it from the staking contract
            legionContract.adminSafeTransferFrom(
                address(this),
                _user,
                _legionSquadInfo.legionIds[i]
            );
        }

        emit LegionSquadUnstaked(_user, _legionSquadId);
    }

    function blowUpMapTile(address _user, Coordinate memory _coordinate)
        internal
    {
        Cell memory _thisCell = addressToUserData[_user].currentBoard[
            _coordinate.x
        ][_coordinate.y];

        //Make sure there is a tile here
        require(_thisCell.hasMapTile, "This tile does not have a maptile!");
        //Make sure there is not a legion squad
        require(!_thisCell.hasLegionSquad, "This tile has a legion squad!");

        //Burn the essence of starlight.
        consumable.adminBurn(_user, gameConfig.EOSID, gameConfig.EOSAmount);
        //Burn the prism shards
        consumable.adminBurn(
            _user,
            gameConfig.prismShardID,
            gameConfig.prismShardAmount
        );

        removeMapTileFromBoard(_user, _thisCell.mapTile.mapTileId);
    }

    function takeTurn(Move[] calldata _moves) public {
        bool claimedMapTiles;

        for (uint256 moveIndex = 0; moveIndex < _moves.length; moveIndex++) {
            Move calldata move = _moves[moveIndex];
            bytes calldata moveDataBytes = move.moveData;

            if (move.moveTypeId == MoveType.ClaimMapTiles) {
                claimMapTiles(msg.sender);
                claimedMapTiles = true;
                continue;
            }

            if (move.moveTypeId == MoveType.PlaceMapTile) {
                //Place map tile

                (uint32 _mapTileId, Coordinate memory _coordinate) = abi.decode(
                    moveDataBytes,
                    (uint32, Coordinate)
                );

                placeMapTile(msg.sender, _mapTileId, _coordinate);
                continue;
            }

            if (move.moveTypeId == MoveType.EnterTemple) {
                //Enter temple

                uint64 _legionSquadId = abi.decode(moveDataBytes, (uint64));

                enterTemple(msg.sender, _legionSquadId);

                continue;
            }

            if (move.moveTypeId == MoveType.ClaimTreasure) {
                //Claim Treasure

                uint64 _legionSquadId = abi.decode(moveDataBytes, (uint64));

                //Claim this treasure, with bypass false.
                claimTreasure(msg.sender, _legionSquadId, false);

                continue;
            }

            if (move.moveTypeId == MoveType.MoveLegionSquad) {
                //Move legion squad

                (
                    uint64 _legionSquadId,
                    uint32 _mapTileId,
                    Coordinate[] memory _coordinates
                ) = abi.decode(moveDataBytes, (uint64, uint32, Coordinate[]));

                moveLegionSquad(
                    msg.sender,
                    _legionSquadId,
                    _mapTileId,
                    _coordinates
                );

                continue;
            }

            if (move.moveTypeId == MoveType.CreateLegionSquad) {
                //Create legion squad

                (
                    uint32[] memory _legionIds,
                    uint8 _targetTemple,
                    string memory _legionSquadName
                ) = abi.decode(moveDataBytes, (uint32[], uint8, string));

                createLegionSquad(
                    msg.sender,
                    _legionIds,
                    _targetTemple,
                    _legionSquadName
                );
                continue;
            }

            if (move.moveTypeId == MoveType.PlaceLegionSquad) {
                //Place legion squad

                (uint64 _legionSquadId, Coordinate memory _coordinate) = abi
                    .decode(moveDataBytes, (uint64, Coordinate));

                placeLegionSquad(msg.sender, _legionSquadId, _coordinate);
                continue;
            }

            if (move.moveTypeId == MoveType.RemoveLegionSquad) {
                //Remove legion squad

                uint64 _legionSquadId = abi.decode(moveDataBytes, (uint64));

                removeLegionSquad(msg.sender, _legionSquadId);

                continue;
            }

            if (move.moveTypeId == MoveType.DissolveLegionSquad) {
                //Dissolve legion squad

                uint64 _legionSquadId = abi.decode(moveDataBytes, (uint64));

                dissolveLegionSquad(msg.sender, _legionSquadId);

                continue;
            }

            if (move.moveTypeId == MoveType.BlowUpMapTile) {
                //BlowUpMapTile

                Coordinate memory _coordinate = abi.decode(
                    moveDataBytes,
                    (Coordinate)
                );

                blowUpMapTile(msg.sender, _coordinate);

                continue;
            }

            revert();
        }

        if (claimedMapTiles) {
            //If they claimed map tiles in this turn request a new random number.
            uint64 _requestId = uint64(randomizer.requestRandomNumber());

            //Store their request Id.
            addressToUserData[msg.sender].requestId = _requestId;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "solidity-linked-list/contracts/StructuredLinkedList.sol";
import "../legionmetadatastore/ILegionMetadataStore.sol";
import "../treasurefragment/ITreasureFragment.sol";
import "../harvesterfactory/IHarvesterFactory.sol";
import "../../shared/randomizer/IRandomizer.sol";
import "../../shared/AdminableUpgradeable.sol";
import "./ICorruptionCryptsInternal.sol";
import "../consumable/IConsumable.sol";
import "../legion/ILegion.sol";
import "./MapTiles.sol";

abstract contract CorruptionCryptsDiamondState is
    Initializable,
    MapTiles,
    OwnableUpgradeable,
    AdminableUpgradeable
{
    using StructuredLinkedList for StructuredLinkedList.List;

    //External Contracts
    IConsumable public consumable;
    IRandomizer public randomizer;
    ILegion public legionContract;
    IHarvesterFactory public harvesterFactory;
    ITreasureFragment public treasureFragment;
    ILegionMetadataStore public legionMetadataStore;

    //Global Structs
    BoardTreasure boardTreasure;
    GameConfig gameConfig;

    //Events
    event MapTilesClaimed(address _user, MapTile[] _mapTiles, uint256 _roundId);
    event MapTilePlaced(
        address _user,
        MapTile _mapTile,
        Coordinate _coordinate,
        uint256 _roundId
    );
    event MapTileRemoved(
        address _user,
        uint32 _mapTileId,
        Coordinate _coordinate,
        uint256 _roundId
    );

    event TempleEntered(
        address _user,
        uint64 _legionSquadId,
        uint16 _targetTemple,
        uint256 _roundId
    );

    event TempleCreated(uint16 thisTempleId, address _thisHarvester);

    event LegionSquadMoved(
        address _user,
        uint64 _legionSquadId,
        Coordinate _finalCoordinate
    );

    event LegionSquadStaked(
        address _user,
        uint64 _legionSquadId,
        uint32[] _legionIds,
        uint16 _targetTemple,
        string _legionSquadName
    );

    event LegionSquadRemoved(address _user, uint64 _legionSquadId);

    event LegionSquadUnstaked(address _user, uint64 _legionSquadId);

    //Emitted when requestGlobalRandomness() is called.
    event GlobalRandomnessRequested(uint256 _globalRequestId, uint256 _roundId);

    event TreasureClaimed(
        address _user,
        uint64 _legionSquadId,
        BoardTreasure _boardTreasure,
        uint256 _roundId
    );

    event ConfigUpdated(GameConfig _newConfig);

    //What round id this round is.
    uint256 public currentRoundId;

    //The timestamp that this round started at.
    uint256 roundStartTime;

    //How many legions have reached the temple this round.
    uint256 numLegionsReachedTemple;

    //Global seed (effects temples and treasures.).
    uint256 globalRequestId;

    //Record the first ever global seed (for future events like user first claiming map tiles.)
    uint256 globalStartingRequestId;

    //Current legion squad Id, increments up by one.
    uint64 legionSquadCurrentId;

    //Address to user data.
    mapping(address => UserData) addressToUserData;

    //Legion squad id to legion squad info.
    mapping(uint64 => LegionSquadInfo) legionSquadIdToLegionSquadInfo;

    //Record temple details.
    mapping(uint16 => Temple) templeIdToTemples;

    mapping(address => uint16) harvesterAddressToTempleId;

    uint16[] activeTemples;

    uint16 currentTempleId;

    function generateRandomNumber(
        uint256 _min,
        uint256 _max,
        uint256 _seed
    ) internal pure returns (uint256) {
        return _min + (_seed % (_max + 1 - _min));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solidity-linked-list/contracts/StructuredLinkedList.sol";

struct Temple {
    Coordinate coordinate;
    address harvesterAddress;
    uint32 latestRoundIdEnterable;
    uint16 templeId;
}

struct MapTile {
    //56 TOTAL BITS.
    uint32 mapTileId;
    uint8 mapTileType;
    uint8 moves;
    bool north;
    bool east;
    bool south;
    bool west;
    // directions of roads on each MapTile
}

enum MoveType {
    ClaimMapTiles,
    PlaceMapTile,
    EnterTemple,
    ClaimTreasure,
    MoveLegionSquad,
    CreateLegionSquad,
    PlaceLegionSquad,
    RemoveLegionSquad,
    DissolveLegionSquad,
    BlowUpMapTile
}

struct Coordinate {
    uint8 x;
    uint8 y;
}

struct Move {
    MoveType moveTypeId;
    bytes moveData;
}

struct Cell {
    //56 BITS.
    MapTile mapTile;
    //2 BITS
    bool hasMapTile;
    //64 BITS
    uint64 legionSquadId;
    //2 BITS
    bool hasLegionSquad;
}

struct LegionSquadInfo {
    //160 bites
    address owner;
    //64 bits
    uint64 legionSquadId;
    //32 bits
    uint32 lastRoundEnteredTemple;
    //32 bits
    uint32 mostRecentRoundTreasureClaimed;
    //16 bits
    Coordinate coordinate;
    //8 bits
    uint16 targetTemple;
    //8 bits
    bool inTemple;
    //8 bits
    bool exists;
    //8 bits
    bool onBoard;
    //224 bits left over
    //x * 16 bits
    uint32[] legionIds;
    //arbitrary number of bits
    string legionSquadName;
}

struct UserData {
    mapping(uint256 => uint256) roundIdToEpochLastClaimedMapTiles;
    mapping(uint32 => Coordinate) mapTileIdToCoordinate;
    StructuredLinkedList.List mapTilesOnBoard;
    Cell[10][16] currentBoard;
    MapTile[] mapTilesInHand;
    uint64 cooldownEnd;
    uint64 requestId;
    uint8 numberOfLegionSquadsOnBoard;
}

struct BoardTreasure {
    Coordinate coordinate;
    uint8 treasureTier;
    uint8 affinity;
    uint8 correspondingId;
    uint16 numClaimed;
    uint16 maxSupply;
}

struct StakingDetails {
    bool staked;
    address staker;
}

struct GameConfig {
    uint256 secondsInEpoch;
    uint256 numLegionsReachedTempleToAdvanceRound;
    uint256 maxMapTilesInHand;
    uint256 maxMapTilesOnBoard;
    uint256 maximumLegionSquadsOnBoard;
    uint256 maximumLegionsInSquad;
    uint64 legionUnstakeCooldown;
    uint256 minimumDistanceFromTempleForLegionSquad;
    uint256 EOSID;
    uint256 EOSAmount;
    uint256 prismShardID;
    uint256 prismShardAmount;
}

interface ICorruptionCryptsInternal {
    function withinDistanceOfTemple(Coordinate memory)
        external
        view
        returns (bool);

    function generateTemplePositions() external view returns (Temple[] memory);

    function updateHarvestersRecord() external;

    function decideMovabilityBasedOnTwoCoordinates(
        address,
        Coordinate memory,
        Coordinate memory
    ) external view returns (bool);

    function generateMapTiles(uint256, address)
        external
        view
        returns (MapTile[] memory);

    function calculateNumPendingMapTiles(address)
        external
        view
        returns (uint256);

    function currentEpoch() external view returns (uint256);

    function generateTempleCoordinate(uint256)
        external
        view
        returns (Coordinate memory);

    function generateBoardTreasure()
        external
        view
        returns (BoardTreasure memory);

            function getMapTileByIDAndUser(uint128, address)
        external
        view
        returns (MapTile memory, uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ICorruptionCryptsInternal.sol";

contract MapTiles is Initializable {
    event MapTilesInitialized(MapTile[] _mapTiles);

    mapping(uint8 => MapTile) mapTiles;

    function initMapTiles() internal {
        // See https://boardgamegeek.com/image/3128699/karuba
        // for the tile road directions

        MapTile[] memory _mapTiles = new MapTile[](36);

        _mapTiles[0] = MapTile({
            mapTileId: 1,
            mapTileType: 1,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[1] = MapTile({
            mapTileId: 2,
            mapTileType: 2,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[2] = MapTile({
            mapTileId: 3,
            mapTileType: 3,
            moves: 2,
            north: false,
            east: true,
            south: true,
            west: false
        });
        _mapTiles[3] = MapTile({
            mapTileId: 4,
            mapTileType: 4,
            moves: 2,
            north: false,
            east: false,
            south: true,
            west: true
        });
        _mapTiles[4] = MapTile({
            mapTileId: 5,
            mapTileType: 5,
            moves: 3,
            north: false,
            east: true,
            south: true,
            west: true
        });
        _mapTiles[5] = MapTile({
            mapTileId: 6,
            mapTileType: 6,
            moves: 3,
            north: false,
            east: true,
            south: true,
            west: true
        });

        _mapTiles[6] = MapTile({
            mapTileId: 7,
            mapTileType: 7,
            moves: 4,
            north: true,
            east: true,
            south: true,
            west: true
        });
        _mapTiles[7] = MapTile({
            mapTileId: 8,
            mapTileType: 8,
            moves: 4,
            north: true,
            east: true,
            south: true,
            west: true
        });
        _mapTiles[8] = MapTile({
            mapTileId: 9,
            mapTileType: 9,
            moves: 2,
            north: true,
            east: true,
            south: false,
            west: false
        });
        _mapTiles[9] = MapTile({
            mapTileId: 10,
            mapTileType: 10,
            moves: 2,
            north: true,
            east: false,
            south: false,
            west: true
        });
        _mapTiles[10] = MapTile({
            mapTileId: 11,
            mapTileType: 11,
            moves: 3,
            north: true,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[11] = MapTile({
            mapTileId: 12,
            mapTileType: 12,
            moves: 3,
            north: true,
            east: true,
            south: false,
            west: true
        });

        _mapTiles[12] = MapTile({
            mapTileId: 13,
            mapTileType: 13,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[13] = MapTile({
            mapTileId: 14,
            mapTileType: 14,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[14] = MapTile({
            mapTileId: 15,
            mapTileType: 15,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[15] = MapTile({
            mapTileId: 16,
            mapTileType: 16,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[16] = MapTile({
            mapTileId: 17,
            mapTileType: 17,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });
        _mapTiles[17] = MapTile({
            mapTileId: 18,
            mapTileType: 18,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });

        _mapTiles[18] = MapTile({
            mapTileId: 19,
            mapTileType: 19,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[19] = MapTile({
            mapTileId: 20,
            mapTileType: 20,
            moves: 2,
            north: false,
            east: true,
            south: false,
            west: true
        });
        _mapTiles[20] = MapTile({
            mapTileId: 21,
            mapTileType: 21,
            moves: 2,
            north: false,
            east: true,
            south: true,
            west: false
        });
        _mapTiles[21] = MapTile({
            mapTileId: 22,
            mapTileType: 22,
            moves: 2,
            north: false,
            east: false,
            south: true,
            west: true
        });
        _mapTiles[22] = MapTile({
            mapTileId: 23,
            mapTileType: 23,
            moves: 3,
            north: true,
            east: true,
            south: true,
            west: false
        });
        _mapTiles[23] = MapTile({
            mapTileId: 24,
            mapTileType: 24,
            moves: 3,
            north: true,
            east: false,
            south: true,
            west: true
        });

        _mapTiles[24] = MapTile({
            mapTileId: 25,
            mapTileType: 25,
            moves: 4,
            north: true,
            east: true,
            south: true,
            west: true
        });
        _mapTiles[25] = MapTile({
            mapTileId: 26,
            mapTileType: 26,
            moves: 4,
            north: true,
            east: true,
            south: true,
            west: true
        });
        _mapTiles[26] = MapTile({
            mapTileId: 27,
            mapTileType: 27,
            moves: 2,
            north: true,
            east: true,
            south: false,
            west: false
        });
        _mapTiles[27] = MapTile({
            mapTileId: 28,
            mapTileType: 28,
            moves: 2,
            north: true,
            east: false,
            south: false,
            west: true
        });
        _mapTiles[28] = MapTile({
            mapTileId: 29,
            mapTileType: 29,
            moves: 3,
            north: true,
            east: true,
            south: true,
            west: false
        });
        _mapTiles[29] = MapTile({
            mapTileId: 30,
            mapTileType: 30,
            moves: 3,
            north: true,
            east: false,
            south: true,
            west: true
        });

        _mapTiles[30] = MapTile({
            mapTileId: 31,
            mapTileType: 31,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });
        _mapTiles[31] = MapTile({
            mapTileId: 32,
            mapTileType: 32,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });
        _mapTiles[32] = MapTile({
            mapTileId: 33,
            mapTileType: 33,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });
        _mapTiles[33] = MapTile({
            mapTileId: 34,
            mapTileType: 34,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });
        _mapTiles[34] = MapTile({
            mapTileId: 35,
            mapTileType: 35,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });
        _mapTiles[35] = MapTile({
            mapTileId: 36,
            mapTileType: 36,
            moves: 2,
            north: true,
            east: false,
            south: true,
            west: false
        });

        for (uint8 i = 0; i < 36; i++) {
            mapTiles[i] = _mapTiles[i];
        }

        emit MapTilesInitialized(_mapTiles);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../middleman/IMiddleman.sol';

interface IHarvesterFactory {
    function magic() external view returns (IERC20);
    function middleman() external view returns (IMiddleman);
    function getAllHarvesters() external view returns (address[] memory);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMiddleman {
    function requestRewards() external returns (uint256 rewardsPaid);

    function getPendingRewards(address _stream) external view returns (uint256 pendingRewards);
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

interface IStructureInterface {
    function getValue(uint256 _id) external view returns (uint256);
}

/**
 * @title StructuredLinkedList
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev An utility library for using sorted linked list data structures in your Solidity project.
 */
library StructuredLinkedList {
    uint256 private constant _NULL = 0;
    uint256 private constant _HEAD = 0;

    bool private constant _PREV = false;
    bool private constant _NEXT = true;

    struct List {
        uint256 size;
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    /**
     * @dev Checks if the list exists
     * @param self stored linked list from contract
     * @return bool true if list exists, false otherwise
     */
    function listExists(List storage self) internal view returns (bool) {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[_HEAD][_PREV] != _HEAD || self.list[_HEAD][_NEXT] != _HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Checks if the node exists
     * @param self stored linked list from contract
     * @param _node a node to search for
     * @return bool true if node exists, false otherwise
     */
    function nodeExists(List storage self, uint256 _node) internal view returns (bool) {
        if (self.list[_node][_PREV] == _HEAD && self.list[_node][_NEXT] == _HEAD) {
            if (self.list[_HEAD][_NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of elements in the list
     * @param self stored linked list from contract
     * @return uint256
     */
    function sizeOf(List storage self) internal view returns (uint256) {
        return self.size;
    }

    /**
     * @dev Returns the links of a node as a tuple
     * @param self stored linked list from contract
     * @param _node id of the node to get
     * @return bool, uint256, uint256 true if node exists or false otherwise, previous node, next node
     */
    function getNode(List storage self, uint256 _node) internal view returns (bool, uint256, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][_PREV], self.list[_node][_NEXT]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @param _direction direction to step in
     * @return bool, uint256 true if node exists or false otherwise, node in _direction
     */
    function getAdjacent(List storage self, uint256 _node, bool _direction) internal view returns (bool, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, next node
     */
    function getNextNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _NEXT);
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, previous node
     */
    function getPreviousNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _PREV);
    }

    /**
     * @dev Can be used before `insert` to build an ordered list.
     * @dev Get the node and then `insertBefore` or `insertAfter` basing on your list order.
     * @dev If you want to order basing on other than `structure.getValue()` override this function
     * @param self stored linked list from contract
     * @param _structure the structure instance
     * @param _value value to seek
     * @return uint256 next node with a value less than _value
     */
    function getSortedSpot(List storage self, address _structure, uint256 _value) internal view returns (uint256) {
        if (sizeOf(self) == 0) {
            return 0;
        }

        uint256 next;
        (, next) = getAdjacent(self, _HEAD, _NEXT);
        while ((next != 0) && ((_value < IStructureInterface(_structure).getValue(next)) != _NEXT)) {
            next = self.list[next][_NEXT];
        }
        return next;
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertAfter(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _NEXT);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertBefore(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _PREV);
    }

    /**
     * @dev Removes an entry from the linked list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     * @return uint256 the removed node
     */
    function remove(List storage self, uint256 _node) internal returns (uint256) {
        if ((_node == _NULL) || (!nodeExists(self, _node))) {
            return 0;
        }
        _createLink(self, self.list[_node][_PREV], self.list[_node][_NEXT], _NEXT);
        delete self.list[_node][_PREV];
        delete self.list[_node][_NEXT];

        self.size -= 1; // NOT: SafeMath library should be used here to decrement.

        return _node;
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @return bool true if success, false otherwise
     */
    function pushFront(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _NEXT);
    }

    /**
     * @dev Pushes an entry to the tail of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the tail
     * @return bool true if success, false otherwise
     */
    function pushBack(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _PREV);
    }

    /**
     * @dev Pops the first entry from the head of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popFront(List storage self) internal returns (uint256) {
        return _pop(self, _NEXT);
    }

    /**
     * @dev Pops the first entry from the tail of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popBack(List storage self) internal returns (uint256) {
        return _pop(self, _PREV);
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @param _direction push to the head (_NEXT) or tail (_PREV)
     * @return bool true if success, false otherwise
     */
    function _push(List storage self, uint256 _node, bool _direction) private returns (bool) {
        return _insert(self, _HEAD, _node, _direction);
    }

    /**
     * @dev Pops the first entry from the linked list
     * @param self stored linked list from contract
     * @param _direction pop from the head (_NEXT) or the tail (_PREV)
     * @return uint256 the removed node
     */
    function _pop(List storage self, bool _direction) private returns (uint256) {
        uint256 adj;
        (, adj) = getAdjacent(self, _HEAD, _direction);
        return remove(self, adj);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @param _direction direction to insert node in
     * @return bool true if success, false otherwise
     */
    function _insert(List storage self, uint256 _node, uint256 _new, bool _direction) private returns (bool) {
        if (!nodeExists(self, _new) && nodeExists(self, _node)) {
            uint256 c = self.list[_node][_direction];
            _createLink(self, _node, _new, _direction);
            _createLink(self, _new, c, _direction);

            self.size += 1; // NOT: SafeMath library should be used here to increment.

            return true;
        }

        return false;
    }

    /**
     * @dev Creates a bidirectional link between two nodes on direction `_direction`
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _link node to link to in the _direction
     * @param _direction direction to insert node in
     */
    function _createLink(List storage self, uint256 _node, uint256 _link, bool _direction) private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}