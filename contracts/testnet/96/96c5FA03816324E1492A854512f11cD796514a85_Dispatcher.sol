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
// This contract consolidates all functionality for managing reservations and user registrations
**************************************************************************************************************/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../access/DAOAccessControlled.sol";

import "../../interfaces/user/IUser.sol";
import "../../interfaces/admin/IEntity.sol";
import "../../interfaces/misc/IDispatcher.sol";
import "../../interfaces/tokens/ILoot8Token.sol";
import "../../interfaces/misc/ICollectionHelper.sol";
import "../../interfaces/misc/ICollectionManager.sol";
import "../../interfaces/collections/ICollectionData.sol";
import "../../interfaces/factories/ICollectionFactory.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Dispatcher is IDispatcher, Initializable, DAOAccessControlled {
    
    using Counters for Counters.Counter;

    // Unique IDs for new reservations
    Counters.Counter private reservationIds;

    // Unique IDs for new offers
    Counters.Counter private offerContractsIds;

    // Time after which a new reservation expires(Seconds)
    uint256 public reservationsExpiry; 
    address public loot8Token;
    address public daoWallet;
    address public userContract;
    address public loot8CollectionFactory;

    // Earliest non-expired reservation, for gas optimization
    uint256 public earliestNonExpiredIndex;

    // List of all offers
    address[] public allOffers;

    // Offer/Event wise context for each offer/event
    mapping(address => OfferContext) public offerContext;

    // Mapping ReservationID => Reservation Details
    mapping(uint256 => Reservation) public reservations;

    function initialize(
        address _authority,
        address _loot8Token,
        address _daoWallet,
        uint256 _reservationsExpiry,
        address _userContract,
        address _loot8CollectionFactory
    ) public initializer {

        DAOAccessControlled._setAuthority(_authority);
        loot8Token = _loot8Token;
        daoWallet = _daoWallet;
        reservationsExpiry = _reservationsExpiry;

        // Start ids with 1 as 0 is for existence check
        offerContractsIds.increment();
        reservationIds.increment();
        earliestNonExpiredIndex = reservationIds.current();
        userContract = _userContract;
        loot8CollectionFactory = _loot8CollectionFactory;
    }

    function addOfferWithContext(address _offer, uint256 _maxPurchase, uint256 _expiry) external {
        
        require(msg.sender == authority.getAuthorities().collectionManager, 'UNAUTHORIZED');

        OfferContext storage oc = offerContext[_offer];
        oc.id = offerContractsIds.current();
        oc.expiry = _expiry;
        oc.totalPurchases = 0;
        oc.activeReservationsCount = 0;
        oc.maxPurchase = _maxPurchase;

        allOffers.push(_offer);

        offerContractsIds.increment();
    }

    function removeOfferWithContext(address _offer) external {
        require(msg.sender == authority.getAuthorities().collectionManager, 'UNAUTHORIZED');
        require(offerContext[_offer].expiry < block.timestamp, "OFFER NOT EXPIRED");
        updateActiveReservationsCount();
        require(offerContext[_offer].activeReservationsCount == 0, "OFFER HAS ACTIVE RESERVATIONS");
        delete offerContext[_offer];
        for (uint256 i = 0; i < allOffers.length; i++) {
            if(allOffers[i] == _offer) {
                if( i < allOffers.length - 1) {
                    allOffers[i] = allOffers[allOffers.length - 1];
                }
                allOffers.pop();
            }
        }
    }

    /**
     * @notice Called to create a reservation when a patron places an order using their mobile app
     * @param _offer address Address of the offer contract for which a reservation needs to be made
     * @param _patron address
     * @param _cashPayment bool True if cash will be used as mode of payment
     * @return newReservationId Unique Reservation Id for the newly created reservation
    */
    function addReservation(
        address _offer,
        address _patron, 
        bool _cashPayment,
        uint256 _offerId
    ) external onlyForwarder
    returns(uint256 newReservationId) {

        uint256 _patronRecentReservation = offerContext[_offer].patronRecentReservation[_patron];

        require(
            reservations[_patronRecentReservation].fulfilled ||
            reservations[_patronRecentReservation].cancelled || 
            reservations[_patronRecentReservation].expiry <= block.timestamp, 'PATRON HAS AN ACTIVE RESERVATION');

        require(ICollectionManager(authority.getAuthorities().collectionManager).checkCollectionActive(_offer), "OFFER IS NOT ACTIVE");
        this.updateActiveReservationsCount();
        
        require(
            (offerContext[_offer].maxPurchase == 0 || 
            (offerContext[_offer].totalPurchases + offerContext[_offer].activeReservationsCount) < offerContext[_offer].maxPurchase),
            'MAX PURCHASE EXCEEDED'
        );
        
        offerContext[_offer].activeReservationsCount++;

        uint256 _expiry = block.timestamp + reservationsExpiry;

        newReservationId = reservationIds.current();

        uint256[20] memory __gap;
        // Create reservation
        reservations[newReservationId] = Reservation({
            id: newReservationId,
            patron: _patron,
            created: block.timestamp,
            expiry: _expiry,
            offer: _offer,
            offerId: _offerId, // 0 for normal offers. > 0 for redeemable coupons
            cashPayment: _cashPayment,
            data: "",
            cancelled: false,
            fulfilled: false,
            __gap: __gap
        });

        offerContext[_offer].patronRecentReservation[_patron] = newReservationId;

        offerContext[_offer].reservations.push(newReservationId);

        // Dispatch and fulfill a reservation for redeemable coupons that don't need bartender approval/serve
        if(_offerId > 0 &&  !_cashPayment) {
            _dispatch(newReservationId, '');
        }

        reservationIds.increment();

        address _entity = ICollectionManager(authority.getAuthorities().collectionManager).getCollectionData(_offer).entity;

        emit ReservationAdded(_entity, _offer, _patron, newReservationId, _expiry, _cashPayment);
    }

    /**
     * @notice Called by bartender or patron to cancel a reservation
     * @param _reservationId uint256
    */
    function cancelReservation(uint256 _reservationId) external {
        
        require(reservations[_reservationId].id != 0, 'INVALID RESERVATION');
        require(!reservations[_reservationId].fulfilled, "DISPATCHED RESERVATION");
        require(!reservations[_reservationId].cancelled, "CANCELLED RESERVATION");

        address _offer = reservations[_reservationId].offer;
        address _entity = ICollectionManager(authority.getAuthorities().collectionManager).getCollectionData(_offer).entity;
        require(
            IEntity(_entity).getBartenderDetails(_msgSender()).isActive || 
            _msgSender() == reservations[_reservationId].patron, "UNAUTHORIZED"
        );

        reservations[_reservationId].cancelled = true;
        offerContext[_offer].activeReservationsCount--;
        
        // TODO: Burn collectible if minted
        emit ReservationCancelled(_entity, _offer, _reservationId);
    }

    /**
     * @notice Mints a Collectible for a reservation and sets the offer Id in Reservation details
     * @param _reservationId uint256
     * @param _data bytes Meta data for the reservation
     * @return offerId uint256 Token Id for newly minted Collectible
    */
    function reservationAddTxnInfoMint(uint256 _reservationId, bytes memory _data) external returns(uint256 offerId) {
        require(_msgSender() == address(this) || isTrustedForwarder(msg.sender), "UNAUTHORIZED");
        require(reservations[_reservationId].id != 0, 'INVALID RESERVATION');

        address _offer = reservations[_reservationId].offer;
        address _entity = ICollectionManager(authority.getAuthorities().collectionManager).getCollectionData(_offer).entity;
        offerId = _mintCollectibles(_offer, reservations[_reservationId].patron);
        emit TokenMintedForReservation(_entity, _offer, _reservationId, offerId);
        if(offerId > 0) {
            reservations[_reservationId].offerId = offerId;
        }
        reservations[_reservationId].data = _data;
    }

    function getReservationDetails(uint256 _reservationId) public view returns(Reservation memory){
        require(reservations[_reservationId].id != 0, 'INVALID RESERVATION');
        return reservations[_reservationId];
    }

    function getPatronRecentReservationForOffer(address _patron, address _offer) public view returns(uint256) {
        return offerContext[_offer].patronRecentReservation[_patron];
    }

    /**
     * @notice Maintenance function to cancel expired reservations and update active reservation counts
    */
    function updateActiveReservationsCount() public {

        for (uint256 i = earliestNonExpiredIndex; i < reservationIds.current(); i++) {
            
            Reservation storage reservation = reservations[i];

            if (reservation.offerId == 0) { // we cannot cancel reservations if offer token minted
                if (
                    reservation.expiry <= block.timestamp && 
                    !reservation.cancelled &&
                    !reservation.fulfilled
                ) {
                    reservation.cancelled = true;
                    if(offerContext[reservation.offer].activeReservationsCount > 0) {
                        offerContext[reservation.offer].activeReservationsCount--;
                    }
                }
            }

            // Set earliestNonExpiredIndex for next updateActiveReservationsCount call
            if(
                (
                    reservations[earliestNonExpiredIndex].cancelled ||
                    reservations[earliestNonExpiredIndex].fulfilled
                ) && (
                    reservation.expiry > block.timestamp && 
                    !reservation.cancelled && !reservation.fulfilled
                )
            ) {
                earliestNonExpiredIndex = reservation.id;
            }
            
        }
    }

    function dispatch (
        uint256 _reservationId,
        bytes memory _data
    ) public {
        address _offer = reservations[_reservationId].offer;
        address _entity = ICollectionManager(authority.getAuthorities().collectionManager).getCollectionData(_offer).entity;
        require(IEntity(_entity).getBartenderDetails(_msgSender()).isActive, "UNAUTHORIZED");
        _dispatch(_reservationId, _data);
    }

    function _dispatch (
        uint256 _reservationId,
        bytes memory _data
    ) internal {

        require(reservations[_reservationId].id != 0, 'INVALID RESERVATION');
        require(!reservations[_reservationId].fulfilled, "DISPATCHED RESERVATION");
        require(!reservations[_reservationId].cancelled, "CANCELLED RESERVATION");

        address _offer = reservations[_reservationId].offer;
        address _entity = ICollectionManager(authority.getAuthorities().collectionManager).getCollectionData(_offer).entity;

        require(offerContext[_offer].id != 0, "No Such Offer");
        address patron = reservations[_reservationId].patron;
        
        require(offerContext[_offer].patronRecentReservation[patron] == _reservationId, 'RESERVATION NOT RECENT OR ACTIVE');
        require(!reservations[_reservationId].cancelled, 'CANCELLED RESERVATION');
        require(reservations[_reservationId].expiry > block.timestamp, 'RESERVATION EXPIRED');

        uint256 _offerId;

        // Mint Collectible if not already minted
        if(reservations[_reservationId].offerId == 0) {
            _offerId = this.reservationAddTxnInfoMint(_reservationId, _data);
        }

        // Fulfill the reservation
        _fulfillReservation(_reservationId);

        emit OrderDispatched(_entity, _offer, _reservationId, _offerId);
    }

    /**
     * @notice Allows the administrator to change expiry for reservations
     * @param _newExpiry uint256 New expiry timestamp
    */
    function setReservationExpiry(uint256 _newExpiry) external onlyGovernor {
        reservationsExpiry = _newExpiry;

        emit ReservationsExpirySet(_newExpiry);
    }

    /**
     * @notice Allows the administrator to change user contract for registrations
     * @param _newUserContract address
    */
    function setUserContract(address _newUserContract) external onlyGovernor {
        userContract = _newUserContract;

        emit UserContractSet(_newUserContract);
    }

    /**
     * @notice Allows the administrator to change Loot8 collection factory contract for collections minting
     * @param _newLoot8CollectionFactory address Address of the new Loot8 collection factory contract
    */
    function setLoot8CollectionFactory(address _newLoot8CollectionFactory) external onlyGovernor {
        loot8CollectionFactory = _newLoot8CollectionFactory;

        emit Loot8CollectionFactorySet(_newLoot8CollectionFactory);
    }

    /**
     * @notice Called to complete a reservation when order is dispatched
     * @param _reservationId uint256
    */
    function _fulfillReservation(uint256 _reservationId) internal {
        require(reservations[_reservationId].id != 0, 'INVALID RESERVATION');
        reservations[_reservationId].fulfilled = true;

        address offer = reservations[_reservationId].offer;
        offerContext[offer].activeReservationsCount--;
        offerContext[offer].totalPurchases++;

        uint256 _offerId = reservations[_reservationId].offerId;
        ICollectionManager(authority.getAuthorities().collectionManager).setCollectibleRedemption(offer, _offerId);

        uint256 rewards = ICollectionHelper(authority.collectionHelper()).calculateRewards(offer, 1);

        _mintRewards(_reservationId, rewards);

        _creditRewardsToPassport(_reservationId, rewards);

        address _entity = ICollectionManager(authority.getAuthorities().collectionManager).getCollectionData(offer).entity;

        emit ReservationFulfilled(_entity, offer, reservations[_reservationId].patron, _reservationId, _offerId);
    }
    
    function _getOfferPassport(address _offer) internal view returns(address) {
        
        address[] memory _collections = ICollectionHelper(authority.collectionHelper()).getAllLinkedCollections(_offer);

        for(uint256 i = 0; i < _collections.length; i++) {
            if(
                ICollectionManager(authority.getAuthorities().collectionManager).getCollectionType(_collections[i]) == 
                ICollectionData.CollectionType.PASSPORT
            ) {
                return _collections[i];
            }
        }

        return address(0);

    }

    function _mintRewards(uint256 _reservationId, uint256 _rewards) internal {
        address offer = reservations[_reservationId].offer;
        address entity = ICollectionManager(authority.getAuthorities().collectionManager).getCollectionData(offer).entity;

        ILoot8Token(loot8Token).mint(reservations[_reservationId].patron, _rewards);
        ILoot8Token(loot8Token).mint(daoWallet, _rewards);
        ILoot8Token(loot8Token).mint(entity, _rewards);
    }

    function _creditRewardsToPassport(uint256 _reservationId, uint256 _rewards) internal {
        address _passport = _getOfferPassport(reservations[_reservationId].offer);
        if(_passport != address(0)) {
            ICollectionManager(authority.getAuthorities().collectionManager).creditRewards(_passport, reservations[_reservationId].patron, _rewards);
        }
    }

    function registerUser(
        string memory _name,
        string memory _avatarURI,
        string memory _dataURI
    ) external onlyForwarder returns (uint256 userId) {
        
        userId = IUser(userContract).register(_name, _msgSender(), _avatarURI, _dataURI);

        _mintAvailableCollectibles(_msgSender());
    }   

    function mintAvailableCollectibles(address _patron) external onlyForwarder {
        _mintAvailableCollectibles(_patron);
    }

    /*
     * @notice Mints available passports and their linked collections
     * @param _patron address The patron to whom collections should be minted
    */
    function _mintAvailableCollectibles(address _patron) internal {
        
        IExternalCollectionManager.ContractDetails[] memory allLoot8Collections = ICollectionManager(authority.getAuthorities().collectionManager).getAllCollectionsWithChainId(CollectionType.PASSPORT, true);

        ICollectionManager collectionManager = ICollectionManager(authority.getAuthorities().collectionManager);

        for(uint256 i = 0; i < allLoot8Collections.length; i++) {

            (string[] memory points, uint256 radius) = collectionManager.getLocationDetails(allLoot8Collections[i].source);
          
            if( 
                points.length == 0 
                && radius == 0
            ) {

                (,,,,CollectionDataAdditional memory _additionCollectionData,,,,,) = collectionManager.getCollectionInfo(allLoot8Collections[i].source);

                if(!_additionCollectionData.mintWithLinkedOnly) {
                    uint256 balance = IERC721(allLoot8Collections[i].source).balanceOf(_patron);
                    if(balance == 0) {
                        _mintCollectibles(allLoot8Collections[i].source, _patron);
                    }
                }
            }
        }
    }

    function mintLinkedCollectionsTokensForHolders(address _collection) external onlyForwarder {
        
        require(ICollectionManager(authority.getAuthorities().collectionManager).checkCollectionActive(_collection), "Collection is retired");

        IUser.UserAttributes[] memory allUsers = IUser(userContract).getAllUsers(false);

        for(uint256 i=0; i < allUsers.length; i++) {
            mintLinked(_collection, allUsers[i].wallet);
        }

    }

    function _mintCollectibles(address _collection, address _patron) internal returns (uint256 collectibleId) {

        ICollectionManager collectionManager = ICollectionManager(authority.getAuthorities().collectionManager);

        collectibleId = collectionManager.mintCollectible(_patron, _collection);

        if (collectionManager.getCollectionType(_collection) == CollectionType.PASSPORT) {
            mintLinked(_collection, _patron);
        }
    }

    /**
     * @notice Mints collectibles for collections linked to a given collection
     * @notice Minting conditions:
     * @notice The patron should have a non-zero balance of the collection
     * @notice The linked collection should be active
     * @notice The linked collection should have the mintWithLinked boolean flag set to true for itself
     * @notice The patron should have a zero balance for the linked collection
     * @param _collection uint256 Collection for which linked collectibles are to be minted
     * @param _patron uint256 Mint to the same patron to which the collectible was minted
     */
    function mintLinked(address _collection, address _patron) public virtual override {

        require(
            _msgSender() == address(this) || 
            _msgSender() == authority.getAuthorities().collectionManager || 
            isTrustedForwarder(msg.sender), "UNAUTHORIZED"
        );
        
        ICollectionManager collectionManager = ICollectionManager(authority.getAuthorities().collectionManager);

        ICollectionHelper collectionHelper = ICollectionHelper(authority.collectionHelper());

        // Check if collection is active
        require(collectionManager.checkCollectionActive(_collection), "Collectible is retired");
        
        if(IERC721(_collection).balanceOf(_patron) > 0) {
            
            address[] memory linkedCollections = collectionHelper.getAllLinkedCollections(_collection);

            for (uint256 i = 0; i < linkedCollections.length; i++) {
                if(
                    collectionManager.checkCollectionActive(linkedCollections[i]) &&
                    collectionManager.getCollectionData(linkedCollections[i]).mintWithLinked &&
                    collectionManager.getCollectionChainId(linkedCollections[i]) == block.chainid &&
                    IERC721(linkedCollections[i]).balanceOf(_patron) == 0
                ) {
                    _mintCollectibles(linkedCollections[i], _patron);
                }
            }

        }
    }

    function getAllOffers() public view returns(address[] memory) {
        return allOffers;
    }

    function getCurrentReservationId() public view returns(uint256) {
        return reservationIds.current();
    }

    function getReservationsForOffer(address _offer) public view returns(uint256[] memory) {
        return offerContext[_offer].reservations;
    }
 
    function getAllReservations() external view returns(Reservation[] memory _allReservations) {

        _allReservations = new Reservation[](reservationIds.current());
        for(uint256 i = 0; i < reservationIds.current(); i++) {
            _allReservations[i] = reservations[i];
        }
    }

    function testUpgrade() public pure returns(uint256) {
        return 0;
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
        // Zero for unlimited
        uint256 maxBalance;

        // Is minted only when a linked collection is minted
        bool mintWithLinkedOnly;

        // Storage Gap
        uint256[19] __gap; //0th element is being used for isCoupon flag. zero = false, nonzero = true.
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

interface ICollectionFactory {

    /*************** EVENTS ***************/
    event CreatedCollection(address _entity, address _collection);

    function createCollection(
        address _entity,
        string memory _name, 
        string memory _symbol,
        string memory _dataURI,
        bool _transferable,
        address _helper,
        address _layerZeroEndpoint
    ) external  returns (address _collection);
    
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

    function updateContractURI(address _collection, string memory _contractURI) external;
    function calculateRewards(address _collection, uint256 _quantity) external view returns(uint256);
    function linkCollections(address _collection1, address _collection2) external;
    function delinkCollections(address _collection1, address _collection2) external;
    function areLinkedCollections(address _collection1, address _collection2) external view returns(bool _areLinked);
    function getAllLinkedCollections(address _collection) external view returns (address[] memory);
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

        // Storage Gap
        uint256[20] __gap;
    }

    function addOfferWithContext(address _offer, uint256 _maxPurchase, uint256 _expiry) external;
    function removeOfferWithContext(address _offer) external;

    function addReservation(
        address _offer,
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

interface ILoot8Token {
    function mint(address account_, uint256 amount_) external;
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IUser {

    /* ========== EVENTS ========== */
    event UserCreated(address indexed _walletAddress, uint256 indexed _userId, string _name);
    event UserRemoved(address indexed _walletAddress);

    event NameChanged(address indexed _user, string _name);
    event AvatarURIChanged(address indexed _user, string _avatarURI);
    event DataURIChanged(address indexed _user, string _dataURI);

    event Banned(address indexed _user);
    event BanLifted(address indexed _user);

    struct UserAttributes {
        uint256 id;
        string name;
        address wallet;
        string avatarURI;
        string dataURI;
        address[] adminAt; // List of entities where user is an Admin
        address[] bartenderAt; // List of entities where user is a bartender

        // Storage Gap
        uint256[20] __gap;
    }

    function register(string memory _name, address walletAddress, string memory _avatarURI, string memory _dataURI) external returns (uint256);

    function deregister() external;

    function changeName(string memory _name) external;
    
    function getAllUsers(bool _includeBanned) external view returns(UserAttributes[] memory _users);

    function getBannedUsers() external view returns(UserAttributes[] memory _users);

    function isValidPermittedUser(address _user) external view returns(bool);

    function addEntityToOperatorsList(address _user, address _entity, bool _admin) external;

    function removeEntityFromOperatorsList(address _user, address _entity, bool _admin) external;

    function isUserOperatorAt(address _user, address _entity, bool _admin) external view returns(bool, uint256);

}