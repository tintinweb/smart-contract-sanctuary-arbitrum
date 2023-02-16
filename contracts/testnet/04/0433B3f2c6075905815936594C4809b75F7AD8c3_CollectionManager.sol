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
import "../../interfaces/collections/ILoot8Collection.sol";
import "../../interfaces/tokens/ITokenPriceCalculator.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CollectionManager is ICollectionManager, Initializable, DAOAccessControlled {
    // Indicates if a collection is active in the Loot8 eco-system
    mapping(address => bool) public collectionIsActive;

    // List of collectible Ids minted for a collection
    mapping(address => uint256[]) public collectionCollectibleIds;

    // Mapping Collection Address => Collection Data
    // Maintains collection data holding information for
    // a given collection of collectibles at a given address
    mapping(address => CollectionData) public collectionData;

    // Mapping Collection Address => List of linked collectibles
    // List of all collectibles linked to a given collectible
    // Eg: An offer linked to a passport, digital collectible linked
    // to a passport, offer linked to digital collectible linked to passport, etc.
    mapping(address => address[]) public linkedCollections;

    // Mapping Collection Address => Area
    // Area for which a given collection is valid
    mapping(address => Area) public area;

    // Mapping Collection Address => Collection Type
    // Type of Collection(Passport, Offer, Event, Digital Collection)
    mapping(address => CollectionType) public collectionType;

    // Mapping Collection Address => Collectible ID => Collectible Attributes
    // A mapping that maps collectible ids to its details for a given collection
    mapping(address => mapping(uint256 => CollectibleDetails)) public collectibleDetails;

    // (address => chainId => index) 1-based index lookup for third-party collections whitelisting/delisting
    // Mapping Passport => Collection address => Chain Id => Index in whitelistedCollections[passport]
    mapping(address => mapping(address => mapping(uint256 => uint256))) public whitelistedCollectionsLookup;
    
    // List of whitelisted third-party collection contracts
    // Mapping Passport to List of linked external collections
    mapping(address => ContractDetails[]) public whitelistedCollections;

    // Collections for a given Entity
    // Entity address => Collections list
    mapping(address => address[]) public entityCollections;

    // Used to check for existence of a collection in LOOT8 system
    mapping(address => bool) public collectionExists;

    IDispatcher public dispatcher;
    ITokenPriceCalculator public tokenPriceCalculator;
   
    address[] public allCollections;

    // Lists of all collections by types
    address[] public passports;
    address[] public events;
    address[] public offers;
    address[] public collections;

    uint16 INVALID;
    uint16 SUSPENDED;
    uint16 LINKED;
    uint16 NOT_LINKED;
    uint16 EXIST;
    uint16 NOT_EXIST;
    uint16 RETIRED; 
    mapping(uint16 => string) private errorMessages;

    function initialize(
        address _authority,
        address _dispatcher,
        address _tokenPriceCalculator
    ) public initializer {
        DAOAccessControlled._setAuthority(_authority);

        dispatcher = IDispatcher(_dispatcher);
        tokenPriceCalculator = ITokenPriceCalculator(_tokenPriceCalculator);

        INVALID = 1;
        SUSPENDED = 2;
        LINKED = 3;
        NOT_LINKED = 4;
        EXIST = 5;
        NOT_EXIST = 6;
        RETIRED = 7; 
   
        errorMessages[INVALID] = "INVALID COLLECTIBLE";
        errorMessages[SUSPENDED] = "COLLECTIBLE SUSPENDED";
        errorMessages[LINKED] = "LINKED COLLECTIBLES";
        errorMessages[NOT_LINKED] = "NOT LINKED COLLECTIBLES";
        errorMessages[NOT_EXIST] = "COLLECTION DOES NOT EXIST";
        errorMessages[EXIST] = "COLLECTION EXISTS";
        errorMessages[RETIRED] = "COLLECTION RETIRED";
    }

    function addCollection(
        address _collection,
        CollectionType _collectionType,
        CollectionData calldata _collectionData,
        Area calldata _area
    ) external onlyEntityAdmin(_collectionData.entity) {
        require(_collectionType != CollectionType.ANY, errorMessages[INVALID]);
        require(!collectionExists[_collection], errorMessages[EXIST]);
    
        _addCollectionToLists(_collection, _collectionData.entity, _collectionType);

        // Set collection type
        collectionType[_collection] = _collectionType;

        // Set the data for the collection
        collectionData[_collection] = _collectionData;

        // Set the area where collection is valid
        area[_collection] = _area;

        // Set collection as active
        collectionIsActive[_collection] = true;

        if (_collectionType ==  CollectionType.OFFER || _collectionType == CollectionType.EVENT) {
            dispatcher.addOfferWithContext(_collection, _collectionData.maxPurchase, _collectionData.end);
        }

        collectionExists[_collection] = true;

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

        CollectionType _collectionType = collectionType[_collection];
        if (_collectionType ==  CollectionType.OFFER || _collectionType == CollectionType.EVENT) {
            dispatcher.removeOfferWithContext(_collection);
        }

        collectionExists[_collection] = false;

        // Remove collection type
        delete collectionType[_collection];
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

    function mintCollectible(
        address _patron,
        address _collection
    ) external onlyDispatcher returns(uint256 _collectibleId) {

        // Check if the patron already holds this passport and more passports still available
        if(collectionType[_collection] == CollectionType.PASSPORT) {
            if (IERC721(_collection).balanceOf(_patron) > 0 || collectionCollectibleIds[_collection].length < collectionData[_collection].maxMint) {
                return 0;
            }
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

    /*
     * @notice Link two collections
     * @param _collection1 address
     * @param _collection2 address
    */
    function linkCollections(address _collection1, address _collection2) external {
        require(
            IEntity(collectionData[_collection1].entity).getEntityAdminDetails(_msgSender()).isActive || 
            IEntity(collectionData[_collection2].entity).getEntityAdminDetails(_msgSender()).isActive,
            "UNAUTHORIZED"
        );

        require(collectionExists[_collection1] && collectionExists[_collection2], errorMessages[NOT_EXIST]);

        require(!areLinkedCollections(_collection1, _collection2), errorMessages[LINKED]);
        
        linkedCollections[_collection1].push(_collection2);
        linkedCollections[_collection2].push(_collection1);

        // Emit an event marking a collectible holders friends visit to the club
        emit CollectionsLinked(_collection1, _collection1);
    }

    function delinkCollections(address _collection1, address _collection2) external {
        
        require(
            IEntity(collectionData[_collection1].entity).getEntityAdminDetails(_msgSender()).isActive || 
            IEntity(collectionData[_collection2].entity).getEntityAdminDetails(_msgSender()).isActive,
            "UNAUTHORIZED"
        );

        require(collectionExists[_collection1] && collectionExists[_collection2], errorMessages[NOT_EXIST]);
        require(areLinkedCollections(_collection1, _collection2), errorMessages[NOT_LINKED]);

        for (uint256 i = 0; i < linkedCollections[_collection1].length; i++) {
            if (linkedCollections[_collection1][i] == _collection2) {
                if(i < linkedCollections[_collection1].length - 1) {
                    linkedCollections[_collection1][i] = linkedCollections[_collection1][linkedCollections[_collection1].length-1];
                }
                linkedCollections[_collection1].pop();
                break;
            }
        }

        for (uint256 i = 0; i < linkedCollections[_collection2].length; i++) {
            if (linkedCollections[_collection2][i] == _collection1) {
                // delete linkedCollections[i];
                if(i < linkedCollections[_collection2].length - 1) {
                    linkedCollections[_collection2][i] = linkedCollections[_collection2][linkedCollections[_collection2].length-1];
                }
                linkedCollections[_collection2].pop();
                break;
            }
        }

        emit CollectionsDelinked(_collection1, _collection2);
    }

    /**
     * @notice Toggles mintWithLinked flag to true or false
     * @notice Can only be toggled by entity admin
     * @param _collection address
    */
    function toggleMintWithLinked(address _collection) external onlyEntityAdmin(collectionData[_collection].entity) {
        collectionData[_collection].mintWithLinked = !collectionData[_collection].mintWithLinked;
        emit  CollectionMintWithLinkedToggled(_collection, collectionData[_collection].mintWithLinked);
    }

    function retireCollection(address _collection) external onlyEntityAdmin(collectionData[_collection].entity) {
        require(collectionIsActive[_collection], errorMessages[RETIRED]);

        collectionIsActive[_collection] = false;
        emit CollectionRetired(_collection, collectionType[_collection]);
    }

    function calculateRewards(address _collection, uint256 _quantity) public view returns(uint256) {
        require(collectionExists[_collection], errorMessages[NOT_EXIST]);
        return tokenPriceCalculator.getTokensEligible(collectionData[_collection].price * _quantity);
    }

    /**
     * @notice            add an address to third-party collections whitelist
     * @param _source     address collection contract address
     * @param _chainId    uint256 chainId where contract is deployed
     * @param _passport   address Passport for which the the collection be whitelisted
     */
    function whitelistCollection(address _source, uint256 _chainId, address _passport) onlyEntityAdmin(getCollectionData(_passport).entity) external {
        require(collectionType[_passport] == CollectionType.PASSPORT, "NOT A PASSPORT");
        uint256 index = whitelistedCollectionsLookup[_passport][_source][_chainId];
        require(index == 0, errorMessages[EXIST]);

        uint256[5] memory __gap;
        whitelistedCollections[_passport].push(ContractDetails({
            source: _source,
            chainId: _chainId,
            __gap: __gap
        }));

        whitelistedCollectionsLookup[_passport][_source][_chainId] = whitelistedCollections[_passport].length; // store as 1-based index
        emit CollectionWhitelisted(_passport, _source, _chainId);
    }

    /**
     * @notice          remove an address from third-party collections whitelist
     * @param _source   collections contract address
     * @param _chainId  chainId where contract is deployed
     * @param _passport address Passport for which the the collection be whitelisted
     */
    function delistCollection(address _source, uint256 _chainId, address _passport) onlyEntityAdmin(address(this)) external {
        require(collectionType[_passport] == CollectionType.PASSPORT, "NOT A PASSPORT");
        uint256 index = whitelistedCollectionsLookup[_passport][_source][_chainId];
        require(index > 0, errorMessages[NOT_EXIST]);
        index -= 1; // convert to 0-based index

        if (index < whitelistedCollections[_passport].length - 1) {
            whitelistedCollections[_passport][index] = whitelistedCollections[_passport][whitelistedCollections[_passport].length - 1];
        }
        whitelistedCollections[_passport].pop();
        delete whitelistedCollectionsLookup[_passport][_source][_chainId];

        emit CollectionDelisted(_passport, _source, _chainId);
    }

    function setCollectibleRedemption(address _collection, uint256 _collectibleId) external onlyDispatcher {
        collectibleDetails[_collection][_collectibleId].redeemed = true;
    }

    function isCollection(address _collection) public view returns(bool) {
        return collectionExists[_collection];
    }

    function isRetired(address _collection, uint256 _collectibleId) external view returns(bool) {
        return !collectibleDetails[_collection][_collectibleId].isActive;
    }

    function areLinkedCollections(address _collection1, address _collection2) public view returns(bool _areLinked) {
        require(collectionExists[_collection1] && collectionExists[_collection2], errorMessages[NOT_EXIST]);

        for (uint256 i = 0; i < linkedCollections[_collection1].length; i++) {
            if(linkedCollections[_collection1][i] == _collection2) {
                _areLinked = true;
                break;
            }
        }

    }
    
    function checkCollectionActive(address _collection) public view returns(bool) {
        return collectionIsActive[_collection];
    }

    /*
     * @notice Returns collectible details for a given collectibleID belonging to a collection
     * @param _collection address The collection to which the collectible belongs
     * @param _collectibleId uint256 Collectible ID for which details need to be fetched
    */
    function getCollectibleDetails(address _collection, uint256 _collectibleId) external view returns(CollectibleDetails memory) {
        return collectibleDetails[_collection][_collectibleId];
    }

    function getCollectionType(address _collection) external view returns(CollectionType) {
        return collectionType[_collection];
    }

    function getCollectionData(address _collection) public view returns(CollectionData memory) {
        return collectionData[_collection];
    }

    function getAllLinkedCollections(address _collection) public view returns (address[] memory) {
        return linkedCollections[_collection];
    }

    function getLocationDetails(address _collection) external view returns(string[] memory, uint256) {
        return (area[_collection].points, area[_collection].radius);
    }

    function getAllTokensForPatron(address _collection, address _patron) public view returns(uint256[] memory _patronTokenIds) {
        
        IERC721 collection = IERC721(_collection);

        uint256 tokenId = 1;
        uint256 patronBalance = collection.balanceOf(_patron);
        uint256 i = 0;

        _patronTokenIds = new uint256[](patronBalance);

        while(i < patronBalance) {
            if(collection.ownerOf(tokenId) == _patron) {
                _patronTokenIds[i] = tokenId;
                i++;
            }

            tokenId++;

        }

    }

    function getCollectionTokens(address _collection) external view returns(uint256[] memory) {
        return collectionCollectibleIds[_collection];
    }

    function getCollectionInfo(address _collection) external view 
        returns (string memory _name,
        string memory _symbol,
        string memory _dataURI,
        CollectionData memory _data,
        bool _isActive,
        string[] memory _areaPoints,
        uint256 _areaRadius,
        address[] memory _linkedCollections,
        CollectionType _collectionType) {
        
        _name = IERC721Metadata(_collection).name();
        _symbol = IERC721Metadata(_collection).symbol();
        if (collectionCollectibleIds[_collection].length > 0) {
            _dataURI = IERC721Metadata(_collection).tokenURI(collectionCollectibleIds[_collection][0]);
        } else {
            _dataURI = "";
        }

        _data = getCollectionData(_collection);
        _areaPoints = area[_collection].points;
        _areaRadius = area[_collection].radius;
        _isActive = checkCollectionActive(_collection);
        _linkedCollections = getAllLinkedCollections(_collection);
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

    function getAllCollections(CollectionType _collectionType, bool _onlyActive) public view returns(address[] memory _allCollections) {

        address[] memory collectionList = _getListForCollectionType(_collectionType);

        uint256 count;
        for (uint256 i = 0; i < collectionList.length; i++) {
            if (!_onlyActive || checkCollectionActive(collectionList[i])) {
                count++;
            }
        }
        
        _allCollections = new address[](count);
        uint256 _idx;
        for (uint256 i = 0; i < collectionList.length; i++) {
            if (!_onlyActive || checkCollectionActive(collectionList[i])) {
                _allCollections[_idx] = collectionList[i];
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
                IERC721(collectionList[i]).balanceOf(_patron) > 0
            ) {
                _allCollections[_idx] = collectionList[i];
                _idx++;
            }
        }

    }

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

    struct Authorities {
        address governor;
        address policy;
        address admin;
        address forwarder;
        address dispatcher;
    }

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
        uint256 start;

        // End time from when the Collection will no longer be available for purchase
        uint256 end;

        // Flag to indicate the need for check in to place an order
        bool checkInNeeded;

        // Maximum tokens that can be minted for this collection
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

interface ILoot8Collection {

    function mint(
        address _patron,
        uint256 _collectibleId
    ) external;

    function getNextTokenId() external view returns(uint256 tokenId);

    function burn(uint256 tokenId) external;

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

import "../../interfaces/access/IDAOAuthority.sol";
import "../../interfaces/location/ILocationBased.sol";
import "../../interfaces/collections/ICollectionData.sol";

interface ICollectionManager is ICollectionData, ILocationBased {

    event CollectionAdded(address indexed _collection, CollectionType indexed _collectionType);

    event CollectionRetired(address indexed _collection, CollectionType indexed _collectionType);

    event CollectibleMinted(address indexed _collection, uint256 indexed _collectibleId, CollectionType indexed _collectionType);

    event CollectibleToggled(address indexed _collection, uint256 indexed _collectibleId, bool _status);

    event CollectionsLinked(address indexed _collectible1, address indexed _collectible2);

    event CollectionsDelinked(address indexed _collectible1, address indexed _collectible2);

    event CreditRewards(address indexed _collection, uint256 indexed _collectibleId, address indexed _patron, uint256 _amount);

    event BurnRewards(address indexed _collection, uint256 indexed _collectibleId, address indexed _patron, uint256 _amount);

    event Visited(address indexed _collection, uint256 indexed _collectibleId);

    event FriendVisited(address indexed _collection, uint256 indexed _collectibleId);

    event CollectionMintWithLinkedToggled(address indexed _collection, bool indexed _mintWithLinked);

    event CollectionWhitelisted(address indexed _passport, address indexed _source, uint256 indexed _chainId);

    event CollectionDelisted(address indexed _passport, address indexed _source, uint256 indexed _chainId);

    struct ContractDetails {
        // Contract address
        address source;

        // ChainId where the contract deployed
        uint256 chainId;

        // Storage Gap
        uint256[5] __gap;
    }

    function addCollection(
        address _collection,
        CollectionType _collectionType,
        CollectionData calldata _collectionData,
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

    function linkCollections(address _collection1, address _collection2) external;

    function delinkCollections(address _collection1, address _collection2) external;

    function toggleMintWithLinked(address _collection) external;

    function calculateRewards(address _collection, uint256 _quantity) external view returns(uint256);

    function whitelistCollection(address _source, uint256 _chainId, address _passport) external;

    function delistCollection(address _source, uint256 _chainId, address _passport) external;

    function setCollectibleRedemption(address _collection, uint256 _collectibleId) external;

    function isCollection(address _collection) external view returns(bool);
    
    function isRetired(address _collection, uint256 _collectibleId) external view returns(bool);

    function areLinkedCollections(address _collection1, address _collection2) external view returns(bool _areLinked);

    function checkCollectionActive(address _collection) external view returns(bool);

    function getCollectibleDetails(address _collection, uint256 _collectibleId) external view returns(CollectibleDetails memory);

    function getCollectionType(address _collection) external view returns(CollectionType);

    function getCollectionData(address _collection) external view returns(CollectionData memory);

    function getAllLinkedCollections(address _collection) external view returns (address[] memory);

    function getLocationDetails(address _collection) external view returns(string[] memory, uint256);

    function getCollectionTokens(address _collection) external view returns(uint256[] memory);

    function getCollectionsForEntity(address _entity, CollectionType _collectionType, bool _onlyActive) external view returns(address[] memory _entityCollections);

    function getAllCollections(CollectionType _collectionType, bool _onlyActive) external view returns(address[] memory _allCollections);

    function getAllCollectionsForPatron(CollectionType _collectionType, address _patron, bool _onlyActive) external view returns(address[] memory _allCollections);

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
    event Loot8CollectionMangerSet(address _collectionManager);

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

        // Storage Gap
        uint256[20] __gap;
    }

    function addOfferWithContext(address _offer, uint256 _maxPurchase, uint256 _expiry) external;
    function removeOfferWithContext(address _offer) external;

    function addReservation(
        address _offer,
        address _patron, 
        bool _cashPayment
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

    function getAllActiveReservations() external view returns(Reservation[] memory _activeReservations);

    function getPatronReservations(address _patron, bool _checkActive) external view returns(Reservation[] memory _patronReservations);

    function patronReservationActiveForOffer(address _patron, address _offer) external view returns(bool);

    function getActiveReservationsForEntity(address _entity) external view returns(Reservation[] memory _entityActiveReservations);

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ITokenPriceCalculator {

    event SetPricePerMint(uint256 _price);

    function pricePerMint() external view returns(uint256);

    function getTokensEligible(uint256 _amountPaid) external view returns (uint256);

    function setPricePerMint(uint256 _price) external;
}