// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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

// Abstract contract that implements access check functions
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/admin/IEntity.sol";
import "../../interfaces/access/IDAOAuthority.sol";

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract DAOAccessControlled is Context {
    
    /* ========== EVENTS ========== */

    event AuthorityUpdated(address indexed authority);

    /* ========== STATE VARIABLES ========== */

    IDAOAuthority public authority;    
    uint256[5] __gap; // storage gap

    /* ========== Initializer ========== */

    function _setAuthority(address _authority) internal {        
        authority = IDAOAuthority(_authority);
        emit AuthorityUpdated(_authority);        
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAuthority() {
        require(address(authority) == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyGovernor() {
        require(authority.getAuthorities().governor == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyPolicy() {
        require(authority.getAuthorities().policy == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyAdmin() {
        require(authority.getAuthorities().admin == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyEntityAdmin(address _entity) {
        require(
            IEntity(_entity).getEntityAdminDetails(_msgSender()).isActive,
            "UNAUTHORIZED"
        );
        _;
    }

    modifier onlyBartender(address _entity) {
        require(
            IEntity(_entity).getBartenderDetails(_msgSender()).isActive,
            "UNAUTHORIZED"
        );
        _;
    }

    modifier onlyDispatcher() {
        require(authority.getAuthorities().dispatcher == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyCollectionManager() {
        require(authority.getAuthorities().collectionManager == _msgSender(), "UNAUTHORIZED");
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(address _newAuthority) external onlyGovernor {
       _setAuthority(_newAuthority);
    }

    /* ========= ERC2771 ============ */
    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return address(authority) != address(0) && forwarder == authority.getAuthorities().forwarder;
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    modifier onlyForwarder() {
        // this modifier must check msg.sender directly (not through _msgSender()!)
        require(isTrustedForwarder(msg.sender), "UNAUTHORIZED");
        _;
    }
}

/**************************************************************************************************************
// This contract consolidates all business logic for Collections and performs book-keeping
// and maintanence for collections and collectibles belonging to it
**************************************************************************************************************/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../access/DAOAccessControlled.sol";

import "../../interfaces/misc/IDispatcher.sol";
import "../../interfaces/misc/ICollectionManager.sol";
import "../../interfaces/misc/ICollectionHelper.sol";
import "../../interfaces/collections/ILoot8Collection.sol";
import "../../interfaces/tokens/ITokenPriceCalculator.sol";
import "../../interfaces/collections/ILoot8UniformCollection.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract CollectionManager is ICollectionManager, Initializable, DAOAccessControlled {
    // Indicates if a collection is active in the Loot8 eco-system
    mapping(address => bool) public collectionIsActive;

    // List of collectible Ids minted for a collection
    mapping(address => uint256[]) public collectionCollectibleIds;

    // Mapping Collection Address => Collection Data
    // Maintains collection data holding information for
    // a given collection of collectibles at a given address
    mapping(address => CollectionData) public collectionData;

    // Mapping Collection Address => Collection Additional Data
    // Maintains collection additional data holding information for
    // a given collection of collectibles at a given address
    mapping(address => CollectionDataAdditional) public collectionDataAdditional;

    // Mapping Collection Address => Area
    // Area for which a given collection is valid
    mapping(address => Area) public area;

    // Mapping Collection Address => Collection Type
    // Type of Collection(Passport, Offer, Event, Digital Collection)
    mapping(address => CollectionType) public collectionType;

    // Mapping Collection Address => Collectible ID => Collectible Attributes
    // A mapping that maps collectible ids to its details for a given collection
    mapping(address => mapping(uint256 => CollectibleDetails)) public collectibleDetails;

    // Collections for a given Entity
    // Entity address => Collections list
    mapping(address => address[]) public entityCollections;

    // Used to check for existence of a collection in LOOT8 system
    // Excludes 3rd party collections
    mapping(address => bool) public collectionExists;

    address[] public allCollections;

    // Lists of all collections by types
    address[] public passports;
    address[] public events;
    address[] public offers;
    address[] public collections;

    uint16 INVALID;
    uint16 SUSPENDED;
    uint16 EXIST;
    uint16 NOT_EXIST;
    uint16 RETIRED;
    uint16 INACTIVE;

    mapping(uint16 => string) private errorMessages;

    mapping(address => uint256) public collectionChainId;

    function initialize(
        address _authority
    ) public initializer {
        DAOAccessControlled._setAuthority(_authority);

        INVALID = 1;
        SUSPENDED = 2;
        EXIST = 3;
        NOT_EXIST = 4;
        RETIRED = 5;
        INACTIVE = 6;
   
        errorMessages[INVALID] = "INVALID COLLECTIBLE";
        errorMessages[SUSPENDED] = "COLLECTIBLE SUSPENDED";
        errorMessages[EXIST] = "COLLECTION EXISTS";
        errorMessages[NOT_EXIST] = "COLLECTION DOES NOT EXIST";
        errorMessages[RETIRED] = "COLLECTION RETIRED";
        errorMessages[INACTIVE] = "COLLECTION INACTIVE";
    }

    function addCollection(
        address _collection,
        uint256 _chainId,
        CollectionType _collectionType,
        CollectionData calldata _collectionData,
        CollectionDataAdditional calldata _collectionDataAdditional,
        Area calldata _area
    ) external onlyEntityAdmin(_collectionData.entity) {

        require(_chainId != 0, "CHAIN ID CANNOT BE ZERO");

        if(_chainId == block.chainid) {
            require(
                ERC165Checker.supportsInterface(_collection, 0x80ac58cd) &&
                ERC165Checker.supportsInterface(_collection, 0x5b5e139f) &&
                (
                    ERC165Checker.supportsInterface(_collection, 0x7a4aa290) || 
                    ERC165Checker.supportsInterface(_collection, 0x6be058c4)
                ),
                "COLLECTION MISSING REQUIRED INTERFACES"
            );
        }

        require(_collectionType != CollectionType.ANY, errorMessages[INVALID]);
        require(!collectionExists[_collection], errorMessages[EXIST]);
    
        _addCollectionToLists(_collection, _collectionData.entity, _collectionType);

        // Set collection type
        collectionType[_collection] = _collectionType;

        // Set the data for the collection
        collectionData[_collection] = _collectionData;

        // Additional data for the collection
        collectionDataAdditional[_collection] = _collectionDataAdditional;

        // Set the area where collection is valid
        area[_collection] = _area;

        // Set collection as active
        collectionIsActive[_collection] = true;

        if (_collectionType ==  CollectionType.OFFER || _collectionType == CollectionType.EVENT) {
            IDispatcher dispatcher = IDispatcher(authority.getAuthorities().dispatcher);
            dispatcher.addOfferWithContext(_collection, _collectionData.maxPurchase, _collectionData.end);
        }

        collectionExists[_collection] = true;

        collectionChainId[_collection] = _chainId;

        if(
            _collectionType == CollectionType.PASSPORT && 
            _collectionDataAdditional.mintModel == MintModel.SUBSCRIPTION
        ) {
            // Set marketplaceOps for subscription passports by default
            ICollectionHelper(authority.collectionHelper()).setAllowMarkeplaceOps(_collection, true);
        }

        emit CollectionAdded(_collection, _collectionType);
    }

    function removeCollection(address _collection) external onlyEntityAdmin(getCollectionData(_collection).entity) {      

        require(collectionExists[_collection], errorMessages[NOT_EXIST]);

        _removeCollectionFromLists(_collection, collectionData[_collection].entity, collectionType[_collection]);

        // Remove the data for the collection
        delete collectionData[_collection];

        // Remove the area where collection is valid
        delete area[_collection];

        // Remove collection as active
        delete collectionIsActive[_collection];

        // Remove chainId mapping
        delete collectionChainId[_collection];

        CollectionType _collectionType = collectionType[_collection];
        if (_collectionType ==  CollectionType.OFFER || _collectionType == CollectionType.EVENT) {
            IDispatcher dispatcher = IDispatcher(authority.getAuthorities().dispatcher);
            dispatcher.removeOfferWithContext(_collection);
        }

        collectionExists[_collection] = false;

        // Remove collection type
        delete collectionType[_collection];
    }

    function updateCollection(
        address _collection,
        CollectionData calldata _collectionData,
        CollectionDataAdditional calldata _collectionDataAdditional,
        Area calldata _area
    ) external onlyEntityAdmin(getCollectionData(_collection).entity) {

        require(collectionExists[_collection], errorMessages[NOT_EXIST]);

        collectionData[_collection] = _collectionData;
        collectionDataAdditional[_collection] = _collectionDataAdditional;
        area[_collection] = _area;

        emit CollectionDataUpdated(_collection);
    }

    function updateExistingCollectionChainIds() external onlyGovernor {
        for(uint256 i = 0; i < allCollections.length; i++) {
            if(collectionChainId[allCollections[i]] == 0) {
                collectionChainId[allCollections[i]] = block.chainid;
            }
        }
    }

    function _addCollectionToLists(address _collection, address _entity, CollectionType _collectionType) internal {
        allCollections.push(_collection);

        entityCollections[_entity].push(_collection);

        if(_collectionType == CollectionType.PASSPORT) {
            passports.push(_collection);
        } else if(_collectionType == CollectionType.OFFER) {
            offers.push(_collection);
        } else if(_collectionType == CollectionType.EVENT) {
            events.push(_collection);
        } else if(_collectionType == CollectionType.COLLECTION) {
            collections.push(_collection);
        }
    }

    function _removeCollectionFromLists(address _collection, address _entity, CollectionType _collectionType) internal {
        for (uint256 i = 0; i < allCollections.length; i++) {
            if (allCollections[i] == _collection) {
                if (i < allCollections.length) {
                    allCollections[i] = allCollections[allCollections.length - 1];
                }
                allCollections.pop();
            }
        }

        address[] storage _collections = entityCollections[_entity];

        for(uint256 i = 0; i < _collections.length; i++) {
            if(_collections[i] == _collection) {
                if(i < _collections.length) {
                    _collections[i] = _collections[_collections.length - 1];
                }
                _collections.pop();
            }
        }

        address[] storage list = passports;

        if(_collectionType == CollectionType.OFFER) {
            list = offers;
        } else if(_collectionType == CollectionType.EVENT) {
            list = events;
        } else if(_collectionType == CollectionType.COLLECTION) {
            list = collections;
        }

        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == _collection) {
                if (i < list.length) {
                    list[i] = list[list.length - 1];
                }
                list.pop();
            }
        }

    }

    function passedPreMintingChecks(address _patron, address _collection) public view returns(bool) {
        
        if(
            !collectionExists[_collection] || 
            !collectionIsActive[_collection] ||
            (collectionDataAdditional[_collection].mintModel != MintModel.REGULAR) ||
            (collectionData[_collection].start > 0 && collectionData[_collection].end > 0 && 
            (collectionData[_collection].start > block.timestamp || collectionData[_collection].end <= block.timestamp))
        ) {
            return false;
        }
        
        if(collectionChainId[_collection] == block.chainid) {
            if(
                (collectionData[_collection].maxMint > 0 && collectionCollectibleIds[_collection].length >= collectionData[_collection].maxMint) ||
                ((collectionType[_collection] == CollectionType.PASSPORT || collectionType[_collection] == CollectionType.COLLECTION) && collectionDataAdditional[_collection].maxBalance == 0 && IERC721(_collection).balanceOf(_patron) >= 1) ||
                (collectionDataAdditional[_collection].maxBalance > 0 && IERC721(_collection).balanceOf(_patron) >= collectionDataAdditional[_collection].maxBalance) ||
                (collectionType[_collection] == CollectionType.COLLECTION && collectionData[_collection].passport != address(0) && IERC721(collectionData[_collection].passport).balanceOf(_patron) == 0)
            ) {
                return false;
            }
        }

        return true;

    }

    function mintCollectible(
        address _patron,
        address _collection
    ) external returns(uint256 _collectibleId) {

        require(
            _msgSender() == authority.getAuthorities().dispatcher ||
            (isTrustedForwarder(msg.sender) && 
            (collectionType[_collection] == CollectionType.PASSPORT || 
            collectionType[_collection] == CollectionType.COLLECTION)), 
            "UNAUTHORIZED"
        );

        // This function cannot mint tokens for collections on other chains
        if(collectionChainId[_collection] != block.chainid) {
            return 0;
        }

        if(!passedPreMintingChecks(_patron, _collection)) {
            return 0;
        }

        // require(collectionCollectibleIds[_collection].length < collectionData[_collection].maxMint, "OUT OF STOCK");

        // if(collectionType[_collection] == CollectionType.COLLECTION) {
        //     address _passport = collectionData[_collection].passport;
        //     uint256 _patronPassportId = getAllTokensForPatron(_passport, _patron)[0];
            
        //     require(collectibleDetails[_passport][_patronPassportId].visits >= collectionData[_collection].minVisits, "Not enough visits");
        //     require(collectibleDetails[_passport][_patronPassportId].rewardBalance >= collectionData[_collection].minRewardBalance, "Not enough reward balance");
        //     require(collectibleDetails[_passport][_patronPassportId].friendVisits >= collectionData[_collection].minFriendVisits, "Not enough friend visits");
        // }   

        _collectibleId = ILoot8Collection(_collection).getNextTokenId();
       
        ILoot8Collection(_collection).mint(_patron, _collectibleId);

        collectionCollectibleIds[_collection].push(_collectibleId);

        // Add details about the collectible to the collectibles object and add it to the mapping
        uint256[20] memory __gap;
        collectibleDetails[_collection][_collectibleId] = CollectibleDetails({
            id: _collectibleId,
            mintTime: block.timestamp, 
            isActive: true,
            rewardBalance: 0,
            visits: 0,
            friendVisits: 0,
            redeemed: false,
            __gap: __gap
        });

        emit CollectibleMinted(_collection, _collectibleId, collectionType[_collection]);  
    }

    /**
     * @notice Activation/Deactivation of a Collections Collectible token
     * @param _collection address Collection address to which the Collectible belongs
     * @param _collectibleId uint256 Collectible ID to be toggled
    */
    function toggle(address _collection, uint256 _collectibleId)
        external onlyBartender(collectionData[_collection].entity) {
        
        require(collectionExists[_collection], errorMessages[NOT_EXIST]);

        // Check if collection is active
        require(collectionIsActive[_collection], errorMessages[RETIRED]);

        CollectibleDetails storage _details = collectibleDetails[_collection][_collectibleId];

        // Check if Collectible with the given Id exists
        require(_details.id != 0, errorMessages[INVALID]);

        // Toggle the collectible
        _details.isActive = !_details.isActive;

        // Emit an event for Collectible toggling with status
        emit CollectibleToggled(_collection, _collectibleId, _details.isActive);
    }

    /**
     * @notice Transfers reward tokens to the patrons wallet when they purchase drinks/products.
     * @notice Internally also maintains and updates a tally around number of rewards held by a patron.
     * @notice Should be called when the bartender serves an order and receives payment for the drink.
     * @param _collection address Collection to which the patrons Collectible belongs
     * @param _patron address Patrons wallet address
     * @param _amount uint256 Amount of rewards to be credited
    */
    function creditRewards(
        address _collection,
        address _patron,
        uint256 _amount
    ) external onlyDispatcher {

        require(collectionExists[_collection], errorMessages[NOT_EXIST]);

        // Check if collectible is active
        require(collectionIsActive[_collection], errorMessages[RETIRED]);

        // Get the Collectible ID for the patron
        uint256 collectibleId = getAllTokensForPatron(_collection, _patron)[0];

        // Check if the patrons collectible is active
        require(collectibleDetails[_collection][collectibleId].isActive, errorMessages[SUSPENDED]);

        // Update a tally for reward balance in a collectible
        collectibleDetails[_collection][collectibleId].rewardBalance = 
                collectibleDetails[_collection][collectibleId].rewardBalance + int256(_amount);

        // Emit an event for reward credits to collectible with relevant details
        emit CreditRewards(_collection, collectibleId, _patron, _amount);
    }

    /**
     * @notice Burns reward tokens from patrons wallet when they redeem rewards for free drinks/products.
     * @notice Internally also maintains and updates a tally around number of rewards held by a patron.
     * @notice Should be called when the bartender serves an order in return for reward tokens as payment.
     * @param _collection address Collection to which the patrons Collectible belongs
     * @param _patron address Patrons wallet address
     * @param _amount uint256 Expiry timestamp for the Collectible
    */
    function debitRewards(
        address _collection,
        address _patron, 
        uint256 _amount
    ) external onlyDispatcher {

        require(collectionExists[_collection], errorMessages[NOT_EXIST]);

        // Check if collection is active
        require(collectionIsActive[_collection], errorMessages[RETIRED]);
        
        // Get the Collectible ID for the patron
        uint256 collectibleId = getAllTokensForPatron(_collection, _patron)[0];

        // Check if the patrons collectible is active
        require(collectibleDetails[_collection][collectibleId].isActive, errorMessages[SUSPENDED]);

        // Update a tally for reward balance in a collectible
        collectibleDetails[_collection][collectibleId].rewardBalance = 
                    collectibleDetails[_collection][collectibleId].rewardBalance - int256(_amount);
        
        // Emit an event for reward debits from a collectible with relevant details
        emit BurnRewards(_collection, collectibleId, _patron, _amount);
    }

    // /*
    //  * @notice Credits visits/friend visits to patrons passport
    //  * @notice Used as a metric to determine eligibility for special Collectible airdrops
    //  * @notice Should be called by the mobile app whenever the patron or his friend visits the club
    //  * @notice Only used for passport Collectible types
    //  * @param _collection address Collection to which the Collectible belongs
    //  * @param _collectibleId uint256 collectible id to which the visit needs to be added
    //  * @param _friend bool false=patron visit, true=friend visit
    // */
    // function addVisit(
    //     address _collection, 
    //     uint256 _collectibleId, 
    //     bool _friend
    // ) external onlyForwarder {

    //     // Check if collection is active
    //     require(collectionIsActive[_collection], errorMessages[RETIRED]);

    //     // Check if collectible with the given Id exists
    //     require(collectibleDetails[_collection][_collectibleId].id != 0, errorMessages[INVALID]);

    //     // Check if patron collectible is active or disabled
    //     require(collectibleDetails[_collection][_collectibleId].isActive, errorMessages[SUSPENDED]);

    //     // Credit visit to the collectible
    //     if(!_friend) {

    //         collectibleDetails[_collection][_collectibleId].visits = collectibleDetails[_collection][_collectibleId].visits + 1;
            
    //         // Emit an event marking a collectible holders visit to the club
    //         emit Visited(_collection, _collectibleId);

    //     } else {

    //         // Credit a friend visit to the collectible
    //         collectibleDetails[_collection][_collectibleId].friendVisits = collectibleDetails[_collection][_collectibleId].friendVisits + 1;

    //         // Emit an event marking a collectible holders friends visit to the club
    //         emit FriendVisited(_collection, _collectibleId);

    //     }

    // }

    /**
     * @notice Toggles mintWithLinked flag to true or false
     * @notice Can only be toggled by entity admin
     * @param _collection address
    */
    function toggleMintWithLinked(address _collection) external onlyEntityAdmin(collectionData[_collection].entity) {
        require(collectionExists[_collection], errorMessages[NOT_EXIST]);
        collectionData[_collection].mintWithLinked = !collectionData[_collection].mintWithLinked;
        emit  CollectionMintWithLinkedToggled(_collection, collectionData[_collection].mintWithLinked);
    }

    function retireCollection(address _collection) external onlyEntityAdmin(collectionData[_collection].entity) {
        require(collectionExists[_collection], errorMessages[NOT_EXIST]);
        require(collectionIsActive[_collection], errorMessages[RETIRED]);

        collectionIsActive[_collection] = false;
        emit CollectionRetired(_collection, collectionType[_collection]);
    }

    function setCollectibleRedemption(address _collection, uint256 _collectibleId) external onlyDispatcher {
        require(collectionExists[_collection], errorMessages[NOT_EXIST]);
        collectibleDetails[_collection][_collectibleId].redeemed = true;
    }

    function isCollection(address _collection) public view returns(bool) {
        return collectionExists[_collection];
    }

    function isRetired(address _collection, uint256 _collectibleId) external view returns(bool) {
        require(collectionExists[_collection], errorMessages[NOT_EXIST]);
        return !collectibleDetails[_collection][_collectibleId].isActive;
    }
    
    function checkCollectionActive(address _collection) public view returns(bool) {
        require(collectionExists[_collection], errorMessages[NOT_EXIST]);
        return collectionIsActive[_collection];
    }

    /*
     * @notice Returns collectible details for a given collectibleID belonging to a collection
     * @param _collection address The collection to which the collectible belongs
     * @param _collectibleId uint256 Collectible ID for which details need to be fetched
    */
    function getCollectibleDetails(address _collection, uint256 _collectibleId) external view returns(CollectibleDetails memory) {
        require(collectionExists[_collection], errorMessages[NOT_EXIST]);
        return collectibleDetails[_collection][_collectibleId];
    }

    function getCollectionType(address _collection) external view returns(CollectionType) {
        require(collectionExists[_collection], errorMessages[NOT_EXIST]);
        return collectionType[_collection];
    }

    function getCollectionData(address _collection) public view returns(CollectionData memory) {
        require(collectionExists[_collection], errorMessages[NOT_EXIST]);
        return collectionData[_collection];
    }

    function getLocationDetails(address _collection) external view returns(string[] memory, uint256) {
        require(collectionExists[_collection], errorMessages[NOT_EXIST]);
        return (area[_collection].points, area[_collection].radius);
    }

    function getCollectionInfo(address _collection) external view 
        returns (string memory _name,
        string memory _symbol,
        string memory _dataURI,
        CollectionData memory _data,
        CollectionDataAdditional memory _additionCollectionData,
        bool _isActive,
        string[] memory _areaPoints,
        uint256 _areaRadius,
        address[] memory _linkedCollections,
        CollectionType _collectionType) {
        require(collectionExists[_collection], errorMessages[NOT_EXIST]);
        _name = (collectionChainId[_collection] == block.chainid) ? IERC721Metadata(_collection).name() : '';
        _symbol = (collectionChainId[_collection] == block.chainid) ? IERC721Metadata(_collection).symbol() : '';
        _dataURI = (collectionChainId[_collection] == block.chainid) ? 
                    (ERC165Checker.supportsInterface(_collection, 0x96f8caa1) ? ILoot8UniformCollection(_collection).contractURI() : '') : '';
        _data = getCollectionData(_collection);
        _additionCollectionData = collectionDataAdditional[_collection];
        _areaPoints = area[_collection].points;
        _areaRadius = area[_collection].radius;
        _isActive = checkCollectionActive(_collection);
        _linkedCollections = ICollectionHelper(authority.collectionHelper()).getAllLinkedCollections(_collection);
        _collectionType = collectionType[_collection];
    }

    function _getListForCollectionType(CollectionType _collectionType) internal view returns(address[] memory) {
        
        if(_collectionType == CollectionType.PASSPORT) {
            return passports;
        } else if(_collectionType == CollectionType.OFFER) {
            return offers;
        } else if(_collectionType == CollectionType.EVENT) {
            return events;
        } else if(_collectionType == CollectionType.COLLECTION) {
            return collections;
        } else {
            return allCollections;
        }

    }

    function getCollectionsForEntity(address _entity, CollectionType _collectionType, bool _onlyActive) public view returns(address[] memory _entityCollections) {

        address[] memory _collections = entityCollections[_entity];

        uint256 count;
        for (uint256 i = 0; i < _collections.length; i++) {
            if (
                (_collectionType == CollectionType.ANY || collectionType[_collections[i]] == _collectionType) &&
                (!_onlyActive || checkCollectionActive(_collections[i]))
            ) {
                count++;
            }
        }
        
        _entityCollections = new address[](count);
        uint256 _idx;
        for(uint256 i = 0; i < _collections.length; i++) {
            if (
                (_collectionType == CollectionType.ANY || collectionType[_collections[i]] == _collectionType) &&
                (!_onlyActive || checkCollectionActive(_collections[i]))
            ) {
                _entityCollections[_idx] = _collections[i];
                _idx++;
            }
        }

    }

    function getAllCollectionsWithChainId(CollectionType _collectionType, bool _onlyActive) public view 
    returns(IExternalCollectionManager.ContractDetails[] memory _allCollections) {

        address[] memory collectionList = _getListForCollectionType(_collectionType);

        uint256 count;
        for (uint256 i = 0; i < collectionList.length; i++) {
            if (!_onlyActive || checkCollectionActive(collectionList[i])) {
                count++;
            }
        }
        
        _allCollections = new IExternalCollectionManager.ContractDetails[](count);
        uint256 _idx;
        for (uint256 i = 0; i < collectionList.length; i++) {
            if (!_onlyActive || checkCollectionActive(collectionList[i])) {
                _allCollections[_idx].source = collectionList[i];
                _allCollections[_idx].chainId = collectionChainId[collectionList[i]];
                _idx++;
            }
        }
    }

    function getAllCollectionsForPatron(CollectionType _collectionType, address _patron, bool _onlyActive) public view returns (address[] memory _allCollections) {
       
        address[] memory collectionList = _getListForCollectionType(_collectionType);
 
        uint256 count;
        for (uint256 i = 0; i < collectionList.length; i++) {
            if ( 
                (!_onlyActive || checkCollectionActive(collectionList[i])) &&
                collectionChainId[collectionList[i]] == block.chainid &&
                IERC721(collectionList[i]).balanceOf(_patron) > 0
            ) {
                count++;
            }
        }
            
        _allCollections = new address[](count);
        uint256 _idx;
        for (uint256 i = 0; i < collectionList.length; i++) {
            if( 
                (!_onlyActive || checkCollectionActive(collectionList[i])) &&
                (collectionChainId[collectionList[i]] == block.chainid) &&
                IERC721(collectionList[i]).balanceOf(_patron) > 0
            ) {
                _allCollections[_idx] = collectionList[i];
                _idx++;
            }
        }

    }

    function getCollectionChainId(address _collection) external view returns(uint256) {
        return collectionChainId[_collection];
    }

    function getAllTokensForPatron(address _collection, address _patron) public view returns(uint256[] memory _patronTokenIds) {
        require(isCollection(_collection), errorMessages[NOT_EXIST]);
        require(collectionChainId[_collection] == block.chainid, "COLLECTION ON FOREIGN CHAIN");
        IERC721 collection = IERC721(_collection);

        uint256 tokenId = 1;
        uint256 patronBalance = collection.balanceOf(_patron);
        uint256 i = 0;

        _patronTokenIds = new uint256[](patronBalance);

        bool isNewVersion = (
            ERC165Checker.supportsInterface(_collection, 0x7a4aa290) || 
            ERC165Checker.supportsInterface(_collection, 0x6be058c4)
        );

        while(i < patronBalance) {
            if(
                isNewVersion &&
                ILoot8Collection(_collection).isValidToken(tokenId) && 
                collection.ownerOf(tokenId) == _patron
            ) {
                _patronTokenIds[i] = tokenId;
                i++;
            }

            tokenId++;

        }
    }

    // function getExternalCollectionsForPatron(address _patron) public view returns (address[] memory _collections) {
       
    //     address[] memory passportList = getAllCollectionsForPatron(CollectionType.PASSPORT, _patron, true);

    //     uint256 idx;
        
    //     for (uint256 i = 0; i < passportList.length; i++) {
    //         ContractDetails[] memory _wl = getWhitelistedCollectionsForPassport(passportList[i]);

    //         for (uint256 j = 0; j < _wl.length; j++) {
    //             if(IERC721(_wl[j].source).balanceOf(_patron) > 0) {
    //                 _collections[idx] = _wl[j].source;
    //                 idx++;
    //             }
    //         }
    //     }
    // }

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IDAOAuthority {

    /*********** EVENTS *************/
    event ChangedGovernor(address _newGovernor);
    event ChangedPolicy(address _newPolicy);
    event ChangedAdmin(address _newAdmin);
    event ChangedForwarder(address _newForwarder);
    event ChangedDispatcher(address _newDispatcher);
    event ChangedCollectionHelper(address _newCollectionHelper);
    event ChangedCollectionManager(address _newCollectionManager);
    event ChangedTokenPriceCalculator(address _newTokenPriceCalculator);

    struct Authorities {
        address governor;
        address policy;
        address admin;
        address forwarder;
        address dispatcher;
        address collectionManager;
        address tokenPriceCalculator;
    }

    function collectionHelper() external view returns(address);
    function getAuthorities() external view returns(Authorities memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/location/ILocationBased.sol";

interface IEntity is ILocationBased {

    /* ========== EVENTS ========== */
    event EntityToggled(address _entity, bool _status);
    event EntityUpdated(address _entity, Area _area, string _dataURI, address _walletAddress);
        
    event EntityDataURIUpdated(string _oldDataURI,  string _newDataURI);    

    event EntityAdminGranted(address _entity, address _entAdmin);
    event BartenderGranted(address _entity, address _bartender);
    event EntityAdminToggled(address _entity, address _entAdmin, bool _status);
    event BartenderToggled(address _entity, address _bartender, bool _status);

    event CollectionWhitelisted(address indexed _entity, address indexed _collection, uint256 indexed _chainId);
    event CollectionDelisted(address indexed _entity, address indexed _collection, uint256 indexed _chainId);

    event UserContractSet(address _newUserContract);
    
    struct Operator {
        uint256 id;
        bool isActive;

        // Storage Gap
        uint256[5] __gap;
    }

    struct BlacklistDetails {
        // Timestamp after which the patron should be removed from blacklist
        uint256 end;

        // Storage Gap
        uint256[5] __gap;
    }

    struct EntityData {

        // Entity wallet address
        address walletAddress;
        
        // Flag to indicate whether entity is active or not
        bool isActive;

        // Data URI where file containing entity details resides
        string dataURI;

        // name of the entity
        string name;

        // Storage Gap
        uint256[20] __gap;

    }

    function toggleEntity() external returns(bool _status);

    function updateEntity(
        Area memory _area,
        string memory _name,
        string memory _dataURI,
        address _walletAddress
    ) external;

     function updateDataURI(
        string memory _dataURI
    ) external;
    

    function addEntityAdmin(address _entAdmin) external;

    function addBartender(address _bartender) external;

    function toggleEntityAdmin(address _entAdmin) external returns(bool _status);

    function toggleBartender(address _bartender) external returns(bool _status);

    function addPatronToBlacklist(address _patron, uint256 _end) external;

    function removePatronFromBlacklist(address _patron) external;

    function getEntityData() external view returns(EntityData memory);

    function getEntityAdminDetails(address _entAdmin) external view returns(Operator memory);

    function getBartenderDetails(address _bartender) external view returns(Operator memory);

    function getAllEntityAdmins(bool _onlyActive) external view returns(address[] memory);

    function getAllBartenders(bool _onlyActive) external view returns(address[] memory);
    
    function getLocationDetails() external view returns(string[] memory, uint256);

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ICollectionData {
    
    enum CollectionType {
        ANY,
        PASSPORT,
        OFFER,
        COLLECTION,
        BADGE,
        EVENT
    }

    enum OfferType {
        NOTANOFFER,
        FEATURED,
        REGULAR 
    }

    enum MintModel {
        REGULAR,
        SUBSCRIPTION
    }

    struct CollectionData {

        // A collectible may optionally be linked to an entity
        // If its not then this will be address(0)
        address entity;

        // Flag that checks if a collectible should be minted when a collectible which it is linked to is minted
        // Eg: Offers/Events that should be airdropped along with passport for them
        // If true for a linked collectible, mintLinked can be called by the
        // dispatcher contract to mint collectibles linked to it
        bool mintWithLinked;

        // Price per collectible in this collection.
        // 6 decimals precision 24494022 = 24.494022 USD
        uint256 price;

        // Max Purchase limit for this collection.
        uint256 maxPurchase;

        // Start time from when the Collection will be on offer to patrons
        // Zero for non-time bound
        uint256 start;

        // End time from when the Collection will no longer be available for purchase
        // Zero for non-time bound
        uint256 end;

        // Flag to indicate the need for check in to place an order
        bool checkInNeeded;

        // Maximum tokens that can be minted for this collection
        // Used for passports
        // Zero for unlimited
        uint256 maxMint;

        // Type of offer represented by the collection(NOTANOFFER for passports and other collections)
        OfferType offerType;

        // Non zero when the collection needs some criteria to be fulfilled on a passport
        address passport;

        // Min reward balance needed to get a collectible of this collection airdropped
        int256 minRewardBalance;

        // Min visits needed to get a collectible this collection airdropped
        uint256 minVisits;

        // Min friend visits needed to get a collectible this collection airdropped
        uint256 minFriendVisits;

        // Storage Gap
        uint256[20] __gap;

    }

    struct CollectionDataAdditional {
        // Max Balance a patron can hold for this collection.
        // Zero for 1
        uint256 maxBalance;

        // Is minted only when a linked collection is minted
        bool mintWithLinkedOnly;

        uint256 isCoupon; //zero = false, nonzero = true.

        MintModel mintModel; // The mint model for the collection. REGULAR, SUBSCRIPTION, etc.

        // Storage Gap
        uint256[17] __gap;
    }

    struct CollectibleDetails {
        uint256 id;
        uint256 mintTime; // timestamp
        bool isActive;
        int256 rewardBalance; // used for passports only
        uint256 visits; // // used for passports only
        uint256 friendVisits; // used for passports only
        // A flag indicating whether the collectible was redeemed
        // This can be useful in scenarios such as cancellation of orders
        // where the the collectible minted to patron is supposed to be burnt/demarcated
        // in some way when the payment is reversed to patron
        bool redeemed;

        // Storage Gap
        uint256[20] __gap;
    }

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/**
 * @title Minimally required collection interface of a LOOT8 compliant contract.
 */
interface ILoot8Collection {

    /**
     * @dev Mints `_collectibleId` and transfers it to `_patron`.
     * @param _patron address representing an owner of minted token
     * @param _collectibleId a tokenId to mint
     *
     * Requirements:
     * - `tokenId` must not exist.
     */
    function mint(address _patron, uint256 _collectibleId) external;

    /**
     * @dev Returns a tokenId available for minting.
     */
    function getNextTokenId() external view returns(uint256 tokenId);

    /**
     * @dev Checks if a given tokenId is a valid token belonging to the collection
     * @param _collectibleId a tokenId to validate
     */
    function isValidToken(uint256 _collectibleId) external view returns(bool);

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ILoot8UniformCollection {

    /**
     * @dev Returns a contract-level metadata URI.
     */
    function contractURI() external view returns (string memory);

    /**
     * @dev Updates the metadata URI for the collection
     * @param _contractURI string new contract URI
     */
    function updateContractURI(string memory _contractURI) external;

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ILocationBased {

    struct Area {
        // Area Co-ordinates.
        // For circular area, points[] length = 1 and radius > 0
        // For arbitrary area, points[] length > 1 and radius = 0
        // For arbitrary areas UI should connect the points with a
        // straight line in the same sequence as specified in the points array
        string[] points; // Each element in this array should be specified in "lat,long" format
        uint256 radius; // Unit: Meters. 2 decimals(5000 = 50 meters)
    }    
    
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ICollectionHelper {
    event ContractURIUpdated(address _collection, string oldContractURI, string _contractURI);
    event CollectionsLinked(address indexed _collectible1, address indexed _collectible2);
    event CollectionsDelinked(address indexed _collectible1, address indexed _collectible2);
    event TradeablitySet(address _collection, bool _privateTradeAllowed, bool _publicTradeAllowed);
    event MarketplaceOpsSet(address _collection, bool _allowMarketplaceOps);

    struct MarketplaceConfig {
        // Is the collection tradeable on a private marketplace
        // Entity Admin may choose to allow or not allow a collection to be traded privately
        bool privateTradeAllowed;

        // Is the collection tradeable on a public marketplace
        // Entity Admin may choose to allow or not allow a collection to be traded publicly
        bool publicTradeAllowed;

        // Is this collection allowed to be traded on the Loot8 marketplace.
        // Governor may choose to allow or not allow a collection to be traded on LOOT8
        bool allowMarketplaceOps;

        uint256[20] __gap;
    }

    function updateContractURI(address _collection, string memory _contractURI) external;
    function calculateRewards(address _collection, uint256 _quantity) external view returns(uint256);
    function linkCollections(address _collection1, address[] calldata _arrayOfCollections) external;
    function delinkCollections(address _collection1, address _collection2) external;
    function areLinkedCollections(address _collection1, address _collection2) external view returns(bool _areLinked);
    function getAllLinkedCollections(address _collection) external view returns (address[] memory);
    function setTradeablity(address _collection, bool _privateTradeAllowed, bool _publicTradeAllowed) external;
    function setAllowMarkeplaceOps(address _collection, bool _allowMarketplaceOps) external;
    function getMarketplaceConfig(address _collection) external view returns(MarketplaceConfig memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/access/IDAOAuthority.sol";
import "../../interfaces/location/ILocationBased.sol";
import "../../interfaces/misc/IExternalCollectionManager.sol";
import "../../interfaces/collections/ICollectionData.sol";


interface ICollectionManager is ICollectionData, ILocationBased {

    event CollectionAdded(address indexed _collection, CollectionType indexed _collectionType);

    event CollectionDataUpdated(address _collection);

    event CollectionRetired(address indexed _collection, CollectionType indexed _collectionType);

    event CollectibleMinted(address indexed _collection, uint256 indexed _collectibleId, CollectionType indexed _collectionType);

    event CollectibleToggled(address indexed _collection, uint256 indexed _collectibleId, bool _status);

    event CreditRewards(address indexed _collection, uint256 indexed _collectibleId, address indexed _patron, uint256 _amount);

    event BurnRewards(address indexed _collection, uint256 indexed _collectibleId, address indexed _patron, uint256 _amount);

    event Visited(address indexed _collection, uint256 indexed _collectibleId);

    event FriendVisited(address indexed _collection, uint256 indexed _collectibleId);

    event CollectionMintWithLinkedToggled(address indexed _collection, bool indexed _mintWithLinked);

    event CollectionWhitelisted(address indexed _passport, address indexed _source, uint256 indexed _chainId);

    event CollectionDelisted(address indexed _passport, address indexed _source, uint256 indexed _chainId);

    function addCollection(
        address _collection,
        uint256 _chainId,
        CollectionType _collectionType,
        CollectionData calldata _collectionData,
        CollectionDataAdditional calldata _collectionDataAdditional,
        Area calldata _area
    ) external;

    function updateCollection(
        address _collection,
        CollectionData calldata _collectionData,
        CollectionDataAdditional calldata _collectionDataAdditional,
        Area calldata _area
    ) external;

    function mintCollectible(
        address _patron,
        address _collection
    ) external returns(uint256 _collectibleId);

    function toggle(address _collection, uint256 _collectibleId) external;

    function creditRewards(
        address _collection,
        address _patron,
        uint256 _amount
    ) external;

    function debitRewards(
        address _collection,
        address _patron, 
        uint256 _amount
    ) external;

    // function addVisit(
    //     address _collection, 
    //     uint256 _collectibleId, 
    //     bool _friend
    // ) external;

    function toggleMintWithLinked(address _collection) external;

    //function whitelistCollection(address _source, uint256 _chainId, address _passport) external;

    //function getWhitelistedCollectionsForPassport(address _passport) external view returns(ContractDetails[] memory _wl);

    //function delistCollection(address _source, uint256 _chainId, address _passport) external;

    function setCollectibleRedemption(address _collection, uint256 _collectibleId) external;

    function isCollection(address _collection) external view returns(bool);
    
    function isRetired(address _collection, uint256 _collectibleId) external view returns(bool);

    function checkCollectionActive(address _collection) external view returns(bool);

    function getCollectibleDetails(address _collection, uint256 _collectibleId) external view returns(CollectibleDetails memory);

    function getCollectionType(address _collection) external view returns(CollectionType);

    function getCollectionData(address _collection) external view returns(CollectionData memory _collectionData);

    function getLocationDetails(address _collection) external view returns(string[] memory, uint256);

    function getCollectionsForEntity(address _entity, CollectionType _collectionType, bool _onlyActive) external view returns(address[] memory _entityCollections);

    function getAllCollectionsWithChainId(CollectionType _collectionType, bool _onlyActive) external view returns(IExternalCollectionManager.ContractDetails[] memory _allCollections);
    
    function getAllCollectionsForPatron(CollectionType _collectionType, address _patron, bool _onlyActive) external view returns(address[] memory _allCollections);

    function getCollectionChainId(address _collection) external view returns(uint256);

    function getCollectionInfo(address _collection) external view 
        returns (string memory _name,
        string memory _symbol,
        string memory _dataURI,
        CollectionData memory _data,
        CollectionDataAdditional memory _additionCollectionData,
        bool _isActive,
        string[] memory _areaPoints,
        uint256 _areaRadius,
        address[] memory _linkedCollections,
        CollectionType _collectionType);

    // function getExternalCollectionsForPatron(address _patron) external view returns (address[] memory _collections);

    function getAllTokensForPatron(address _collection, address _patron) external view returns(uint256[] memory _patronTokenIds);

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/collections/ICollectionData.sol";

interface IDispatcher is ICollectionData {

    event OrderDispatched(address indexed _entity, address indexed _offer, uint256 indexed _reservationId, uint256 _offerId);
    event ReservationAdded(address indexed _entity, address indexed _offer, address indexed _patron, uint256 _newReservationId, uint256 _expiry, bool  _cashPayment);
    event ReservationFulfilled(address _entity, address indexed _offer, address indexed _patron, uint256 indexed _reservationId, uint256 _offerId);
    event ReservationCancelled(address _entity, address indexed _offer, uint256 indexed _reservationId);
    event ReservationsExpirySet(uint256 _newExpiry);
    event TokenMintedForReservation(address indexed _entity, address indexed _offer, uint256 indexed _reservationId, uint256 _offerId);
    event UserContractSet(address _newUserContract);
    event Loot8CollectionFactorySet(address _newLoot8CollectionFactory);

    struct OfferContext {
        uint256 id;
        uint256 expiry;
        uint256 totalPurchases;
        uint256 activeReservationsCount;
        uint256 maxPurchase;
        uint256[] reservations;
        mapping(address => uint256) patronRecentReservation;

        // Storage Gap
        uint256[20] __gap;
    }

    struct Reservation {
        uint256 id;
        address patron;
        uint256 created;
        uint256 expiry;
        address offer;
        uint256 offerId; // Offer Collectible Token Id if Collectible was minted for this reservation
        bool cashPayment; // Flag indicating if the reservation will be paid for in cash or online
        bool cancelled;
        bool fulfilled; // Flag to indicate if the order was fulfilled
        bytes data;
        address passport; // Passport on which the offer was reserved

        // Storage Gap
        uint256[19] __gap;
    }

    function addOfferWithContext(address _offer, uint256 _maxPurchase, uint256 _expiry) external;
    function removeOfferWithContext(address _offer) external;

    function addReservation(
        address _offer,
        address _passport,
        address _patron, 
        bool _cashPayment,
        uint256 _offerId
    ) external returns(uint256 newReservationId);

    function cancelReservation(uint256 _reservationId) external;

    function reservationAddTxnInfoMint(uint256 _reservationId, bytes memory _data) external returns(uint256 offerId);

    function getReservationDetails(uint256 _reservationId) external view returns(Reservation memory);

    function getPatronRecentReservationForOffer(address _patron, address _offer) external view returns(uint256);

    function updateActiveReservationsCount() external;

    function setReservationExpiry(uint256 _newExpiry) external;

    function dispatch (
        uint256 _reservationId,
        bytes memory _data
    ) external;

    function registerUser(
        string memory _name,
        string memory _avatarURI,
        string memory _dataURI
    ) external returns (uint256 userId);

    function mintAvailableCollectibles(address _patron) external;

    function mintLinkedCollectionsTokensForHolders(address _collection) external;

    function mintLinked(address _collectible, address _patron) external;

    function getAllOffers() external view returns(address[] memory);

    function getAllReservations() external view returns(Reservation[] memory _allReservations);

    /*function getAllActiveReservations() external view returns(Reservation[] memory _activeReservations);

    function getPatronReservations(address _patron, bool _checkActive) external view returns(Reservation[] memory _patronReservations);

    function patronReservationActiveForOffer(address _patron, address _offer) external view returns(bool);

    function getActiveReservationsForEntity(address _entity) external view returns(Reservation[] memory _entityActiveReservations);*/

    function getCurrentReservationId() external view returns(uint256);

    function getReservationsForOffer(address _offer) external view returns(uint256[] memory);    
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/collections/ICollectionData.sol";

interface IExternalCollectionManager is ICollectionData {
    event CollectionWhitelisted(address _passport, address _source, uint256 _chainId);
    event CollectionDelisted(address _passport, address _source, uint256 _chainId);

    struct ContractDetails {
        // Contract address
        address source;

        // ChainId where the contract deployed
        uint256 chainId;

        // Storage Gap
        uint256[5] __gap;
    }

    function whitelistCollection(address _source, uint256 _chainId, address _passport) external;

    function getWhitelistedCollectionsForPassport(address _passport) external view returns(ContractDetails[] memory _wl);

    function delistCollection(address _source, uint256 _chainId, address _passport) external;

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ITokenPriceCalculator {

    event SetPricePerMint(uint256 _price);

    function pricePerMint() external view returns(uint256);

    function getTokensEligible(uint256 _amountPaid) external view returns (uint256);

    function setPricePerMint(uint256 _price) external;
}