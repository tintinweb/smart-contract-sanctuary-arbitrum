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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Context.sol";

/**
    https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
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
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IWorldModule {
    function moduleID() external view returns (uint256);

    function tokenSVG(uint256 _actor, uint256 _startY, uint256 _lineHeight) external view returns (string memory, uint256 _endY);
    function tokenJSON(uint256 _actor) external view returns (string memory);
}

interface IWorldRandom is IWorldModule {
    function dn(uint256 _actor, uint256 _number) external view returns (uint256);
    function d20(uint256 _actor) external view returns (uint256);
}

interface IActors is IERC721, IWorldModule {

    struct Actor 
    {
        address owner;
        address account;
        uint256 actorId;
    }

    event TaiyiDAOUpdated(address taiyiDAO);
    event ActorMinted(address indexed owner, uint256 indexed actorId, uint256 indexed time);
    event ActorPurchased(address indexed payer, uint256 indexed actorId, uint256 price);

    function actor(uint256 _actor) external view returns (uint256 _mintTime, uint256 _status);
    function nextActor() external view returns (uint256);
    function mintActor(uint256 maxPrice) external returns(uint256 actorId);
    function changeActorRenderMode(uint256 _actor, uint256 _mode) external;
    function setTaiyiDAO(address _taiyiDAO) external;

    function actorPrice() external view returns (uint256);
    function getActor(uint256 _actor) external view returns (Actor memory);
    function getActorByHolder(address _holder) external view returns (Actor memory);
    function getActorsByOwner(address _owner) external view returns (Actor[] memory);
    function isHolderExist(address _holder) external view returns (bool);
}

interface IWorldYemings is IWorldModule {
    event TaiyiDAOUpdated(address taiyiDAO);

    function setTaiyiDAO(address _taiyiDAO) external;

    function YeMings(uint256 _actor) external view returns (address);
    function isYeMing(uint256 _actor) external view returns (bool);
}

interface IWorldTimeline is IWorldModule {

    event AgeEvent(uint256 indexed actor, uint256 indexed age, uint256 indexed eventId);
    event BranchEvent(uint256 indexed actor, uint256 indexed age, uint256 indexed eventId);
    event ActiveEvent(uint256 indexed actor, uint256 indexed age, uint256 indexed eventId);

    function name() external view returns (string memory);
    function description() external view returns (string memory);
    function operator() external view returns (uint256);
    function events() external view returns (IWorldEvents);

    function grow(uint256 _actor) external;
    function activeTrigger(uint256 _eventId, uint256 _actor, uint256[] memory _uintParams, string[] memory _stringParams) external;
}

interface IActorAttributes is IWorldModule {

    event Created(address indexed creator, uint256 indexed actor, uint256[] attributes);
    event Updated(address indexed executor, uint256 indexed actor, uint256[] attributes);

    function setAttributes(uint256 _operator, uint256 _actor, uint256[] memory _attributes) external;
    function pointActor(uint256 _operator, uint256 _actor) external;

    function attributeLabels(uint256 _attributeId) external view returns (string memory);
    function attributesScores(uint256 _attributeId, uint256 _actor) external view returns (uint256);
    function characterPointsInitiated(uint256 _actor) external view returns (bool);
    function applyModified(uint256 _actor, int[] memory _modifiers) external view returns (uint256[] memory, bool);
}

interface IActorBehaviorAttributes is IActorAttributes {

    event ActRecovered(uint256 indexed actor, uint256 indexed act);

    function canRecoverAct(uint256 _actor) external view returns (bool);
    function recoverAct(uint256 _actor) external;
}

interface IActorTalents is IWorldModule {

    event Created(address indexed creator, uint256 indexed actor, uint256[] ids);

    function talents(uint256 _id) external view returns (string memory _name, string memory _description);
    function talentAttributeModifiers(uint256 _id) external view returns (int256[] memory);
    function talentAttrPointsModifiers(uint256 _id, uint256 _attributeModuleId) external view returns (int256);
    function setTalent(uint256 _id, string memory _name, string memory _description, int[] memory _modifiers, int256[] memory _attr_point_modifiers) external;
    function setTalentExclusive(uint256 _id, uint256[] memory _exclusive) external;
    function setTalentProcessor(uint256 _id, address _processorAddress) external;
    function talentProcessors(uint256 _id) external view returns(address);
    function talentExclusivity(uint256 _id) external view returns (uint256[] memory);

    function setActorTalent(uint256 _operator, uint256 _actor, uint256 _tid) external;
    function talentActor(uint256 _operator, uint256 _actor) external; 
    function actorAttributePointBuy(uint256 _actor, uint256 _attributeModuleId) external view returns (uint256);
    function actorTalents(uint256 _actor) external view returns (uint256[] memory);
    function actorTalentsInitiated(uint256 _actor) external view returns (bool);
    function actorTalentsExist(uint256 _actor, uint256[] memory _talents) external view returns (bool[] memory);
    function canOccurred(uint256 _actor, uint256 _id, uint256 _age) external view returns (bool);
}

interface IActorTalentProcessor {
    function checkOccurrence(uint256 _actor, uint256 _age) external view returns (bool);
    function process(uint256 _operator, uint256 _actor, uint256 _age) external;
}

interface IWorldEvents is IWorldModule {

    event Born(uint256 indexed actor);

    function ages(uint256 _actor) external view returns (uint256); //current age
    function actorBorn(uint256 _actor) external view returns (bool);
    function actorBirthday(uint256 _actor) external view returns (bool);
    function expectedAge(uint256 _actor) external view returns (uint256); //age should be
    function actorEvent(uint256 _actor, uint256 _age) external view returns (uint256[] memory);
    function actorEventCount(uint256 _actor, uint256 _eventId) external view returns (uint256);

    function eventInfo(uint256 _id, uint256 _actor) external view returns (string memory);
    function eventAttributeModifiers(uint256 _id, uint256 _actor) external view returns (int256[] memory);
    function eventProcessors(uint256 _id) external view returns(address);
    function setEventProcessor(uint256 _id, address _address) external;
    function canOccurred(uint256 _actor, uint256 _id, uint256 _age) external view returns (bool);
    function checkBranch(uint256 _actor, uint256 _id, uint256 _age) external view returns (uint256);

    function bornActor(uint256 _operator, uint256 _actor) external;
    function grow(uint256 _operator, uint256 _actor) external;
    function changeAge(uint256 _operator, uint256 _actor, uint256 _age) external;
    function addActorEvent(uint256 _operator, uint256 _actor, uint256 _age, uint256 _eventId) external;
}

interface IWorldEventProcessor {
    function eventInfo(uint256 _actor) external view returns (string memory);
    function eventAttributeModifiers(uint256 _actor) external view returns (int[] memory);
    function trigrams(uint256 _actor) external view returns (uint256[] memory);
    function checkOccurrence(uint256 _actor, uint256 _age) external view returns (bool);
    function process(uint256 _operator, uint256 _actor, uint256 _age) external;
    function activeTrigger(uint256 _operator, uint256 _actor, uint256[] memory _uintParams, string[] memory _stringParams) external;

    function checkBranch(uint256 _actor, uint256 _age) external view returns (uint256);
    function setDefaultBranch(uint256 _enentId) external;
}

interface IWorldFungible is IWorldModule {
    event FungibleTransfer(uint256 indexed from, uint256 indexed to, uint256 amount);
    event FungibleApproval(uint256 indexed from, uint256 indexed to, uint256 amount);

    function balanceOfActor(uint256 _owner) external view returns (uint256);
    function allowanceActor(uint256 _owner, uint256 _spender) external view returns (uint256);

    function approveActor(uint256 _from, uint256 _spender, uint256 _amount) external;
    function transferActor(uint256 _from, uint256 _to, uint256 _amount) external;
    function transferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _amount) external;
    function claim(uint256 _operator, uint256 _actor, uint256 _amount) external;
    function withdraw(uint256 _operator, uint256 _actor, uint256 _amount) external;
}

interface IWorldNonfungible {
    event NonfungibleTransfer(uint256 indexed from, uint256 indexed to, uint256 indexed tokenId);
    event NonfungibleApproval(uint256 indexed owner, uint256 indexed approved, uint256 indexed tokenId);
    event NonfungibleApprovalForAll(uint256 indexed owner, uint256 indexed operator, bool approved);

    function tokenOfActorByIndex(uint256 _owner, uint256 _index) external view returns (uint256);
    function balanceOfActor(uint256 _owner) external view returns (uint256);
    function ownerActorOf(uint256 _tokenId) external view returns (uint256);
    function getApprovedActor(uint256 _tokenId) external view returns (uint256);
    function isApprovedForAllActor(uint256 _owner, uint256 _operator) external view returns (bool);

    function approveActor(uint256 _from, uint256 _to, uint256 _tokenId) external;
    function setApprovalForAllActor(uint256 _from, uint256 _operator, bool _approved) external;
    function safeTransferActor(uint256 _from, uint256 _to, uint256 _tokenId, bytes calldata _data) external;
    function safeTransferActor(uint256 _from, uint256 _to, uint256 _tokenId) external;
    function transferActor(uint256 _from, uint256 _to, uint256 _tokenId) external;
    function safeTransferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _tokenId, bytes calldata _data) external;
    function safeTransferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _tokenId) external;
    function transferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _tokenId) external;
}

interface IActorNames is IWorldNonfungible, IERC721Enumerable, IWorldModule {

    event NameClaimed(address indexed owner, uint256 indexed actor, uint256 indexed nameId, string name, string firstName, string lastName);
    event NameUpdated(uint256 indexed nameId, string oldName, string newName);
    event NameAssigned(uint256 indexed nameId, uint256 indexed previousActor, uint256 indexed newActor);

    function nextName() external view returns (uint256);
    function actorName(uint256 _actor) external view returns (string memory _name, string memory _firstName, string memory _lastName);

    function claim(string memory _firstName, string memory _lastName, uint256 _actor) external returns (uint256 _nameId);
    function assignName(uint256 _nameId, uint256 _actor) external;
    function withdraw(uint256 _operator, uint256 _actor) external;
}

interface IWorldZones is IWorldNonfungible, IERC721Enumerable, IWorldModule {

    event ZoneClaimed(uint256 indexed actor, uint256 indexed zoneId, string name);
    event ZoneUpdated(uint256 indexed zoneId, string oldName, string newName);
    event ZoneAssigned(uint256 indexed zoneId, uint256 indexed previousActor, uint256 indexed newActor);

    function nextZone() external view returns (uint256);
    function names(uint256 _zoneId) external view returns (string memory);
    function timelines(uint256 _zoneId) external view returns (address);

    function claim(uint256 _operator, string memory _name, address _timelineAddress, uint256 _actor) external returns (uint256 _zoneId);
    function withdraw(uint256 _operator, uint256 _zoneId) external;
}

interface IActorBornPlaces is IWorldModule {
    function bornPlaces(uint256 _actor) external view returns (uint256);
    function bornActor(uint256 _operator, uint256 _actor, uint256 _zoneId) external;
}

interface IActorSocialIdentity is IWorldNonfungible, IERC721Enumerable, IWorldModule {
    event SIDClaimed(uint256 indexed actor, uint256 indexed sid, string name);
    event SIDDestroyed(uint256 indexed actor, uint256 indexed sid, string name);

    function nextSID() external view returns (uint256);
    function names(uint256 _nameid) external view returns (string memory);
    function claim(uint256 _operator, uint256 _nameid, uint256 _actor) external returns (uint256 _sid);
    function burn(uint256 _operator, uint256 _sid) external;
    function sidName(uint256 _sid) external view returns (uint256 _nameid, string memory _name);
    function haveName(uint256 _actor, uint256 _nameid) external view returns (bool);
}

interface IActorRelationship is IWorldModule {
    event RelationUpdated(uint256 indexed actor, uint256 indexed target, uint256 indexed rsid, string rsname);

    function relations(uint256 _rsid) external view returns (string memory);
    function setRelation(uint256 _rsid, string memory _name) external;
    function setRelationProcessor(uint256 _rsid, address _processorAddress) external;
    function relationProcessors(uint256 _id) external view returns(address);

    function setActorRelation(uint256 _operator, uint256 _actor, uint256 _target, uint256 _rsid) external;
    function actorRelations(uint256 _actor, uint256 _target) external view returns (uint256);
    function actorRelationPeople(uint256 _actor, uint256 _rsid) external view returns (uint256[] memory);
}

interface IActorRelationshipProcessor {
    function process(uint256 _actor, uint256 _age) external;
}

struct SItem 
{
    uint256 typeId;
    string typeName;
    uint256 shapeId;
    string shapeName;
    uint256 wear;
}

interface IWorldItems is IWorldNonfungible, IERC721Enumerable, IWorldModule {
    event ItemCreated(uint256 indexed actor, uint256 indexed item, uint256 indexed typeId, string typeName, uint256 wear, uint256 shape, string shapeName);
    event ItemChanged(uint256 indexed actor, uint256 indexed item, uint256 indexed typeId, string typeName, uint256 wear, uint256 shape, string shapeName);
    event ItemDestroyed(uint256 indexed item, uint256 indexed typeId, string typeName);

    function nextItemId() external view returns (uint256);
    function typeNames(uint256 _typeId) external view returns (string memory);
    function itemTypes(uint256 _itemId) external view returns (uint256);
    function itemWears(uint256 _itemId) external view returns (uint256);  //耐久
    function shapeNames(uint256 _shapeId) external view returns (string memory);
    function itemShapes(uint256 _itemId) external view returns (uint256); //品相

    function item(uint256 _itemId) external view returns (SItem memory);

    function mint(uint256 _operator, uint256 _typeId, uint256 _wear, uint256 _shape, uint256 _actor) external returns (uint256);
    function modify(uint256 _operator, uint256 _itemId, uint256 _wear) external;
    function burn(uint256 _operator, uint256 _itemId) external;
    function withdraw(uint256 _operator, uint256 _itemId) external;
}

interface IActorPrelifes is IWorldModule {

    event Reincarnation(uint256 indexed actor, uint256 indexed postLife);

    function preLifes(uint256 _actor) external view returns (uint256);
    function postLifes(uint256 _actor) external view returns (uint256);

    function setPrelife(uint256 _operator, uint256 _actor, uint256 _prelife) external;
}

interface IWorldSeasons is IWorldModule {

    function seasonLabels(uint256 _seasonId) external view returns (string memory);
    function actorBornSeasons(uint256 _actor) external view returns (uint256); // =0 means not born

    function bornActor(uint256 _operator, uint256 _actor, uint256 _seasonId) external;
}

interface IWorldZoneBaseResources is IWorldModule {

    event ZoneAssetGrown(uint256 indexed zone, uint256 gold, uint256 food, uint256 herb, uint256 fabric, uint256 wood);
    event ActorAssetCollected(uint256 indexed actor, uint256 gold, uint256 food, uint256 herb, uint256 fabric, uint256 wood);

    function ACTOR_GUANGONG() external view returns (uint256);

    function growAssets(uint256 _operator, uint256 _zoneId) external;
    function collectAssets(uint256 _operator, uint256 _actor, uint256 _zoneId) external;
}

interface IActorLocations is IWorldModule {

    event ActorLocationChanged(uint256 indexed actor, uint256 indexed oldA, uint256 indexed oldB, uint256 newA, uint256 newB);

    function locationActors(uint256 _A, uint256 _B) external view returns (uint256[] memory);
    function actorLocations(uint256 _actor) external view returns (uint256[] memory); //return 2 items array
    function actorFreeTimes(uint256 _actor) external view returns (uint256);
    function isActorLocked(uint256 _actor) external view returns (bool);
    function isActorUnlocked(uint256 _actor) external view returns (bool);

    function setActorLocation(uint256 _operator, uint256 _actor, uint256 _A, uint256 _B) external;
    function lockActor(uint256 _operator, uint256 _actor, uint256 _freeTime) external;
    function unlockActor(uint256 _operator, uint256 _actor) external;
    function finishActorTravel(uint256 _actor) external;
}

interface IWorldVillages is IWorldModule {
    function isZoneVillage(uint256 _zoneId) external view returns (bool);
    function villageCreators(uint256 _zoneId) external view returns (uint256);

    function createVillage(uint256 _operator, uint256 _actor, uint256 _zoneId) external;
}

//building is an item
interface IWorldBuildings is IWorldModule {

    function typeNames(uint256 _typeId) external view returns (string memory);
    function buildingTypes(uint256 _zoneId) external view returns (uint256);
    function isZoneBuilding(uint256 _zoneId) external view returns (bool);

    function createBuilding(uint256 _operator, uint256 _actor, uint256 _typeId, uint256 _zoneId) external;
}

interface ITrigramsRender is IWorldModule {
}

interface ITrigrams is IWorldModule {
    
    event TrigramsOut(uint256 indexed actor, uint256 indexed trigram);

    function addActorTrigrams(uint256 _operator, uint256 _actor, uint256[] memory _trigramsData) external;
    function actorTrigrams(uint256 _actor) external view returns (int256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library WorldConstants {

    //special actors ID
    uint256 public constant ACTOR_PANGU = 1;

    //actor attributes ID
    uint256 public constant ATTR_BASE = 0;
    uint256 public constant ATTR_AGE = 0; // 年龄
    uint256 public constant ATTR_HLH = 1; // 健康，生命

    //module ID
    uint256 public constant WORLD_MODULE_ACTORS       = 0;  //角色
    uint256 public constant WORLD_MODULE_RANDOM       = 1;  //随机数
    uint256 public constant WORLD_MODULE_NAMES        = 2;  //姓名
    uint256 public constant WORLD_MODULE_COIN         = 3;  //通货
    uint256 public constant WORLD_MODULE_YEMINGS      = 4;  //噎明权限
    uint256 public constant WORLD_MODULE_ZONES        = 5;  //区域
    uint256 public constant WORLD_MODULE_SIDS         = 6;  //身份
    uint256 public constant WORLD_MODULE_ITEMS        = 7;  //物品
    uint256 public constant WORLD_MODULE_PRELIFES     = 8;  //前世
    uint256 public constant WORLD_MODULE_ACTOR_LOCATIONS    = 9;  //角色定位

    uint256 public constant WORLD_MODULE_TRIGRAMS_RENDER    = 10; //角色符文渲染器
    uint256 public constant WORLD_MODULE_TRIGRAMS           = 11; //角色符文数据

    uint256 public constant WORLD_MODULE_SIFUS        = 12; //师傅令牌
    uint256 public constant WORLD_MODULE_ATTRIBUTES   = 13; //角色基本属性
}

// SPDX-License-Identifier: MIT
/// @title The Taiyi ShejiTu

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░█████████░░█████████░░░░░ *
 * ░░░░█████████░░█████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import './interfaces/WorldInterfaces.sol';
import './libs/Base64.sol';
import "./world/attributes/ActorAttributes.sol";
//import "hardhat/console.sol";

contract ShejiTu is IWorldTimeline, ERC165, IERC721Receiver, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* *******
     * Globals
     * *******
     */

    IActors public actors;
    IActorLocations public locations;
    IWorldZones public zones;
    IActorAttributes public attributes;
    IWorldEvents public override events;
    IActorTalents public talents;
    ITrigrams public trigrams;
    IWorldRandom public random;

    string public override name;
    string public override description;
    uint256 public override moduleID;

    uint256 public override operator; //timeline administrator authority, 噎鸣

    uint256 public startZone; //actors in this timeline born in this zone

    //map age to event pool ids
    mapping(uint256 => uint256[]) private _eventIDs; //age to id list
    mapping(uint256 => uint256[]) private _eventProbs; //age to prob list

    EnumerableSet.AddressSet private _attributeModules;

    /* *********
     * Modifiers
     * *********
     */

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isActorApprovedOrOwner(_actor), "not approved or owner of actor");
        _;
    }

    //角色位置和时间线校验
    modifier onlyCurrentTimeline(uint256 _actor) {
        require(locations.isActorUnlocked(_actor), "actor is locked by location");
        uint256[] memory lcs = locations.actorLocations(_actor);
        require(lcs.length == 2, "actor location invalid");
        require(lcs[0] == lcs[1] && lcs[0] > 0, "actor location unstable");
        address zta = zones.timelines(lcs[0]);
        require(zta == address(this), "not in current timeline");
        _;
    }

    /* ****************
     * Public Functions
     * ****************
     */

    /* ****************
     * External Functions
     * ****************
     */

    /**
     * @notice Initialize the ShejiTu and base contracts,
     * populate configuration values and init YeMing.
     * @dev This function can only be called once.
     */
    function initialize(
        string memory _name,
        string memory _desc,
        uint256 _moduleID,
        IActors _actors,
        IActorLocations _locations,
        IWorldZones _zones,
        IActorAttributes _attributes,
        IWorldEvents _evts,
        IActorTalents _talents,
        ITrigrams _trigrams,
        IWorldRandom _random
    ) external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        name = _name;
        description = _desc;
        moduleID = _moduleID;

        actors = _actors;
        locations = _locations;
        zones = _zones;
        attributes = _attributes;
        events = _evts;
        talents = _talents;
        trigrams = _trigrams;
        random = _random;
    }

    function setStartZone(uint256 _zoneId) external 
        onlyOwner
    {
        require(_zoneId > 0, "zoneId invalid");
        startZone = _zoneId;
    }

    function initOperator(uint256 _operator) external 
        onlyOwner
    {
        require(operator == 0, "operator already initialized");
        actors.transferFrom(_msgSender(), address(this), _operator);
        operator = _operator;
    }

    function bornActor(uint256 _actor) external
        onlyApprovedOrOwner(_actor)
    {
        return _bornActor(_actor);
    }

    function grow(uint256 _actor) external override
        onlyApprovedOrOwner(_actor)
        onlyCurrentTimeline(_actor)
    {
        require(operator > 0, "operator not initialized");
        if(attributes.characterPointsInitiated(_actor))
            require(attributes.attributesScores(WorldConstants.ATTR_HLH, _actor) > 0, "actor dead!");

        events.grow(operator, _actor);

        //do year age events
        _process(_actor, events.ages(_actor));
    }

    function registerAttributeModule(address _attributeModule) external 
        onlyOwner
    {
        require(_attributeModule != address(0), "input can not be ZERO address!");
        bool rt = _attributeModules.add(_attributeModule);
        require(rt == true, "module with same address is exist.");
    }

    function changeAttributeModule(address _oldAddress, address _newAddress) external
        onlyOwner
    {
        require(_oldAddress != address(0), "input can not be ZERO address!");
        _attributeModules.remove(_oldAddress);
        if(_newAddress != address(0))
            _attributeModules.add(_newAddress);
    }

    function addAgeEvent(uint256 _age, uint256 _eventId, uint256 _eventProb) external 
        onlyOwner
    {
        require(_eventId > 0, "event id must not zero");
        require(_eventIDs[_age].length == _eventProbs[_age].length, "internal ids not match probs");
        _eventIDs[_age].push(_eventId);
        _eventProbs[_age].push(_eventProb);
    }

    function setAgeEventProb(uint256 _age, uint256 _eventId, uint256 _eventProb) external 
        onlyOwner
    {
        require(_eventId > 0, "event id must not zero");
        require(_eventIDs[_age].length == _eventProbs[_age].length, "internal ids not match probs");
        for(uint256 i=0; i<_eventIDs[_age].length; i++) {
            if(_eventIDs[_age][i] == _eventId) {
                _eventProbs[_age][i] = _eventProb;
                return;
            }
        }
        require(false, "can not find _eventId");
    }

    function activeTrigger(uint256 _eventId, uint256 _actor, uint256[] memory _uintParams, string[] memory _stringParams) external override
        onlyApprovedOrOwner(_actor)
        onlyCurrentTimeline(_actor)
    {
        require(operator > 0, "operator not initialized");
        require(events.eventProcessors(_eventId) != address(0), "can not find event processor.");

        uint256 _age = events.ages(_actor);
        require(events.canOccurred(_actor, _eventId, _age), "event check occurrence failed.");
        uint256 branchEvtId = _processActiveEvent(_actor, _age, _eventId, _uintParams, _stringParams, 0);

        //only support two level branchs
        if(branchEvtId > 0 && events.canOccurred(_actor, branchEvtId, _age)) {
            branchEvtId = _processActiveEvent(_actor, _age, branchEvtId, _uintParams, _stringParams, 1);
            if(branchEvtId > 0 && events.canOccurred(_actor, branchEvtId, _age)) {
                branchEvtId = _processActiveEvent(_actor, _age, branchEvtId, _uintParams, _stringParams, 2);
                if(branchEvtId > 0 && events.canOccurred(_actor, branchEvtId, _age)) {
                    branchEvtId = _processActiveEvent(_actor, _age, branchEvtId, _uintParams, _stringParams, 3);
                    if(branchEvtId > 0 && events.canOccurred(_actor, branchEvtId, _age)) {
                        branchEvtId = _processActiveEvent(_actor, _age, branchEvtId, _uintParams, _stringParams, 4);
                        require(branchEvtId == 0, "only support 4 level branchs");
                    }
                }
            }
        }
    }

    /* **************
     * View Functions
     * **************
     */

    function tokenSVG(uint256 _actor, uint256 _startY, uint256 _lineHeight) external virtual override view returns (string memory, uint256 _endY) {
        if(_isActorInCurrentTimeline(_actor))
            return _tokenURISVGPart(_actor, _startY, _lineHeight);
        else
            return ("", _startY);
    }

    function tokenJSON(uint256 _actor) external virtual override view returns (string memory) {
        if(_isActorInCurrentTimeline(_actor))
            return _tokenURIJSONPart(_actor);
        else
            return "{}";
}

    function onERC721Received(address, address, uint256, bytes calldata) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /* *****************
     * Private Functions
     * *****************
     */

    function _attributeModify(uint256 _attr, int _modifier) internal pure returns (uint256) {
        if(_modifier > 0)
            _attr += uint256(_modifier); 
        else {
            if(_attr < uint256(-_modifier))
                _attr = 0;
            else
                _attr -= uint256(-_modifier); 
        }
        return _attr;
    }

    function _runTalentProcessor(uint256 _actor, uint256 _age, address _processorAddress) private {
        //approve talent processor the authority of timeline
        require(operator > 0, "Operator is not init");
        actors.approve(_processorAddress, operator);
        IActorTalentProcessor(_processorAddress).process(operator, _actor, _age); 
    }

    function _applyAttributeModifiers(uint256 _actor, uint256 _age, int[] memory _attrModifier) private {
        bool attributesModified = false;
        uint256[] memory attrib;
        for(uint256 i=0; i<_attributeModules.length(); i++) {
            IActorAttributes attrs = IActorAttributes(_attributeModules.at(i));
            (attrib, attributesModified) = attrs.applyModified(_actor, _attrModifier);
            if(attributesModified)            
                attrs.setAttributes(operator, _actor, attrib); //this will trigger attribute uptate event
        }

        //check if change age
        for(uint256 m=0; m<_attrModifier.length; m+=2) {
            if(_attrModifier[m] == int(WorldConstants.ATTR_AGE)) {
                events.changeAge(operator, _actor, uint256(_attributeModify(uint256(_age), _attrModifier[m+1])));
                break;
            }
        }
    }

    function _processTalents(uint256 _actor, uint256 _age) internal
        onlyApprovedOrOwner(_actor)
    {
        uint256[] memory tlts = talents.actorTalents(_actor);
        for(uint256 i=0; i<tlts.length; i++) {
            if(talents.canOccurred(_actor, tlts[i], _age)) {
                int[] memory _attrModifier = talents.talentAttributeModifiers(tlts[i]);
                _applyAttributeModifiers(_actor, _age, _attrModifier);

                //process talent if any processor
                address tltProcessorAddress = talents.talentProcessors(tlts[i]);
                if(tltProcessorAddress != address(0))
                    _runTalentProcessor(_actor, _age, tltProcessorAddress);
            }
        }
    }

    function _runEventProcessor(uint256 _actor, uint256 _age, address _processorAddress) private {
        //approve event processor the authority of timeline
        //worldRoute.actors().approve(_processorAddress, operator);
        IWorldEventProcessor evtProcessor = IWorldEventProcessor(_processorAddress);
        actors.setApprovalForAll(_processorAddress, true);
        evtProcessor.process(operator, _actor, _age); 
        actors.setApprovalForAll(_processorAddress, false);

        trigrams.addActorTrigrams(operator, _actor, evtProcessor.trigrams(_actor));
    }

    function _processEvent(uint256 _actor, uint256 _age, uint256 _eventId, uint256 _depth) private returns (uint256 _branchEvtId) {

        events.addActorEvent(operator, _actor, _age, _eventId);

        int[] memory _attrModifier = events.eventAttributeModifiers(_eventId, _actor);
        _applyAttributeModifiers(_actor, _age, _attrModifier);

        //process event if any processor
        address evtProcessorAddress = events.eventProcessors(_eventId);
        if(evtProcessorAddress != address(0))
            _runEventProcessor(_actor, _age, evtProcessorAddress);

        if(_depth == 0)
            emit AgeEvent(_actor, _age, _eventId);
        else
            emit BranchEvent(_actor, _age, _eventId);

        //check branch
        return events.checkBranch(_actor, _eventId, _age);
    }

    function _processEvents(uint256 _actor, uint256 _age) internal 
        onlyApprovedOrOwner(_actor)
    {
        //filter events for occurrence
        uint256[] memory _eventsFiltered = new uint256[](_eventIDs[_age].length);
        uint256 _eventsFilteredNum = 0;
        for(uint256 i=0; i<_eventIDs[_age].length; i++) {
            if(events.canOccurred(_actor, _eventIDs[_age][i], _age)) {
                _eventsFiltered[_eventsFilteredNum] = i;
                _eventsFilteredNum++;
            }
        }

        uint256 pCt = 0;
        for(uint256 i=0; i<_eventsFilteredNum; i++) {
            pCt += _eventProbs[_age][_eventsFiltered[i]];
        }
        uint256 prob = 0;
        if(pCt > 0)
            prob = random.dn(_actor, pCt);
        
        pCt = 0;
        for(uint256 i=0; i<_eventsFilteredNum; i++) {
            pCt += _eventProbs[_age][_eventsFiltered[i]];
            if(pCt >= prob) {
                uint256 _eventId = _eventIDs[_age][_eventsFiltered[i]];
                uint256 branchEvtId = _processEvent(_actor, _age, _eventId, 0);

                //only support 3 level branchs
                if(branchEvtId > 0 && events.canOccurred(_actor, branchEvtId, _age)) {
                    branchEvtId = _processEvent(_actor, _age, branchEvtId, 1);
                    if(branchEvtId > 0 && events.canOccurred(_actor, branchEvtId, _age)) {
                        branchEvtId = _processEvent(_actor, _age, branchEvtId, 2);
                        if(branchEvtId > 0 && events.canOccurred(_actor, branchEvtId, _age)) {
                            branchEvtId = _processEvent(_actor, _age, branchEvtId, 3);
                            if(branchEvtId > 0 && events.canOccurred(_actor, branchEvtId, _age)) {
                                branchEvtId = _processEvent(_actor, _age, branchEvtId, 4);
                                require(branchEvtId == 0, "only support 4 level branchs");
                            }
                        }
                    }
                }

                break;
            }
        }
    }

    function _process(uint256 _actor, uint256 _age) internal
        onlyApprovedOrOwner(_actor)
    {
        require(events.actorBorn(_actor), "actor have not born!");
        //require(_actorEvents[_actor][_age] == 0, "actor already have event!");
        require(_eventIDs[_age].length > 0, "not exist any event in this age!");

        _processTalents(_actor, _age);
        _processEvents(_actor, _age);
    }

    function _runActiveEventProcessor(uint256 _actor, uint256 /*_age*/, address _processorAddress, uint256[] memory _uintParams, string[] memory _stringParams) private {
        //approve event processor the authority of timeline(YeMing)
        //worldRoute.actors().approve(_processorAddress, operator);
        actors.setApprovalForAll(_processorAddress, true);
        IWorldEventProcessor(_processorAddress).activeTrigger(operator, _actor, _uintParams, _stringParams);
        actors.setApprovalForAll(_processorAddress, false);
    }

    function _processActiveEvent(uint256 _actor, uint256 _age, uint256 _eventId, uint256[] memory _uintParams, string[] memory _stringParams, uint256 _depth) private returns (uint256 _branchEvtId)
    {
        events.addActorEvent(operator, _actor, _age, _eventId);

        int[] memory _attrModifier = events.eventAttributeModifiers(_eventId, _actor);
        _applyAttributeModifiers(_actor, _age, _attrModifier);

        //process active event if any processor
        address evtProcessorAddress = events.eventProcessors(_eventId);
        if(evtProcessorAddress != address(0))
            _runActiveEventProcessor(_actor, _age, evtProcessorAddress, _uintParams, _stringParams);

        if(_depth == 0)
            emit ActiveEvent(_actor, _age, _eventId);
        else
            emit BranchEvent(_actor, _age, _eventId);

        //check branch
        return events.checkBranch(_actor, _eventId, _age);
    }

    /* ****************
     * Private Functions
     * ****************
     */

    function _tokenURISVGPart(uint256 _actor, uint256 _startY, uint256 _lineHeight) private view returns (string memory, uint256 endY) {
        string memory parts;
        endY = _startY;
        (parts, endY) = _tokenSVG(_actor, endY + _lineHeight, _lineHeight);

        string memory moduleSVG;
        //talents
        (moduleSVG, endY) = talents.tokenSVG(_actor, endY + _lineHeight, _lineHeight);
        parts = string(abi.encodePacked(parts, moduleSVG));
        //attributes
        for(uint256 i=0; i<_attributeModules.length(); i++) {
            (moduleSVG, endY) = IWorldModule(_attributeModules.at(i)).tokenSVG(_actor, endY + _lineHeight, _lineHeight);
            parts = string(abi.encodePacked(parts, moduleSVG));
        }
        //events
        (moduleSVG, endY) = events.tokenSVG(_actor, endY + _lineHeight, _lineHeight);
        parts = string(abi.encodePacked(parts, moduleSVG));
        return (parts, endY);
    }

    function _tokenURIJSONPart(uint256 _actor) private view returns (string memory) {
        string memory json;
        json = string(abi.encodePacked(json, '{"base": ', _tokenJSON(_actor)));
        //talents
        json = string(abi.encodePacked(json, ', "m_', Strings.toString(talents.moduleID()),'": ', talents.tokenJSON(_actor)));
        //attributes
        for(uint256 i=0; i<_attributeModules.length(); i++) {
            IWorldModule mod = IWorldModule(_attributeModules.at(i));
            json = string(abi.encodePacked(json, ', "m_', Strings.toString(mod.moduleID()),'": ', mod.tokenJSON(_actor)));
        }
        //events
        json = string(abi.encodePacked(json, ', "m_', Strings.toString(events.moduleID()),'": ', events.tokenJSON(_actor)));
        json = string(abi.encodePacked(json, '}'));
        return json;
    }

    /* *****************
     * Internal Functions
     * *****************
     */

    function _tokenSVG(uint256 /*_actor*/, uint256 _startY, uint256 /*_lineHeight*/) internal view returns (string memory, uint256 _endY) {
        _endY = _startY;
        return (string(abi.encodePacked('<text x="10" y="', Strings.toString(_endY), '" class="base">', description,'</text>')), _endY);
    }

    function _tokenJSON(uint256 /*_actor*/) internal view returns (string memory) {
        return string(abi.encodePacked('{"name":  "', name,'"}'));
    }

    function _isActorApprovedOrOwner(uint _actor) internal view returns (bool) {
        return (actors.getApproved(_actor) == msg.sender || actors.ownerOf(_actor) == msg.sender) || actors.isApprovedForAll(actors.ownerOf(_actor), msg.sender);
    }

    function _bornActor(uint256 _actor) internal {
        events.bornActor(operator, _actor);

        require(startZone > 0, "start zone invalid");
        locations.setActorLocation(operator, _actor, startZone, startZone);
    }

    function _isActorInCurrentTimeline(uint256 _actor) internal view returns (bool) {
        uint256[] memory lcs = locations.actorLocations(_actor);        
        if(lcs.length != 2)
            return false;
        if(zones.timelines(lcs[0]) == address(this))
            return true;
        if(zones.timelines(lcs[1]) == address(this))
            return true;

        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../interfaces/WorldInterfaces.sol";
import '../../libs/Base64.sol';
import '../WorldConfigurable.sol';

contract ActorAttributes is IActorAttributes, WorldConfigurable {

    /* *******
     * Globals
     * *******
     */
    
    string[] public override attributeLabels = [
        "\xE5\xB9\xB4\xE9\xBE\x84", //年龄
        "\xE5\x81\xA5\xE5\xBA\xB7" //健康
    ];

    mapping(uint256 => mapping(uint256 => uint256)) public override attributesScores; //attributeId => (actor => score)
    mapping(uint256 => bool) public override characterPointsInitiated;

    /* *********
     * Modifiers
     * *********
     */

    modifier onlyPointsInitiated(uint256 _actor) {
        require(characterPointsInitiated[_actor], "points have not been initiated yet");
        _;
    }

    /* ****************
     * Public Functions
     * ****************
     */

    constructor(WorldContractRoute _route) WorldConfigurable(_route) {}

    /* *****************
     * Private Functions
     * *****************
     */

    function _attributeModify(uint256 _attr, int _modifier) internal pure returns (uint256) {
        if(_modifier > 0)
            _attr += uint256(_modifier); 
        else {
            if(_attr < uint256(-_modifier))
                _attr = 0;
            else
                _attr -= uint256(-_modifier); 
        }
        return _attr;
    }

    /* *****************
     * Internal Functions
     * *****************
     */

    function _tokenSVG(uint256 _actor, uint256 _startY, uint256 _lineHeight) internal view returns (string memory, uint256 _endY) {
        _endY = _startY;
        if(characterPointsInitiated[_actor]) {
            //基础属性：
            string memory svg0 = string(abi.encodePacked('<text x="10" y="', Strings.toString(_endY), '" class="base">', '\xE5\x9F\xBA\xE7\xA1\x80\xE5\xB1\x9E\xE6\x80\xA7\xEF\xBC\x9A', '</text>'));
            _endY += _lineHeight;
            string memory svg1 = string(abi.encodePacked('<text x="20" y="', Strings.toString(_endY), '" class="base">', attributeLabels[WorldConstants.ATTR_HLH], "=", Strings.toString(attributesScores[WorldConstants.ATTR_HLH][_actor]), '</text>'));
            return (string(abi.encodePacked(svg0, svg1)), _endY);
        }
        else
            //基础属性未初始化。
            return (string(abi.encodePacked('<text x="10" y="', Strings.toString(_endY), '" class="base">', '\xE5\x9F\xBA\xE7\xA1\x80\xE5\xB1\x9E\xE6\x80\xA7\xE6\x9C\xAA\xE5\x88\x9D\xE5\xA7\x8B\xE5\x8C\x96\xE3\x80\x82', '</text>')), _endY);
    }

    function _tokenJSON(uint256 _actor) internal view returns (string memory) {
        string memory json = '';
        json = string(abi.encodePacked('{"HLH": ', Strings.toString(attributesScores[WorldConstants.ATTR_HLH][_actor]), '}'));
        return json;
    }

    /* ****************
     * External Functions
     * ****************
     */

    function moduleID() external override pure returns (uint256) { return WorldConstants.WORLD_MODULE_ATTRIBUTES; }

    function pointActor(uint256 _operator, uint256 _actor) external override
        onlyYeMing(_operator)
    {        
        require(!characterPointsInitiated[_actor], "already init points");

        attributesScores[WorldConstants.ATTR_HLH][_actor] = 100;
        characterPointsInitiated[_actor] = true;

        uint256[] memory atts = new uint256[](2);
        atts[0] = WorldConstants.ATTR_HLH;
        atts[1] = attributesScores[WorldConstants.ATTR_HLH][_actor];
        emit Created(msg.sender, _actor, atts);
    }

    function setAttributes(uint256 _operator, uint256 _actor, uint256[] memory _attributes) external override
        onlyYeMing(_operator)
        onlyPointsInitiated(_actor)
    {
        require(_attributes.length % 2 == 0, "attributes is invalid.");        

        bool updated = false;
        for(uint256 i=0; i<_attributes.length; i+=2) {
            if(_attributes[i] == WorldConstants.ATTR_HLH) {
                attributesScores[WorldConstants.ATTR_HLH][_actor] = _attributes[i+1];
                updated = true;
                break;
            }
        }

        if(updated) {
            uint256[] memory atts = new uint256[](2);
            atts[0] = WorldConstants.ATTR_HLH;
            atts[1] = attributesScores[WorldConstants.ATTR_HLH][_actor];
            emit Updated(msg.sender, _actor, atts);
        }
    }

    /* **************
     * View Functions
     * **************
     */

    function applyModified(uint256 _actor, int[] memory _modifiers) external view override returns (uint256[] memory, bool) {
        require(_modifiers.length % 2 == 0, "modifiers is invalid.");        

        bool attributesModified = false;
        uint256 hlh = attributesScores[WorldConstants.ATTR_HLH][_actor];
        for(uint256 i=0; i<_modifiers.length; i+=2) {
            if(_modifiers[i] == int(WorldConstants.ATTR_HLH)) {
                hlh = _attributeModify(hlh, _modifiers[i+1]);
                attributesModified = true;
            }
        }

        uint256[] memory atts = new uint256[](2);
        atts[0] = WorldConstants.ATTR_HLH;
        atts[1] = hlh;
        return (atts, attributesModified);
    }

    function tokenSVG(uint256 _actor, uint256 _startY, uint256 _lineHeight) external override view returns (string memory, uint256 _endY) {
        return _tokenSVG(_actor, _startY, _lineHeight);
    }

    function tokenJSON(uint256 _actor) external override view returns (string memory) {
        return _tokenJSON(_actor);
    }

    function tokenURI(uint256 _actor) public view returns (string memory) {
        string[7] memory parts;
        //start svg
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        uint256 endY = 0;
        (parts[1], endY) = _tokenSVG(_actor, endY + 20, 20);
        //end svg
        parts[2] = '</svg>';
        string memory svg = string(abi.encodePacked(parts[0], parts[1], parts[2]));

        //start json
        parts[0] = string(abi.encodePacked('{"name": "Actor #', Strings.toString(_actor), ' attributes"'));
        parts[1] = ', "description": "This is not a game."';
        parts[2] = string(abi.encodePacked(', "data": ', _tokenJSON(_actor)));
        //end json with svg
        parts[3] = string(abi.encodePacked(', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]))));

        //final output
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./WorldContractRoute.sol";

contract WorldConfigurable
{
    WorldContractRoute internal worldRoute;

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isActorApprovedOrOwner(_actor), "not approved or owner of actor");
        _;
    }

    modifier onlyPanGu() {
        require(_isActorApprovedOrOwner(WorldConstants.ACTOR_PANGU), "only PanGu");
        _;
    }

    modifier onlyYeMing(uint256 _actor) {
        require(IWorldYemings(worldRoute.modules(WorldConstants.WORLD_MODULE_YEMINGS)).isYeMing(_actor), "only YeMing");
        require(_isActorApprovedOrOwner(_actor), "not YeMing's operator");
        _;
    }

    constructor(WorldContractRoute _route) {
        worldRoute = _route;
    }

    function _isActorApprovedOrOwner(uint _actor) internal view returns (bool) {
        IActors actors = worldRoute.actors();
        return (actors.getApproved(_actor) == msg.sender || actors.ownerOf(_actor) == msg.sender) || actors.isApprovedForAll(actors.ownerOf(_actor), msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interfaces/WorldInterfaces.sol";
import "../libs/WorldConstants.sol";
import "../base/Ownable.sol";

contract WorldContractRoute is Ownable
{ 
    uint256 public constant ACTOR_PANGU = 1;
    
    mapping(uint256 => address) public modules;
    address                     public actorsAddress;
    IActors                     public actors;
 
    /* *********
     * Modifiers
     * *********
     */

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "cannot set zero address");
        _;
    }

    modifier onlyPanGu() {
        require(_isActorApprovedOrOwner(ACTOR_PANGU), "only PanGu");
        _;
    }

    /* ****************
     * Internal Functions
     * ****************
     */

    function _isActorApprovedOrOwner(uint256 _actor) internal view returns (bool) {
        return (actors.getApproved(_actor) == msg.sender || actors.ownerOf(_actor) == msg.sender) || actors.isApprovedForAll(actors.ownerOf(_actor), msg.sender);
    }

    /* ****************
     * External Functions
     * ****************
     */

    function registerActors(address _address) external 
        onlyOwner
        onlyValidAddress(_address)
    {
        require(actorsAddress == address(0), "Actors address already registered.");
        actorsAddress = _address;
        actors = IActors(_address);
        modules[WorldConstants.WORLD_MODULE_ACTORS] = _address;
    }

    function registerModule(uint256 id, address _address) external 
        onlyPanGu
        onlyValidAddress(_address)
    {
        //require(modules[id] == address(0), "module address already registered.");
        require(IWorldModule(_address).moduleID() == id, "module id is not match.");
        modules[id] = _address;
    }
}