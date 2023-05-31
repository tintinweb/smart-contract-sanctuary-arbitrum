// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

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
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC721ContractURI is Ownable {
    /// @notice Current metadata URI for the contract
    string private _contractURI;

    /// @notice Emitted when contractURI has changed
    event ContractURIUpdated(string uri);

    /**
     * Sets the current contractURI for the contract
     *
     * @param _uri New contract URI
     */
    function setContractURI(string calldata _uri) public onlyOwner {
        _contractURI = _uri;
        emit ContractURIUpdated(_uri);
    }

    /**
     * @return Contract metadata URI for the NFT contract, used by NFT marketplaces to display collection inf
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./IERC721BeforeTokenTransferHandler.sol";

abstract contract ERC721OperatorFilter is Context, Ownable, ERC721 {
     /// @notice Reference to the handler contract for transfer hooks
    address public beforeTokenTransferHandler;

    /**
     * Sets the before token transfer handler
     *
     * @param handlerAddress  Address to the transfer hook handler contract
     */
    function setBeforeTokenTransferHandler(
        address handlerAddress
    ) external onlyOwner {
        beforeTokenTransferHandler = handlerAddress;
    }

    /**
     * @notice Handles any pre-transfer actions
     * @inheritdoc ERC721
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        if (beforeTokenTransferHandler != address(0)) {
            IERC721BeforeTokenTransferHandler handlerRef = IERC721BeforeTokenTransferHandler(
                    beforeTokenTransferHandler
                );
            handlerRef.beforeTokenTransfer(
                address(this),
                _msgSender(),
                from,
                to,
                tokenId,
                batchSize
            );
        }

        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IERC721BeforeTokenTransferHandler {
    /**
     * Handles before token transfer events from a ERC721 contract
     */
    function beforeTokenTransfer(
        address tokenContract,
        address operator,
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * Handles before token transfer events from a ERC721 contract with newer OpenZepplin ERC721Consecutive implementation
     */
    function beforeTokenTransfer(
        address tokenContract,
        address operator,
        address from,
        address to,
        uint256 firstId,
        uint256 batchSize
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

bytes32 constant TRUSTED_MIRROR_ROLE = keccak256("TRUSTED_MIRROR_ROLE");
bytes32 constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

/**
 * @title ERC721MirroredL2
 * An extension to ERC721 that allows for ownership to be mirrored from L1 to L2
 * This is meant to be used by contracts using GameRegistryConsumer, but any system can implement _checkRole
 * This is meant to be used with either an Oracle on L1, or an L1 to L2 handler
 */
abstract contract ERC721MirroredL2 is ERC721 {
    bool private _isCheckingRole = true;

    error Soulbound();

    /**
     * @param isCheckingRole Whether to check the TRUSTED_MIRROR_ROLE when transferring tokens
     */
    function setIsCheckingRole(bool isCheckingRole) external {
        _checkRole(MANAGER_ROLE, _msgSender());
        _isCheckingRole = isCheckingRole;
    }

    /**
     * Called by the Oracle or L1 to L2 handler, transfers the ownership.
     * Always checks the role regardless of wether the beforeTransferHook does
     * @param from The address to transfer from
     * @param to The address to transfer to
     * @param tokenId The token id to transfer
     */
    function mirrorOwnership(address from, address to, uint256 tokenId) external {
        _checkRole(TRUSTED_MIRROR_ROLE, _msgSender());

        if (from == address(0x0)) {
            _mint(to, tokenId);
        } else {
            _transfer(from, to, tokenId);
        }
    }

    /**
     * This will be included by GameRegistryConsumer which checks the gameRegistry for various roles
     * @param role The role to check
     * @param account The account to check
     */
    function _checkRole(bytes32 role, address account) internal virtual;


    /**
     * @inheritdoc ERC721
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721)
    {  
        if (_isCheckingRole) {
            _checkRole(TRUSTED_MIRROR_ROLE, _msgSender());
        }

        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import {IGameGlobals, ID as GAME_GLOBALS_ID} from "../gameglobals/IGameGlobals.sol";
import {GameRegistryConsumerUpgradeable} from "../GameRegistryConsumerUpgradeable.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.affinitysystem"));

uint256 constant FIRE_ID = uint256(keccak256("affinity.damagemultiplier.fire"));
uint256 constant WATER_ID = uint256(
    keccak256("affinity.damagemultiplier.water")
);
uint256 constant EARTH_ID = uint256(
    keccak256("affinity.damagemultiplier.earth")
);
uint256 constant AIR_ID = uint256(keccak256("affinity.damagemultiplier.air"));
uint256 constant LIGHTNING_ID = uint256(
    keccak256("affinity.damagemultiplier.lightning")
);

int256 constant AFFINITY_PRECISION_FACTOR = 10000;

enum AffinityTypes {
    UNDEFINED,
    FIRE,
    WATER,
    EARTH,
    AIR,
    LIGHTNING
}

contract AffinitySystem is GameRegistryConsumerUpgradeable {
    mapping(uint256 => uint256) _affinityToGlobal;

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     */
    function initialize(address gameRegistryAddress) public initializer {
        __GameRegistryConsumer_init(gameRegistryAddress, ID);

        _affinityToGlobal[uint256(AffinityTypes.FIRE)] = FIRE_ID;
        _affinityToGlobal[uint256(AffinityTypes.WATER)] = WATER_ID;
        _affinityToGlobal[uint256(AffinityTypes.EARTH)] = EARTH_ID;
        _affinityToGlobal[uint256(AffinityTypes.AIR)] = AIR_ID;
        _affinityToGlobal[uint256(AffinityTypes.LIGHTNING)] = LIGHTNING_ID;
    }

    /**
     * Takes two damage modifiers and returns a percentage to multiply by
     * @param affinityA affinity you have
     * @param affinityB affinity you will be doing damage to
     * @return damageModifier amount in % you will modify (multiply) for that affinity
     */
    function getDamageModifier(
        uint256 affinityA,
        uint256 affinityB
    ) public view returns (uint256) {
        IGameGlobals gameGlobals = IGameGlobals(_getSystem(GAME_GLOBALS_ID));

        uint256[] memory damageModifiers = gameGlobals.getUint256Array(
            _affinityToGlobal[affinityA]
        );

        return damageModifiers[affinityB];
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {AFFINITY_PRECISION_FACTOR, AffinitySystem} from "../affinity/AffinitySystem.sol";
import {CoreMoveSystem} from "../combat/CoreMoveSystem.sol";
import {DAMAGE_TRAIT_ID, ELEMENTAL_AFFINITY_TRAIT_ID, LEVEL_TRAIT_ID, EXPERTISE_TRAIT_ID, EXPERTISE_DAMAGE_ID, EXPERTISE_EVASION_ID, EXPERTISE_SPEED_ID, EXPERTISE_ACCURACY_ID, EXPERTISE_HEALTH_ID} from "../Constants.sol";
import {EntityLibrary} from "../core/EntityLibrary.sol";
import {IEquippable} from "../equipment/IEquippable.sol";
import {ITokenTemplateSystem} from "../tokens/ITokenTemplateSystem.sol";
import {ITraitsProvider} from "../interfaces/ITraitsProvider.sol";
import {CombatStats} from "./Combatable.sol";
import {IGameGlobals} from "../gameglobals/IGameGlobals.sol";

/**
 * @dev Parameters for the validateVersusBattleResult function
 * @param attackerEntity Entity of the attacker (ship NFT)
 * @param defenderEntity Entity of the defender (boss or mob template)
 * @param attackerOverload Entity of the attacker overload (pirate NFT)
 * @param totalDamageDealt Total damage dealt by the attacker
 * @param moves Moves used by the attacker
 * @param affinitySystem Affinity system
 * @param moveSystem Move system
 * @param tokenTemplateSystem TokenTemplate system
 */
struct ValidateVersusResultParams {
    uint256 attackerEntity;
    uint256 defenderEntity;
    uint256 attackerOverload;
    uint256 totalDamageDealt;
    uint256[] moves;
    AffinitySystem affinitySystem;
    CoreMoveSystem moveSystem;
    IEquippable attackerEquippable;
    ITokenTemplateSystem tokenTemplateSystem;
    ITraitsProvider traitsProvider;
    IGameGlobals gameGlobals;
}

enum ExpertiseTypes {
    UNDEFINED,
    DAMAGE,
    EVASION,
    SPEED,
    ACCURACY,
    HEALTH
}

/**
 * @title Battle helpers Library
 */
library BattleLibrary {
    /**
     * @dev Perform simple combat validation
     */
    function validateVersusResult(
        ValidateVersusResultParams memory params
    ) internal view returns (bool) {
        // Get defender affinity from TokenTemplate system
        (address tokenContract, uint256 tokenId) = EntityLibrary.entityToToken(
            params.defenderEntity
        );
        uint256 defenderAffinity = params.tokenTemplateSystem.getTraitUint256(
            tokenContract,
            tokenId,
            ELEMENTAL_AFFINITY_TRAIT_ID
        );

        // Get pirate affinity from TraitsProvider
        (tokenContract, tokenId) = EntityLibrary.entityToToken(
            params.attackerOverload
        );

        // Get affinity for attacker overload vs defender, cast to int256
        int256 attackerAffinityModifier = SafeCast.toInt256(
            params.affinitySystem.getDamageModifier(
                params.traitsProvider.getTraitUint256(
                    tokenContract,
                    tokenId,
                    ELEMENTAL_AFFINITY_TRAIT_ID
                ),
                defenderAffinity
            )
        );

        // Get attacker base damage from TokenTemplate
        (tokenContract, tokenId) = EntityLibrary.entityToToken(
            params.attackerEntity
        );
        int256 attackerBaseDamage = params.tokenTemplateSystem.getTraitInt256(
            tokenContract,
            tokenId,
            DAMAGE_TRAIT_ID
        );
        // Apply Damage mod from expertise
        attackerBaseDamage = applyExpertiseDamageMod(
            params.traitsProvider,
            params.gameGlobals,
            attackerBaseDamage,
            params.attackerOverload
        );

        // Retrieve combat stat modifiers from equipment and move system
        int256[] memory equipmentMods = params
            .attackerEquippable
            .getCombatModifiers(params.attackerEntity);

        // Calculate damage for each move done
        int256[] memory moveMods;
        int256 totalDamageCalculated;
        for (uint i = 0; i < params.moves.length; ++i) {
            moveMods = params.moveSystem.getCombatModifiers(params.moves[i]);
            totalDamageCalculated +=
                ((attackerBaseDamage + equipmentMods[0] + moveMods[0]) *
                    attackerAffinityModifier) /
                AFFINITY_PRECISION_FACTOR;
        }

        // Reported attacker damage cannot exceed total calculated damage
        if (params.totalDamageDealt > uint256(totalDamageCalculated)) {
            return false;
        }

        return true;
    }

    /**
     * @dev Take in base damage and apply expertise damage modifier if applicable
     * @param traitsProvider Traits provider
     * @param gameGlobals Game globals
     * @param baseDamage Base damage
     * @param entity Pirate NFT entity
     */
    function applyExpertiseDamageMod(
        ITraitsProvider traitsProvider,
        IGameGlobals gameGlobals,
        int256 baseDamage,
        uint256 entity
    ) internal view returns (int256) {
        // Get Pirate NFT contract and token ID
        (address pirateContract, uint256 pirateTokenId) = EntityLibrary
            .entityToToken(entity);

        // If Pirate has Damage expertise apply modifier, else return base damage
        if (
            traitsProvider.getTraitUint256(
                pirateContract,
                pirateTokenId,
                EXPERTISE_TRAIT_ID
            ) == uint256(ExpertiseTypes.DAMAGE)
        ) {
            // Get damage mod and multiply by Pirate level
            int256 damageMod = gameGlobals.getInt256(EXPERTISE_DAMAGE_ID);
            baseDamage +=
                damageMod *
                SafeCast.toInt256(
                    traitsProvider.getTraitUint256(
                        pirateContract,
                        pirateTokenId,
                        LEVEL_TRAIT_ID
                    )
                );
        }
        return baseDamage;
    }

    /**
     * @dev Take in base health and apply expertise health modifier if applicable
     * @param traitsProvider Traits provider
     * @param gameGlobals Game globals
     * @param baseHealth Base health
     * @param entity Pirate NFT entity
     */
    function applyExpertiseHealthMod(
        ITraitsProvider traitsProvider,
        IGameGlobals gameGlobals,
        uint256 baseHealth,
        uint256 entity
    ) internal view returns (uint256) {
        // Get Pirate NFT contract and token ID
        (address pirateContract, uint256 pirateTokenId) = EntityLibrary
            .entityToToken(entity);

        // If Pirate has Health expertise apply modifier, else return base health
        if (
            traitsProvider.getTraitUint256(
                pirateContract,
                pirateTokenId,
                EXPERTISE_TRAIT_ID
            ) == uint256(ExpertiseTypes.HEALTH)
        ) {
            // Get health mod and multiply by Pirate level
            uint256 healthMod = gameGlobals.getUint256(EXPERTISE_HEALTH_ID);
            baseHealth +=
                healthMod *
                traitsProvider.getTraitUint256(
                    pirateContract,
                    pirateTokenId,
                    LEVEL_TRAIT_ID
                );
        }
        return baseHealth;
    }

    /**
     *
     * @param traitsProvider Traits provider
     * @param gameGlobals Game globals
     * @param stats Combat stats
     * @param pirateEntity Pirate entity
     */
    function applyExpertiseToCombatStats(
        ITraitsProvider traitsProvider,
        IGameGlobals gameGlobals,
        CombatStats memory stats,
        uint256 pirateEntity
    ) internal view returns (CombatStats memory) {
        // Get Pirate NFT contract and token ID
        (address pirateContract, uint256 pirateTokenId) = EntityLibrary
            .entityToToken(pirateEntity);

        // Get Pirate expertise
        uint256 pirateExpertise = traitsProvider.getTraitUint256(
            pirateContract,
            pirateTokenId,
            EXPERTISE_TRAIT_ID
        );

        // Get Pirate level
        int256 pirateLevel = SafeCast.toInt256(
            traitsProvider.getTraitUint256(
                pirateContract,
                pirateTokenId,
                LEVEL_TRAIT_ID
            )
        );

        // Temporarily cast to int256 for high precision calculations
        int256 newValue;
        if (pirateExpertise == uint256(ExpertiseTypes.DAMAGE)) {
            // Apply Damage mod from expertise
            newValue = gameGlobals.getInt256(EXPERTISE_DAMAGE_ID);
            stats.damage += SafeCast.toInt64(newValue * pirateLevel);
        } else if (pirateExpertise == uint256(ExpertiseTypes.EVASION)) {
            // Apply Evasion mod from expertise
            newValue = gameGlobals.getInt256(EXPERTISE_EVASION_ID);
            stats.evasion += SafeCast.toInt64(newValue * pirateLevel);
        } else if (pirateExpertise == uint256(ExpertiseTypes.SPEED)) {
            // Apply Speed mod from expertise
            newValue = gameGlobals.getInt256(EXPERTISE_SPEED_ID);
            stats.speed += SafeCast.toInt64(newValue * pirateLevel);
        } else if (pirateExpertise == uint256(ExpertiseTypes.ACCURACY)) {
            // Apply Accuracy mod from expertise
            newValue = gameGlobals.getInt256(EXPERTISE_ACCURACY_ID);
            stats.accuracy += SafeCast.toInt64(newValue * pirateLevel);
        }
        // Health is handled separately

        return stats;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {AffinitySystem, ID as AFFINITY_SYSTEM_ID} from "../affinity/AffinitySystem.sol";
import {ICooldownSystem, ID as COOLDOWN_SYSTEM_ID} from "../cooldown/ICooldownSystem.sol";
import {EntityLibrary} from "../core/EntityLibrary.sol";
import {ID as COUNTING_SYSTEM_ID, ICountingSystem} from "../counting/ICountingSystem.sol";
import {ShipEquipment, ID as SHIP_EQUIPMENT_ID} from "../equipment/ShipEquipment.sol";
import {IGameGlobals, ID as GAME_GLOBALS_ID} from "../gameglobals/IGameGlobals.sol";
import {ITraitsProvider} from "../interfaces/ITraitsProvider.sol";
import {ITokenTemplateSystem, ID as TOKEN_TEMPLATE_SYSTEM_ID} from "../tokens/ITokenTemplateSystem.sol";

import {BattleLibrary, ValidateVersusResultParams} from "./BattleLibrary.sol";
import {ID as BOSS_COMBATABLE_ID} from "./BossCombatable.sol";
import {Battle, CoreBattleSystem} from "./CoreBattleSystem.sol";
import {CoreMoveSystem, ID as CORE_MOVE_SYSTEM_ID} from "./CoreMoveSystem.sol";
import {ICombatable, CombatStats} from "./ICombatable.sol";
import {ID as SHIP_COMBATABLE_ID} from "./ShipCombatable.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.bossbattlesystem"));

uint256 constant BOSS_COMBAT_ACCURACY_DICE_ROLL = 200;

uint256 constant BOSS_BATTLE_COOLDOWN_ID = uint256(
    keccak256("boss_battle.cooldown_id")
);

uint256 constant COUNTING_TYPE_SINGLE_BOSS_DAMAGE_DEALT = uint256(
    keccak256("counting.boss_battle.damage_dealt_to_single_boss")
);

uint256 constant COUNTING_TYPE_ALL_BOSS_DAMAGE_DEALT = uint256(
    keccak256("counting.boss_battle.damage_dealt_to_all_bosses_combined")
);

// Game Globals

// Time limit for Boss battles to become available again in seconds
uint256 constant BOSS_BATTLE_COOLDOWN_TIME = uint256(
    keccak256("boss_battle.cooldown_time")
);

// Time limit for valid active Boss battles to complete in seconds
uint256 constant BOSS_BATTLE_TIME_LIMIT = uint256(
    keccak256("boss_battle.time_limit")
);

// Number of moves allowed in valid end battle submission
uint256 constant BOSS_BATTLE_MAX_MOVE_COUNT = uint256(
    keccak256("boss_battle.max_move_count")
);

/**
 * Input for calling startBattle() for Ship vs Boss
 * @param battleSeed Keccak of drand randomness value provided by client
 * @param shipEntity Entity of ShipNFT address plus token id
 * @param shipOverloads Array of ship overloads, must contain pirate captain
 * @param bossEntity Entity of BossSpawn address plus boss ID from SoT doc
 */
struct StartBattleParams {
    uint256 battleSeed;
    uint256 shipEntity;
    uint256 bossEntity;
    uint256[] shipOverloads;
}

/**
 * Input for calling endBattle() for Ship vs Boss
 * @param battleEntity Entity of battle provided from startBattle call
 * @param totalDamageTaken Damage the ship sustained
 * @param totalDamageDealt Damage the ship did to the boss
 * @param moves Set of move ids the ship made in order
 */
struct EndBattleParams {
    uint256 battleEntity;
    uint256 totalDamageTaken;
    uint256 totalDamageDealt;
    uint256[] moves;
}

/// @notice Store Combatant info for calculating for validation
struct Combatant {
    uint256 health;
    uint256 totalDamageCalculated;
    uint256 roll;
    CombatStats stats;
}

/// @notice Input param for _validateEndBattleParamsFull
struct ValidateFullParams {
    uint256 battleSeed;
    uint256 totalDamageTaken;
    uint256 totalDamageDealt;
    uint256 shipHealth;
    uint256 bossHealth;
    address account;
    uint256[] moves;
    Battle battle;
}

/// @notice Record Final Blow data
struct FinalBlow {
    uint256 shipEntity;
    address account;
}

/**
 * @title Boss Battle System
 *
 * @dev manages initialization and conclusion of battles
 */
contract BossBattleSystem is CoreBattleSystem {
    /** MEMBERS */

    /// @notice Mapping to store account address > battleEntity
    mapping(address => uint256) private _accountToBattleEntity;

    /// @notice Mapping to store bossEntity to final blow data
    mapping(uint256 => FinalBlow) public bossEntityToFinalBlow;

    /** ERRORS **/

    /// @notice Battle in progress; finish before starting new combat
    error ActiveBattleInProgress(uint256 battleEntity);

    /// @notice Ship or Boss is not valid for combat
    error InvalidEntity();

    /// @notice Ship NFT is still in cooldown
    error NftStillInCooldown();

    /// @notice Account is still in cooldown
    error AccountStillInCooldown();

    /// @notice Invalid call to end battle
    error InvalidCallToEndBattle();

    /// @notice Battle time limit expired
    error BattleExpired();

    /// @notice Invalid EndBattle params
    error InvalidEndBattleParams();

    /// @notice Invalid damage dealt value reported
    error InvalidDamageDealt();

    /// @notice Invalid damage taken value reported
    error InvalidDamageTaken();

    /** ERRORS **/

    /// @notice Emit when battle has ended
    event BossBattleResult(
        address indexed account,
        uint256 indexed shipEntity,
        uint256 indexed bossEntity,
        uint256 battleEntity,
        uint256 newShipHealth,
        uint256 newBossHealth,
        uint256 damageDealt,
        uint256 damageTaken,
        bool isFinalBlow
    );

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     */
    function initialize(address gameRegistryAddress) public initializer {
        __GameRegistryConsumer_init(gameRegistryAddress, ID);
    }

    /**
     * @dev Returns cooldown timestamp for Account
     * @return timestamp epoch time in seconds when cooldown is refreshed
     */
    function getAccountCooldown(
        address account
    ) external view returns (uint32) {
        return
            ICooldownSystem(_getSystem(COOLDOWN_SYSTEM_ID)).getCooldown(
                EntityLibrary.addressToEntity(account),
                BOSS_BATTLE_COOLDOWN_ID
            );
    }

    /**
     * @dev Returns cooldown timestamp for Ship
     * @return timestamp epoch time in seconds when cooldown is refreshed
     */
    function getShipCooldown(
        uint256 shipEntity
    ) external view returns (uint32) {
        return
            ICooldownSystem(_getSystem(COOLDOWN_SYSTEM_ID)).getCooldown(
                shipEntity,
                BOSS_BATTLE_COOLDOWN_ID
            );
    }

    /**
     * @dev Returns an active battle if one exists
     * @param battleEntity identifier for the desired battle
     * @return battle a Battle struct containing data for a battle
     * @return isActive a boolean that is true if the battle is still active
     */
    function getActiveBattle(
        uint256 battleEntity
    ) external view returns (Battle memory, bool isActive) {
        Battle memory battle = _getBattle(battleEntity);
        // BattleEntity cooldown == current time is still before battle expires
        bool beforeCooldownTime = ICooldownSystem(
            _getSystem(COOLDOWN_SYSTEM_ID)
        ).isInCooldown(battle.battleEntity, BOSS_BATTLE_COOLDOWN_ID);
        // If battle exists AND current time is still before battle expires then isActive = true
        if (battle.battleEntity != 0 && beforeCooldownTime) {
            isActive = true;
        }
        return (battle, isActive);
    }

    /**
     * @dev Returns an active battle if one exists
     * @param account address to look up an active battle by
     * @return battle a Battle struct containing data for a battle
     * @return isActive a boolean that is true if the battle is still active
     */
    function getActiveBattleByAccount(
        address account
    ) external view returns (Battle memory, bool isActive) {
        Battle memory battle = _getBattle(_accountToBattleEntity[account]);
        // BattleEntity cooldown == current time is still before battle expires
        bool beforeCooldownTime = ICooldownSystem(
            _getSystem(COOLDOWN_SYSTEM_ID)
        ).isInCooldown(battle.battleEntity, BOSS_BATTLE_COOLDOWN_ID);
        // If battle exists AND current time is still before battle expires then isActive = true
        if (battle.battleEntity != 0 && beforeCooldownTime) {
            isActive = true;
        }
        return (battle, isActive);
    }

    /**
     * @dev Create a battle if it doesnt exist for this account
     * @param params Struct of StartBattleParams inputs
     * @return battleEntity Entity of the battle
     */
    function startBattle(
        StartBattleParams calldata params
    ) external nonReentrant whenNotPaused returns (uint256) {
        address account = _getPlayerAccount(_msgSender());

        // Clear any old record
        _deleteBattle(_accountToBattleEntity[account]);

        // Get Combatable for ship and boss
        ICombatable shipCombatable = ICombatable(
            _getSystem(SHIP_COMBATABLE_ID)
        );
        ICombatable bossCombatable = ICombatable(
            _getSystem(BOSS_COMBATABLE_ID)
        );

        // Check if combatants are capable of combat
        if (
            !shipCombatable.canAttack(
                account,
                params.shipEntity,
                params.shipOverloads
            )
        ) {
            revert InvalidEntity();
        }

        if (
            !bossCombatable.canBeAttacked(params.bossEntity, new uint256[](0))
        ) {
            revert InvalidEntity();
        }

        // Create battle and store in mapping; this kicks off a VRF request
        uint256 battleEntity = _createBattle(
            params.battleSeed,
            params.shipEntity,
            params.bossEntity,
            params.shipOverloads,
            new uint256[](0),
            shipCombatable,
            bossCombatable
        );

        // Revert if any cooldowns prevent combat from starting
        _requireValidCooldowns(account, params.shipEntity, battleEntity);

        // burn cannonballs?

        _accountToBattleEntity[account] = battleEntity;
        return battleEntity;
    }

    /**
     * @dev Resolves an active battle with validations
     * @param params Struct of EndBattleParams inputs
     */
    function endBattle(
        EndBattleParams calldata params
    ) external nonReentrant whenNotPaused {
        // Check account is executing their own battle || battle entity != 0
        address account = _getPlayerAccount(_msgSender());
        if (
            _accountToBattleEntity[account] != params.battleEntity ||
            params.battleEntity == 0
        ) {
            revert InvalidCallToEndBattle();
        }
        // Check if call to end-battle still within battle time limit
        if (
            !ICooldownSystem(_getSystem(COOLDOWN_SYSTEM_ID)).isInCooldown(
                params.battleEntity,
                BOSS_BATTLE_COOLDOWN_ID
            )
        ) {
            revert BattleExpired();
        }

        // Get Active battle
        Battle memory battle = _getBattle(params.battleEntity);

        if (
            params.moves.length >
            IGameGlobals(_getSystem(GAME_GLOBALS_ID)).getUint256(
                BOSS_BATTLE_MAX_MOVE_COUNT
            ) ||
            params.moves.length == 0
        ) {
            revert InvalidEndBattleParams();
        }

        ITraitsProvider traitsProvider = _traitsProvider();

        // Get ship starting health & boss starting health
        uint256 shipStartingHealth = battle.attackerCombatable.getCurrentHealth(
            battle.attackerEntity,
            traitsProvider
        );
        // Apply Health expertise
        shipStartingHealth = BattleLibrary.applyExpertiseHealthMod(
            traitsProvider,
            IGameGlobals(_getSystem(GAME_GLOBALS_ID)),
            shipStartingHealth,
            battle.attackerOverloads[0]
        );
        uint256 bossStartingHealth = battle.defenderCombatable.getCurrentHealth(
            battle.defenderEntity,
            traitsProvider
        );

        // Record the killing blow
        bool isFinalBlow;
        if (
            bossStartingHealth != 0 &&
            params.totalDamageDealt >= bossStartingHealth
        ) {
            isFinalBlow = true;
            bossEntityToFinalBlow[battle.defenderEntity] = FinalBlow(
                battle.attackerEntity,
                account
            );
        }

        // Simple threshold check
        if (
            !BattleLibrary.validateVersusResult(
                ValidateVersusResultParams(
                    battle.attackerEntity,
                    battle.defenderEntity,
                    battle.attackerOverloads[0],
                    params.totalDamageDealt,
                    params.moves,
                    AffinitySystem(_getSystem(AFFINITY_SYSTEM_ID)),
                    CoreMoveSystem(_getSystem(CORE_MOVE_SYSTEM_ID)),
                    ShipEquipment(_getSystem(SHIP_EQUIPMENT_ID)),
                    ITokenTemplateSystem(_getSystem(TOKEN_TEMPLATE_SYSTEM_ID)),
                    traitsProvider,
                    IGameGlobals(_getSystem(GAME_GLOBALS_ID))
                )
            )
        ) {
            revert InvalidEndBattleParams();
        }

        // Calculate full damage taken / damage dealt result, ignore if boss already dead & final attacks coming through
        // _validateEndBattleParamsFull()

        _updateBossBattleCount(
            account,
            battle.defenderEntity,
            params.totalDamageDealt
        );

        // TODO: decrease ship health when ship-repairs created
        // Emit results and set new health values of Boss & Ship
        emit BossBattleResult(
            account,
            battle.attackerEntity,
            battle.defenderEntity,
            params.battleEntity,
            shipStartingHealth,
            params.totalDamageDealt == 0
                ? bossStartingHealth
                : battle.defenderCombatable.decreaseHealth(
                    battle.defenderEntity,
                    params.totalDamageDealt
                ),
            params.totalDamageDealt,
            params.totalDamageTaken,
            isFinalBlow
        );

        // Clear battle record
        _clearBattleEntity(account);
    }

    /** INTERNAL **/

    // /**
    //  * @dev Calculate full set of damage taken & damage dealt results
    //  * @param params Set of move ids the ship made in order
    //  */
    // function _validateEndBattleParamsFull(
    //     ValidateFullParams memory params
    // ) internal view returns (uint256, uint256) {
    //     // Calculate damage taken and damage dealt results to compare after

    //     // Declare all loop variables outside loop
    //     AffinitySystem affinitySystem = AffinitySystem(
    //         _getSystem(AFFINITY_SYSTEM_ID)
    //     );

    //     uint256 tempDamageFirst;
    //     uint256 tempDamageSecond;

    //     Combatant[2] memory combatants;
    //     Combatant memory shipCombatant;
    //     shipCombatant.health = params.shipHealth;
    //     Combatant memory bossCombatant;
    //     bossCombatant.health = params.bossHealth;
    //     // Loop through moves
    //     for (uint256 i = 0; i < params.moves.length; ++i) {
    //         // Get newly calculated ship stats
    //         shipCombatant.stats = params
    //             .battle
    //             .attackerCombatable
    //             .getCombatStats(
    //                 params.battle.attackerEntity,
    //                 0,
    //                 params.moves[i],
    //                 params.battle.attackerOverloads
    //             );
    //         // Calculate player roll
    //         shipCombatant.roll = uint256(
    //             keccak256(
    //                 abi.encodePacked(
    //                     params.battleSeed + i * 2 + uint160(params.account)
    //                 )
    //             )
    //         );

    //         // Calculate boss roll
    //         bossCombatant.roll = uint256(
    //             keccak256(
    //                 abi.encodePacked(
    //                     params.battleSeed + i * 3 + uint160(params.account)
    //                 )
    //             )
    //         );
    //         // Get newly calculated boss stats + Calculate boss-move-roll
    //         bossCombatant.stats = params
    //             .battle
    //             .defenderCombatable
    //             .getCombatStats(
    //                 params.battle.defenderEntity,
    //                 uint256(
    //                     keccak256(
    //                         abi.encodePacked(
    //                             params.battleSeed +
    //                                 i *
    //                                 1 +
    //                                 uint160(params.account)
    //                         )
    //                     )
    //                 ),
    //                 0,
    //                 params.battle.defenderOverloads
    //             );

    //         // initialize Combatant[] with boss first
    //         combatants = [bossCombatant, shipCombatant];
    //         // Reorder if ship faster or equal
    //         if (combatants[1].stats.speed >= combatants[0].stats.speed) {
    //             combatants = [shipCombatant, bossCombatant];
    //         }
    //         // Resolve faster attacker
    //         tempDamageFirst = _resolveAttack(
    //             combatants[0].roll,
    //             combatants[0],
    //             combatants[1],
    //             affinitySystem
    //         );

    //         // Resolve slower attacker
    //         tempDamageSecond = _resolveAttack(
    //             combatants[1].roll,
    //             combatants[1],
    //             combatants[0],
    //             affinitySystem
    //         );
    //         // Handle damage done by faster attacker & reducing slower attackers health
    //         if (tempDamageFirst >= combatants[1].health) {
    //             combatants[1].health = 0;
    //         } else {
    //             combatants[1].health -= tempDamageFirst;
    //         }
    //         combatants[0].totalDamageCalculated += tempDamageFirst;
    //         if (combatants[1].health == 0) {
    //             break;
    //         }
    //         // Handle damage done by slower attacker & reducing faster attackers health
    //         if (tempDamageSecond >= combatants[0].health) {
    //             combatants[0].health = 0;
    //         } else {
    //             combatants[0].health -= tempDamageSecond;
    //         }
    //         combatants[1].totalDamageCalculated += tempDamageSecond;
    //         if (combatants[0].health == 0) {
    //             break;
    //         }
    //     }
    //     // If boss is now dead & ship dealt killing blow, return
    //     if (
    //         bossCombatant.health == 0 && shipCombatant.totalDamageCalculated > 0
    //     ) {
    //         return (
    //             bossCombatant.totalDamageCalculated,
    //             shipCombatant.totalDamageCalculated
    //         );
    //     }
    //     // totalDamageTaken not matching calculated value of total damage boss inflicted, revert
    //     if (params.totalDamageTaken != bossCombatant.totalDamageCalculated) {
    //         revert InvalidDamageDealt();
    //     }
    //     // totalDamageDealt not matching calculated value of total damage ship inflicted, revert
    //     if (params.totalDamageDealt != shipCombatant.totalDamageCalculated) {
    //         revert InvalidDamageTaken();
    //     }
    //     return (
    //         bossCombatant.totalDamageCalculated,
    //         shipCombatant.totalDamageCalculated
    //     );
    // }

    // function _resolveAttack(
    //     uint256 accuracyRoll,
    //     Combatant memory fasterCombatant,
    //     Combatant memory slowerCombatant,
    //     AffinitySystem affinitySystem
    // ) internal view returns (uint256 damageDone) {
    //     // Cast roll to int256 and % 200 to get D200
    //     int256 roll = SafeCast.toInt256(
    //         (accuracyRoll % BOSS_COMBAT_ACCURACY_DICE_ROLL) + 1
    //     ) * 1 gwei;
    //     if (
    //         fasterCombatant.stats.accuracy + roll >
    //         slowerCombatant.stats.evasion
    //     ) {
    //         damageDone =
    //             (uint64(fasterCombatant.stats.damage) *
    //                 affinitySystem.getDamageModifier(
    //                     fasterCombatant.stats.affinity,
    //                     slowerCombatant.stats.affinity
    //                 )) /
    //             10000;
    //     }
    // }

    /**
     * @dev Put a cooldown on Account, Ship, and BattleEntity (id)
     */
    function _requireValidCooldowns(
        address account,
        uint256 shipEntity,
        uint256 battleEntity
    ) internal {
        IGameGlobals gameGlobals = IGameGlobals(_getSystem(GAME_GLOBALS_ID));
        ICooldownSystem cooldown = ICooldownSystem(
            _getSystem(COOLDOWN_SYSTEM_ID)
        );

        uint32 bossBattleCooldownTime = uint32(
            gameGlobals.getUint256(BOSS_BATTLE_COOLDOWN_TIME)
        );

        // Apply cooldown on account, revert if still in cooldown
        if (
            cooldown.updateAndCheckCooldown(
                EntityLibrary.addressToEntity(account),
                BOSS_BATTLE_COOLDOWN_ID,
                bossBattleCooldownTime
            )
        ) {
            revert AccountStillInCooldown();
        }

        // Apply cooldown on nft, revert if still in cooldown
        if (
            cooldown.updateAndCheckCooldown(
                shipEntity,
                BOSS_BATTLE_COOLDOWN_ID,
                bossBattleCooldownTime
            )
        ) {
            revert NftStillInCooldown();
        }

        // Apply cooldown on battle id, fails if active
        if (
            cooldown.updateAndCheckCooldown(
                battleEntity,
                BOSS_BATTLE_COOLDOWN_ID,
                uint32(gameGlobals.getUint256(BOSS_BATTLE_TIME_LIMIT))
            )
        ) {
            revert ActiveBattleInProgress(battleEntity);
        }
    }

    function _getBattleEntity(address account) internal view returns (uint256) {
        return _accountToBattleEntity[account];
    }

    function _clearBattleEntity(address account) internal {
        _deleteBattle(_accountToBattleEntity[account]);
        delete (_accountToBattleEntity[account]);
    }

    /**
     * Uses the counting system to update the stats for the player in the counting system.
     */
    function _updateBossBattleCount(
        address account,
        uint256 bossEntity,
        uint256 totalDamageDealt
    ) internal {
        ICountingSystem countingSystem = ICountingSystem(
            _getSystem(COUNTING_SYSTEM_ID)
        );
        uint256 accountEntity = EntityLibrary.addressToEntity(account);
        countingSystem.incrementCount(
            accountEntity,
            uint256(
                keccak256(
                    abi.encode(
                        COUNTING_TYPE_SINGLE_BOSS_DAMAGE_DEALT,
                        bossEntity
                    )
                )
            ),
            totalDamageDealt
        );
        countingSystem.incrementCount(
            accountEntity,
            COUNTING_TYPE_ALL_BOSS_DAMAGE_DEALT,
            totalDamageDealt
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ID as BOSS_SPAWN_ID} from "./BossSpawn.sol";
import {IMoveSystem, ID as CORE_MOVE_SYSTEM_ID} from "./IMoveSystem.sol";
import {EntityLibrary} from "../core/EntityLibrary.sol";
import {ITokenTemplateSystem, ID as TOKEN_TEMPLATE_SYSTEM_ID} from "../tokens/ITokenTemplateSystem.sol";
import {Combatable} from "./Combatable.sol";
import {CombatStats} from "./ICombatable.sol";
import {GAME_LOGIC_CONTRACT_ROLE, ELEMENTAL_AFFINITY_TRAIT_ID, BOSS_START_TIME_TRAIT_ID, BOSS_END_TIME_TRAIT_ID} from "../Constants.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.bosscombatable"));

contract BossCombatable is Combatable {
    /** ERRORS **/

    /// @notice Invalid Boss contract
    error InvalidBossEntity();

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     */
    function initialize(address gameRegistryAddress) public initializer {
        __GameRegistryConsumer_init(gameRegistryAddress, ID);
    }

    /**
     * @dev Function returns CombatStats with calculations from CoreMoveSystem + Roll + Overloads applied to them
     * @param entityId A packed tokenId and Address
     * @param roll VRF result[0]
     * @return CombatStats An enum returning the stats that can be used for combat.
     */
    function getCombatStats(
        uint256 entityId,
        uint256 roll,
        uint256,
        uint256[] calldata
    ) external view override returns (CombatStats memory) {
        (address nftContract, uint256 nftTokenId) = EntityLibrary.entityToToken(
            entityId
        );

        // Get base CombatStats for this Boss entityId
        CombatStats memory stats = _getCombatStats(entityId);

        // Pick Boss random move (1-6 inclusive) using roll
        uint256 moveId = (roll % 6) + 1;
        int256[] memory moveMods = IMoveSystem(_getSystem(CORE_MOVE_SYSTEM_ID))
            .getCombatModifiers(moveId);

        // Calculate new combat stats taking into account move modifiers
        return
            CombatStats({
                damage: stats.damage + int64(moveMods[0]),
                evasion: stats.evasion + int64(moveMods[1]),
                speed: stats.speed + int64(moveMods[2]),
                accuracy: stats.accuracy + int64(moveMods[3]),
                // For now, we cannot modify combat stat health with moves
                // This requires game design decisions before it is implemented
                health: stats.health,
                // Pull affinity from template system
                affinity: uint64(
                    ITokenTemplateSystem(_getSystem(TOKEN_TEMPLATE_SYSTEM_ID))
                        .getTraitUint256(
                            nftContract,
                            nftTokenId,
                            ELEMENTAL_AFFINITY_TRAIT_ID
                        )
                ),
                move: uint64(moveId)
            });
    }

    /**
     * @dev Decrease the current_health trait of entityId
     * @param entityId A packed tokenId and Address
     * @param amount amount to reduce entityIds health
     * @return newHealth New current health of entityId after damage is taken.
     */
    function decreaseHealth(
        uint256 entityId,
        uint256 amount
    ) external override onlyRole(GAME_LOGIC_CONTRACT_ROLE) returns (uint256) {
        return _decreaseHealth(entityId, amount);
    }

    /**
     * @dev Check if Boss entityId can be attacked by checking if boss active/inactive, then check health
     * @param entityId A packed tokenId and Address
     * @return boolean If entityId can be attacked.
     */
    function canBeAttacked(
        uint256 entityId,
        uint256[] calldata
    ) external view override returns (bool) {
        // Unpack
        (address nftContract, uint256 nftTokenId) = EntityLibrary.entityToToken(
            entityId
        );

        if (nftContract != _getSystem(BOSS_SPAWN_ID)) {
            revert InvalidBossEntity();
        }

        ITokenTemplateSystem tokenTemplateSystem = ITokenTemplateSystem(
            _getSystem(TOKEN_TEMPLATE_SYSTEM_ID)
        );
        // Check Boss start time and end time
        if (
            block.timestamp <=
            tokenTemplateSystem.getTraitUint256(
                nftContract,
                nftTokenId,
                BOSS_START_TIME_TRAIT_ID
            ) ||
            block.timestamp >
            tokenTemplateSystem.getTraitUint256(
                nftContract,
                nftTokenId,
                BOSS_END_TIME_TRAIT_ID
            )
        ) {
            return false;
        }

        // Check Boss health == 0, if yes return false, else return true
        return !_isHealthZero(nftContract, nftTokenId);
    }

    /**
     * @dev Bosses can never initiate attack
     * @return boolean If an entity can attack
     */
    function canAttack(
        address,
        uint256,
        uint256[] calldata
    ) external pure override returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {GameRegistryConsumerUpgradeable} from "../GameRegistryConsumerUpgradeable.sol";
import {ITokenTemplateSystem, ID as TOKEN_TEMPLATE_SYSTEM_ID} from "../tokens/ITokenTemplateSystem.sol";
import {BOSS_TYPE_TRAIT_ID, CURRENT_HEALTH_TRAIT_ID, HEALTH_TRAIT_ID, MINTER_ROLE} from "../Constants.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.bossspawn"));

/**
 * @title BossSpawn
 *
 * Spawn Boss
 */
contract BossSpawn is GameRegistryConsumerUpgradeable {
    error InvalidBoss(uint256 templateId);

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     */
    function initialize(address gameRegistryAddress) public initializer {
        __GameRegistryConsumer_init(gameRegistryAddress, ID);
    }

    /**
     * Spawn Boss
     * @dev Could make this a batch spawn? takes in uint256[]
     * @param templateId is ID from SoT and also Boss ID
     */
    function spawnBoss(uint256 templateId) external onlyRole(MINTER_ROLE) {
        ITokenTemplateSystem tokenTemplateSystem = ITokenTemplateSystem(
            _getSystem(TOKEN_TEMPLATE_SYSTEM_ID)
        );

        if (!tokenTemplateSystem.exists(templateId)) {
            revert InvalidBoss(templateId);
        }

        // Set World Boss data from SoT TokenTemplate
        tokenTemplateSystem.setTemplate(address(this), templateId, templateId);

        // Check that is a boss template
        if (
            tokenTemplateSystem.hasTrait(
                address(this),
                templateId,
                BOSS_TYPE_TRAIT_ID
            ) == false
        ) {
            revert InvalidBoss(templateId);
        }

        int256 maxHealth = tokenTemplateSystem.getTraitInt256(
            address(this),
            templateId,
            HEALTH_TRAIT_ID
        );
        _traitsProvider().setTraitUint256(
            address(this),
            templateId,
            CURRENT_HEALTH_TRAIT_ID,
            SafeCast.toUint256(maxHealth)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ACCURACY_TRAIT_ID, CURRENT_HEALTH_TRAIT_ID, DAMAGE_TRAIT_ID, EVASION_TRAIT_ID, SPEED_TRAIT_ID, GAME_LOGIC_CONTRACT_ROLE} from "../Constants.sol";
import {EntityLibrary} from "../core/EntityLibrary.sol";
import {ITraitsProvider} from "../interfaces/ITraitsProvider.sol";
import {ITokenTemplateSystem, ID as TOKEN_TEMPLATE_SYSTEM_ID} from "../tokens/ITokenTemplateSystem.sol";
import {GameRegistryConsumerUpgradeable} from "../GameRegistryConsumerUpgradeable.sol";

import {CombatStats, ICombatable} from "./ICombatable.sol";

abstract contract Combatable is GameRegistryConsumerUpgradeable, ICombatable {
    /**
     * @dev Internal func returns base CombatStats for entityId : affinity pulled separately
     */
    function _getCombatStats(
        uint256 entityId
    ) internal view returns (CombatStats memory) {
        ITokenTemplateSystem tokenTemplateSystem = ITokenTemplateSystem(
            _getSystem(TOKEN_TEMPLATE_SYSTEM_ID)
        );
        // Extract contract address and token ID from entityId
        (address nftContract, uint256 nftTokenId) = EntityLibrary.entityToToken(
            entityId
        );

        return
            CombatStats({
                accuracy: int64(
                    tokenTemplateSystem.getTraitInt256(
                        nftContract,
                        nftTokenId,
                        ACCURACY_TRAIT_ID
                    )
                ),
                damage: int64(
                    tokenTemplateSystem.getTraitInt256(
                        nftContract,
                        nftTokenId,
                        DAMAGE_TRAIT_ID
                    )
                ),
                evasion: int64(
                    tokenTemplateSystem.getTraitInt256(
                        nftContract,
                        nftTokenId,
                        EVASION_TRAIT_ID
                    )
                ),
                health: uint64(
                    _traitsProvider().getTraitUint256(
                        nftContract,
                        nftTokenId,
                        CURRENT_HEALTH_TRAIT_ID
                    )
                ),
                speed: int64(
                    tokenTemplateSystem.getTraitInt256(
                        nftContract,
                        nftTokenId,
                        SPEED_TRAIT_ID
                    )
                ),
                affinity: 0, // Caller must set
                move: 0 // Caller may set
            });
    }

    /**
     * @dev Helper func return current health of entityId without redeclaring TraitsProvider
     */
    function getCurrentHealth(
        uint256 entityId,
        ITraitsProvider traitsProvider
    ) external view override returns (uint256) {
        // Extract contract address and token ID from entityId
        (address nftContract, uint256 nftTokenId) = EntityLibrary.entityToToken(
            entityId
        );
        return
            traitsProvider.getTraitUint256(
                nftContract,
                nftTokenId,
                CURRENT_HEALTH_TRAIT_ID
            );
    }

    /**
     * @dev Internal func decrease health of entityId
     */
    function _decreaseHealth(
        uint256 entityId,
        uint256 amount
    ) internal returns (uint256 newHealth) {
        // Extract contract address and token ID from entityId
        (address nftContract, uint256 nftTokenId) = EntityLibrary.entityToToken(
            entityId
        );

        // Get current health from TraitsProvider
        uint256 currentHealth = _traitsProvider().getTraitUint256(
            nftContract,
            nftTokenId,
            CURRENT_HEALTH_TRAIT_ID
        );
        // Calculate
        if (amount >= currentHealth) {
            newHealth = 0;
        } else {
            newHealth = currentHealth - amount;
        }
        // Update current health in TraitsProvider
        _traitsProvider().setTraitUint256(
            nftContract,
            nftTokenId,
            CURRENT_HEALTH_TRAIT_ID,
            newHealth
        );
    }

    /**
     * @dev Internal func Return true if entityId health == 0
     */
    function _isHealthZero(
        address nftContract,
        uint256 nftTokenId
    ) internal view returns (bool) {
        // Check if entityId health is zero, if yes return true, else return false
        return
            _traitsProvider().getTraitUint256(
                nftContract,
                nftTokenId,
                CURRENT_HEALTH_TRAIT_ID
            ) == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";

import {GAME_LOGIC_CONTRACT_ROLE, RANDOMIZER_ROLE} from "../Constants.sol";
import {ICooldownSystem, ID as COOLDOWN_SYSTEM_ID} from "../cooldown/ICooldownSystem.sol";
import {EntityLibrary} from "../core/EntityLibrary.sol";
import {GameRegistryConsumerUpgradeable} from "../GameRegistryConsumerUpgradeable.sol";

import {ICombatable} from "./ICombatable.sol";

/**
 * Contains data necessary for executing a battle
 */
struct Battle {
    uint256 battleEntity;
    uint256 battleSeed;
    uint256 attackerEntity;
    uint256 defenderEntity;
    uint256[] attackerOverloads;
    uint256[] defenderOverloads;
    ICombatable attackerCombatable;
    ICombatable defenderCombatable;
}

/**
 * @title Core Battle System
 *
 * @dev Simple contract to manage initialization and conclusion of battles
 * @dev Leveraging shared event formats for battle may allow us to avoid gql reindexing
 */
abstract contract CoreBattleSystem is GameRegistryConsumerUpgradeable {
    using Counters for Counters.Counter;

    /** MEMBERS */

    /// @notice Generate a new Battle Id for each new battle created
    Counters.Counter private _latestBattleId;

    /// @notice Mapping to store battleEntity > Battle struct
    mapping(uint256 => Battle) private _battles;

    /// @notice Mapping to store VRF requestId > battleEntity
    mapping(uint256 => uint256) private _requestToBattleEntity;

    /** EVENTS */

    // TODO: consider including ALL data that is required for indexing and for client
    /// @notice emitted when anytime battle + round is started
    event BattlePending(
        uint256 indexed battleEntity,
        uint256 indexed attackerEntity,
        uint256 indexed defenderEntity,
        uint256[] attackerOverloads,
        uint256[] defenderOverloads
    );

    // TODO: consider including ALL data that is required for indexing and for client
    /// @notice emitted when anytime battle + round is started
    event BattleStarted(uint256 indexed battleEntity, uint256 battleSeed);

    // TODO: consider including ALL data that is required for indexing and for client
    /// @notice emitted when anytime battle + round is over
    event BattleEnded(uint256 indexed battleEntity);

    /** ERRORS **/

    /// @notice Required functionality not implemented
    error NotImplemented(string message);

    /**
     * @dev callback executed only in the VRF oracle to resolve randomness for a battle
     * @param requestId identifier for the VRF request
     * @param randomWords an array containing (currently only 1) randomized strings
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external override onlyRole(RANDOMIZER_ROLE) {
        // Store random battle seed
        Battle storage battle = _battles[_requestToBattleEntity[requestId]];

        // Update battle only if it exists; it may have been deleted already
        if (battle.battleEntity != 0) {
            battle.battleSeed = randomWords[0];

            // Emit event
            emit BattleStarted(battle.battleEntity, battle.battleSeed);
        }

        // Clear VRF
        delete _requestToBattleEntity[requestId];
    }

    /**
     * @dev Initializes a battle and kicks off a VRF request for the random battle seed
     * @param attackerEntity A packed address and token ID for the attacker
     * @param defenderEntity A packed address and token ID for the defender
     * @param attackerOverloads Array of entities used to modify combat for the attacker
     * @param defenderOverloads Array of entities used to modify combat for the defender
     * @return battle data initialized for a new battle
     */
    function _createBattle(
        uint256 battleSeed,
        uint256 attackerEntity,
        uint256 defenderEntity,
        uint256[] memory attackerOverloads,
        uint256[] memory defenderOverloads,
        ICombatable attackerCombatable,
        ICombatable defenderCombatable
    ) internal returns (uint256) {
        // Create new battle id
        _latestBattleId.increment();
        uint256 battleEntity = _getBattleEntity(_latestBattleId.current());

        // Initialize battle
        _battles[battleEntity] = Battle({
            battleEntity: battleEntity,
            attackerEntity: attackerEntity,
            defenderEntity: defenderEntity,
            attackerOverloads: attackerOverloads,
            defenderOverloads: defenderOverloads,
            attackerCombatable: attackerCombatable,
            defenderCombatable: defenderCombatable,
            // Instead of VRF callback, store battleSeed from client.
            // This is less secure because seed is unverified, but a better UX.
            battleSeed: battleSeed
        });

        // Request VRF randomness for battle
        // uint256 requestId = _requestRandomWords(1);
        // _requestToBattleEntity[requestId] = battleEntity;

        // Emit event
        emit BattlePending(
            battleEntity,
            attackerEntity,
            defenderEntity,
            attackerOverloads,
            defenderOverloads
        );

        return battleEntity;
    }

    /**
     * @dev Deletes a battle from storage and emits a BattleEnded event
     * @param battleEntity identifier for the desired battle to delete
     */
    function _deleteBattle(uint256 battleEntity) internal {
        delete _battles[battleEntity];
    }

    /**
     * @dev Returns a battle
     * @param battleEntity identifier for the desired battle to retrieve
     * @return battle data pertaining to the battle id if exists
     */
    function _getBattle(
        uint256 battleEntity
    ) internal view returns (Battle memory) {
        return _battles[battleEntity];
    }

    /**
     * @dev Returns a battle entity given the battle id
     * @param battleId internal battle id used to produce the battle entity
     * @return battleEntity unique global identifier given a battleId
     */
    function _getBattleEntity(
        uint256 battleId
    ) internal view returns (uint256) {
        return EntityLibrary.tokenToEntity(address(this), battleId);
    }

    /**
     * @dev provides access to the internal battle id counter, useful for testing
     */
    function _getCurrentBattleId() internal view returns (uint256) {
        return _latestBattleId.current();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {MINTER_ROLE} from "../Constants.sol";
import {IGameGlobals, ID as GAME_GLOBALS_ID} from "../gameglobals/IGameGlobals.sol";
import {GameRegistryConsumerUpgradeable} from "../GameRegistryConsumerUpgradeable.sol";
import {IMoveSystem, ID} from "./IMoveSystem.sol";

// Core move set
uint256 constant POWER_STRIKE_ID = uint256(
    keccak256("coremovesystem.move.powerstrike")
);
uint256 constant NORMAL_STRIKE_ID = uint256(
    keccak256("coremovesystem.move.normalstrike")
);
uint256 constant EVASIVE_ACTION_ID = uint256(
    keccak256("coremovesystem.move.evasiveaction")
);
uint256 constant CAREFUL_AIM_ID = uint256(
    keccak256("coremovesystem.move.carefulaim")
);
uint256 constant DIRTY_TACTICS_ID = uint256(
    keccak256("coremovesystem.move.dirtytactics")
);
uint256 constant QUICK_SHOT_ID = uint256(
    keccak256("coremovesystem.move.quickshot")
);

enum MoveTypes {
    UNDEFINED,
    POWER_STRIKE,
    NORMAL_STRIKE,
    EVASIVE_ACTION,
    CAREFUL_AIM,
    DIRTY_TACTICS,
    QUICK_SHOT,
    length // This must remain as last member in enum; currently == 7
}

/**
 * @title CoreMoveSystem
 *
 * Supplies CombatStats modifiers given a move selection.
 * Currently all opponents share the same move set.
 */
contract CoreMoveSystem is GameRegistryConsumerUpgradeable, IMoveSystem {
    /** MEMBERS **/

    mapping(uint256 => uint256) _moveIdToGlobal;

    /** ERRORS **/

    /// @notice Invalid moveId to set to mapping
    error InvalidMoveId(uint256 moveId);

    /// @notice Invalid moveIds array to set to mapping
    error InvalidMoveIds();

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     */
    function initialize(address gameRegistryAddress) public initializer {
        __GameRegistryConsumer_init(gameRegistryAddress, ID);

        _moveIdToGlobal[uint256(MoveTypes.POWER_STRIKE)] = POWER_STRIKE_ID;
        _moveIdToGlobal[uint256(MoveTypes.NORMAL_STRIKE)] = NORMAL_STRIKE_ID;
        _moveIdToGlobal[uint256(MoveTypes.EVASIVE_ACTION)] = EVASIVE_ACTION_ID;
        _moveIdToGlobal[uint256(MoveTypes.CAREFUL_AIM)] = CAREFUL_AIM_ID;
        _moveIdToGlobal[uint256(MoveTypes.DIRTY_TACTICS)] = DIRTY_TACTICS_ID;
        _moveIdToGlobal[uint256(MoveTypes.QUICK_SHOT)] = QUICK_SHOT_ID;
    }

    /**
     * @dev Takes a moveId and returns stat modifiers in CombatStats format
     * @param moveId Move identifier to lookup modifiers for
     * @return int256[] Stat modifiers for provided moveId
     */
    function getCombatModifiers(
        uint256 moveId
    ) external view override returns (int256[] memory) {
        // Modifier order determined in SoT document.
        return
            IGameGlobals(_getSystem(GAME_GLOBALS_ID)).getInt256Array(
                _moveIdToGlobal[moveId]
            );
    }

    /**
     * @dev Map an array of moveIds to every valid move
     * @param moveIds An array of moveIds like: [1,2,3,4,5,6]
     */
    function setAllMoves(
        uint256[] calldata moveIds
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        if (moveIds.length != uint256(MoveTypes.length) - 1) {
            revert InvalidMoveIds();
        }

        // Default order of moves defined in SoT
        uint256[6] memory MOVE_IDS = [
            POWER_STRIKE_ID,
            NORMAL_STRIKE_ID,
            EVASIVE_ACTION_ID,
            CAREFUL_AIM_ID,
            DIRTY_TACTICS_ID,
            QUICK_SHOT_ID
        ];

        // For each provided moveId value, map it to a known move in SoT order
        // Example: [1,2,3,4,5,6] would set the default move mappings
        uint256 moveId;
        for (uint8 i = 0; i < moveIds.length; i++) {
            moveId = moveIds[i];

            // Ensure moveId is not MoveTypes.UNDEFINED or out of range
            if (moveId >= uint256(MoveTypes.length) || moveId == 0) {
                revert InvalidMoveId(moveId);
            }

            // Each moveId in array will be mapped to a move constant in expected order
            _moveIdToGlobal[moveId] = MOVE_IDS[i];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ITraitsProvider} from "../interfaces/ITraitsProvider.sol";

// NOTE: Must keep IMoveSystem globals + SoT in sync with any changes to CombatStats
struct CombatStats {
    int64 damage;
    int64 evasion;
    int64 speed;
    int64 accuracy;
    uint64 health;
    uint64 affinity;
    uint64 move;
}

/**
 * @title ICombatable
 *
 * ICombatable is an interface for defining how different NFTs can have combat with one an other.
 */
interface ICombatable {
    /**
     * @dev Function returns CombatStats with calculations from CoreMoveSystem + Roll + Overloads applied to them
     * @param entityId A packed tokenId and Address
     * @param roll VRF result[0]
     * @param moveId A Uint of what the move the Attack is doing
     * @param overloads An optional array of overload NFTs (if there is an another NFT on the boat)
     * @return CombatStats newly calculated CombatStats
     */
    function getCombatStats(
        uint256 entityId,
        uint256 roll,
        uint256 moveId,
        uint256[] calldata overloads
    ) external view returns (CombatStats memory);

    /**
     * @dev Decrease the current_health trait of entityId
     * @param entityId A packed tokenId and Address
     * @param amount amount to reduce entityIds health
     * @return newHealth New current health of entityId after damage is taken
     */
    function decreaseHealth(
        uint256 entityId,
        uint256 amount
    ) external returns (uint256 newHealth);

    /**
     * @dev Check if entityId can be attacked by checking its health, if boss then check if active/inactive
     * @param entityId A packed tokenId and Address
     * @param overloads An optional array of overload NFTs (if there is an another NFT on the boat)
     * @return boolean if entityId can be attacked
     */
    function canBeAttacked(
        uint256 entityId,
        uint256[] calldata overloads
    ) external view returns (bool);

    /**
     * @dev Check if entityId health > 0 && caller is owner of entityId && owner of overloads
     * @param caller Address of msg.sender : used for checking if caller is owner of entityId & overloads
     * @param entityId A packed tokenId and Address
     * @param overloads An optional array of overload NFTs (if there is an another NFT on the boat)
     * @return boolean If the boss can attack
     */
    function canAttack(
        address caller,
        uint256 entityId,
        uint256[] calldata overloads
    ) external view returns (bool);

    /**
     * @dev Helper func return current health of entityId without redeclaring TraitsProvider
     */
    function getCurrentHealth(
        uint256 entityId,
        ITraitsProvider traitsProvider
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

uint256 constant ID = uint256(keccak256("game.piratenation.coremovesystem"));

/**
 * @title IMoveSystem
 * @dev NOT IN USE YET; HERE FOR REFERENCE
 *
 * IMoveSystem is an interface for defining and accessing combatant moves.
 */
interface IMoveSystem {
    /**
     * @dev Takes a moveId and returns stat modifiers for CombatStats
     * @dev Modifier order determined in SoT document
     * @param moveId move identifier to lookup modifiers for
     * @return CombatStats stat modifiers for provided moveId
     */
    function getCombatModifiers(
        uint256 moveId
    ) external view returns (int256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {GAME_LOGIC_CONTRACT_ROLE, ELEMENTAL_AFFINITY_TRAIT_ID} from "../Constants.sol";
import {EntityLibrary} from "../core/EntityLibrary.sol";
import {BattleLibrary} from "./BattleLibrary.sol";
import {ShipEquipment, ID as SHIP_EQUIPMENT_ID} from "../equipment/ShipEquipment.sol";
import {ID as PIRATE_NFT_ID} from "../tokens/PirateNFTL2.sol";
import {IShipNFT} from "../tokens/shipnft/IShipNFT.sol";
import {ID as SHIP_NFT_ID} from "../tokens/shipnft/ShipNFT.sol";
import {IGameGlobals, ID as GAME_GLOBALS_ID} from "../gameglobals/IGameGlobals.sol";

import {CombatStats, Combatable} from "./Combatable.sol";
import {CoreMoveSystem, ID as CORE_MOVE_SYSTEM_ID} from "./CoreMoveSystem.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.shipcombatable"));

contract ShipCombatable is Combatable {
    /** ERRORS **/

    /// @notice Invalid Ship contract
    error InvalidShipEntity();

    /// @notice Invalid Pirate contract
    error InvalidPirateEntity(address, address);

    /// @notice Ship combat stats require a pirate captain
    error MissingPirateEntity();

    /// @notice Ship attacks can only be initiated by token owner
    error NotOwner(uint256 entityId);

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     */
    function initialize(address gameRegistryAddress) public initializer {
        __GameRegistryConsumer_init(gameRegistryAddress, ID);
    }

    /**
     * @dev Calculates ships combat stats from the nft, template, equipment, and boarded pirate
     * @param entityId A packed tokenId and Address of a Ship NFT
     * @param moveId A Uint of what the move the Attack is doing
     * @param overloads An optional array of overload NFTs (if there is an another NFT on the boat)
     * @return CombatStats An enum returning the stats that can be used for combat.
     */
    function getCombatStats(
        uint256 entityId,
        uint256,
        uint256 moveId,
        uint256[] calldata overloads
    ) external view override returns (CombatStats memory) {
        if (overloads.length != 1) {
            revert MissingPirateEntity();
        }

        (address pirateContract, uint256 pirateTokenId) = EntityLibrary
            .entityToToken(overloads[0]);

        CombatStats memory stats = _getCombatStats(entityId);

        // Retrieve combat stat modifiers from move system
        int256[] memory moveMods = CoreMoveSystem(
            _getSystem(CORE_MOVE_SYSTEM_ID)
        ).getCombatModifiers(moveId);

        // Retrieve combat stat modifiers from equipment
        int256[] memory equipmentMods = ShipEquipment(
            _getSystem(SHIP_EQUIPMENT_ID)
        ).getCombatModifiers(entityId);

        // Apply expertise modifiers
        stats = BattleLibrary.applyExpertiseToCombatStats(
            _traitsProvider(),
            IGameGlobals(_getSystem(GAME_GLOBALS_ID)),
            stats,
            overloads[0]
        );

        return
            CombatStats({
                damage: stats.damage +
                    int64(moveMods[0]) +
                    int64(equipmentMods[0]),
                evasion: stats.evasion +
                    int64(moveMods[1]) +
                    int64(equipmentMods[1]),
                speed: stats.speed +
                    int64(moveMods[2]) +
                    int64(equipmentMods[2]),
                accuracy: stats.accuracy +
                    int64(moveMods[3]) +
                    int64(equipmentMods[3]),
                // For now, we cannot modify combat stat health with moves
                // This requires game design decisions before it is implemented
                health: stats.health,
                // Get affinity from Pirate captain
                affinity: uint64(
                    _traitsProvider().getTraitUint256(
                        pirateContract,
                        pirateTokenId,
                        ELEMENTAL_AFFINITY_TRAIT_ID
                    )
                ),
                move: uint64(moveId)
            });
    }

    /**
     * @dev Decrease the current_health trait of entityId
     * @param entityId A packed tokenId and Address of an NFT
     * @param amount The damage that should be deducted from an NFT's health
     * @return newHealth The health left after damage is taken
     */
    function decreaseHealth(
        uint256 entityId,
        uint256 amount
    ) external override onlyRole(GAME_LOGIC_CONTRACT_ROLE) returns (uint256) {
        return _decreaseHealth(entityId, amount);
    }

    /**
     * @dev Check if ship is open to attack
     * @return boolean If the ship can be attacked
     */
    function canBeAttacked(
        uint256,
        uint256[] calldata
    ) external pure override returns (bool) {
        // For now, ships cannot be attacked -- PVP coming soon TM.
        return false;
    }

    /**
     * @dev Check if ship is capable of attacking
     * @param entityId A packed tokenId and Address of an NFT
     * @param caller address of msg.sender : used for checking if caller is owner of entityId & overloads
     * @param overloads An optional array of overload NFTs (if there is an another NFT on the boat)
     * @return boolean If the ship can attack
     */
    function canAttack(
        address caller,
        uint256 entityId,
        uint256[] calldata overloads
    ) external view override returns (bool) {
        if (overloads.length == 0) {
            revert MissingPirateEntity();
        }

        // Extract contract address and token ID from pirate
        (address contractAddress, uint256 tokenId) = EntityLibrary
            .entityToToken(overloads[0]);

        address pirateNFTAddr = _getSystem(PIRATE_NFT_ID);
        if (contractAddress != pirateNFTAddr) {
            revert InvalidPirateEntity(contractAddress, pirateNFTAddr);
        }

        // Check pirate NFT owned by caller
        if (caller != IERC721(contractAddress).ownerOf(tokenId)) {
            revert NotOwner(overloads[0]);
        }

        // Extract contract address and token ID from entityId
        (contractAddress, tokenId) = EntityLibrary.entityToToken(entityId);

        if (contractAddress != _getSystem(SHIP_NFT_ID)) {
            revert InvalidShipEntity();
        }

        // Check ship NFT owned by caller
        if (caller != IShipNFT(contractAddress).ownerOf(tokenId)) {
            revert NotOwner(entityId);
        }

        return !_isHealthZero(contractAddress, tokenId);
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

// Used for calculating decimal-point percentages (10000 = 100%)
uint256 constant PERCENTAGE_RANGE = 10000;

// Pauser Role - Can pause the game
bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

// Minter Role - Can mint items, NFTs, and ERC20 currency
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

// Manager Role - Can manage the shop, loot tables, and other game data
bytes32 constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

// Game Logic Contract - Contract that executes game logic and accesses other systems
bytes32 constant GAME_LOGIC_CONTRACT_ROLE = keccak256(
    "GAME_LOGIC_CONTRACT_ROLE"
);

// Game Currency Contract - Allowlisted currency ERC20 contract
bytes32 constant GAME_CURRENCY_CONTRACT_ROLE = keccak256(
    "GAME_CURRENCY_CONTRACT_ROLE"
);

// Game NFT Contract - Allowlisted game NFT ERC721 contract
bytes32 constant GAME_NFT_CONTRACT_ROLE = keccak256("GAME_NFT_CONTRACT_ROLE");

// Game Items Contract - Allowlist game items ERC1155 contract
bytes32 constant GAME_ITEMS_CONTRACT_ROLE = keccak256(
    "GAME_ITEMS_CONTRACT_ROLE"
);

// Depositor role - used by Polygon bridge to mint on child chain
bytes32 constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

// Randomizer role - Used by the randomizer contract to callback
bytes32 constant RANDOMIZER_ROLE = keccak256("RANDOMIZER_ROLE");

// Trusted forwarder role - Used by meta transactions to verify trusted forwader(s)
bytes32 constant TRUSTED_FORWARDER_ROLE = keccak256("TRUSTED_FORWARDER_ROLE");

// =====
// All of the possible traits in the system
// =====

/// @dev Trait that points to another token/template id
uint256 constant TEMPLATE_ID_TRAIT_ID = uint256(keccak256("template_id"));

// Generation of a token
uint256 constant GENERATION_TRAIT_ID = uint256(keccak256("generation"));

// XP for a token
uint256 constant XP_TRAIT_ID = uint256(keccak256("xp"));

// Current level of a token
uint256 constant LEVEL_TRAIT_ID = uint256(keccak256("level"));

// Whether or not a token is a pirate
uint256 constant IS_PIRATE_TRAIT_ID = uint256(keccak256("is_pirate"));

// Whether or not a token is a ship
uint256 constant IS_SHIP_TRAIT_ID = uint256(keccak256("is_ship"));

// Whether or not an item is equippable on ships
uint256 constant EQUIPMENT_TYPE_TRAIT_ID = uint256(keccak256("equipment_type"));

// Combat modifiers for items and tokens
uint256 constant COMBAT_MODIFIERS_TRAIT_ID = uint256(
    keccak256("combat_modifiers")
);

// Animation URL for the token
uint256 constant ANIMATION_URL_TRAIT_ID = uint256(keccak256("animation_url"));

// Item slots
uint256 constant ITEM_SLOTS_TRAIT_ID = uint256(keccak256("item_slots"));

// Rank of the ship
uint256 constant SHIP_RANK_TRAIT_ID = uint256(keccak256("ship_rank"));

// Current Health trait
uint256 constant CURRENT_HEALTH_TRAIT_ID = uint256(keccak256("current_health"));

// Health trait
uint256 constant HEALTH_TRAIT_ID = uint256(keccak256("health"));

// Damage trait
uint256 constant DAMAGE_TRAIT_ID = uint256(keccak256("damage"));

// Speed trait
uint256 constant SPEED_TRAIT_ID = uint256(keccak256("speed"));

// Accuracy trait
uint256 constant ACCURACY_TRAIT_ID = uint256(keccak256("accuracy"));

// Evasion trait
uint256 constant EVASION_TRAIT_ID = uint256(keccak256("evasion"));

// Image hash of token's image, used for verifiable / fair drops
uint256 constant IMAGE_HASH_TRAIT_ID = uint256(keccak256("image_hash"));

// Name of a token
uint256 constant NAME_TRAIT_ID = uint256(keccak256("name_trait"));

// Description of a token
uint256 constant DESCRIPTION_TRAIT_ID = uint256(keccak256("description_trait"));

// General rarity for a token (corresponds to IGameRarity)
uint256 constant RARITY_TRAIT_ID = uint256(keccak256("rarity"));

// The character's affinity for a specific element
uint256 constant ELEMENTAL_AFFINITY_TRAIT_ID = uint256(
    keccak256("affinity_id")
);

// The character's expertise value
uint256 constant EXPERTISE_TRAIT_ID = uint256(keccak256("expertise"));

// Expertise damage mod ID from SoT
uint256 constant EXPERTISE_DAMAGE_ID = uint256(
    keccak256("expertise.levelmultiplier.damage")
);

// Expertise evasion mod ID from SoT
uint256 constant EXPERTISE_EVASION_ID = uint256(
    keccak256("expertise.levelmultiplier.evasion")
);

// Expertise speed mod ID from SoT
uint256 constant EXPERTISE_SPEED_ID = uint256(
    keccak256("expertise.levelmultiplier.speed")
);

// Expertise accuracy mod ID from SoT
uint256 constant EXPERTISE_ACCURACY_ID = uint256(
    keccak256("expertise.levelmultiplier.accuracy")
);

// Expertise health mod ID from SoT
uint256 constant EXPERTISE_HEALTH_ID = uint256(
    keccak256("expertise.levelmultiplier.health")
);

// Boss start time trait
uint256 constant BOSS_START_TIME_TRAIT_ID = uint256(
    keccak256("boss_start_time")
);

// Boss end time trait
uint256 constant BOSS_END_TIME_TRAIT_ID = uint256(keccak256("boss_end_time"));

// Boss type trait
uint256 constant BOSS_TYPE_TRAIT_ID = uint256(keccak256("boss_type"));

// The character's dice rolls
uint256 constant DICE_ROLL_1_TRAIT_ID = uint256(keccak256("dice_roll_1"));
uint256 constant DICE_ROLL_2_TRAIT_ID = uint256(keccak256("dice_roll_2"));

// The character's star sign (astrology)
uint256 constant STAR_SIGN_TRAIT_ID = uint256(keccak256("star_sign"));

// Image for the token
uint256 constant IMAGE_TRAIT_ID = uint256(keccak256("image_trait"));

// How much energy the token provides if used
uint256 constant ENERGY_PROVIDED_TRAIT_ID = uint256(
    keccak256("energy_provided")
);

// Whether a given token is soulbound, meaning it is unable to be transferred
uint256 constant SOULBOUND_TRAIT_ID = uint256(keccak256("soulbound"));

// ------
// Avatar Profile Picture related traits

// If an avatar is a 1 of 1, this is their only trait
uint256 constant PROFILE_IS_LEGENDARY_TRAIT_ID = uint256(
    keccak256("profile_is_legendary")
);

// Avatar's archetype -- possible values: Human (including Druid, Mage, Berserker, Crusty), Robot, Animal, Zombie, Vampire, Ghost
uint256 constant PROFILE_CHARACTER_TYPE = uint256(
    keccak256("profile_character_type")
);

// Avatar's profile picture's background image
uint256 constant PROFILE_BACKGROUND_TRAIT_ID = uint256(
    keccak256("profile_background")
);

// Avatar's eye style
uint256 constant PROFILE_EYES_TRAIT_ID = uint256(keccak256("profile_eyes"));

// Avatar's facial hair type
uint256 constant PROFILE_FACIAL_HAIR_TRAIT_ID = uint256(
    keccak256("profile_facial_hair")
);

// Avatar's hair style
uint256 constant PROFILE_HAIR_TRAIT_ID = uint256(keccak256("profile_hair"));

// Avatar's skin color
uint256 constant PROFILE_SKIN_TRAIT_ID = uint256(keccak256("profile_skin"));

// Avatar's coat color
uint256 constant PROFILE_COAT_TRAIT_ID = uint256(keccak256("profile_coat"));

// Avatar's earring(s) type
uint256 constant PROFILE_EARRING_TRAIT_ID = uint256(
    keccak256("profile_facial_hair")
);

// Avatar's eye covering
uint256 constant PROFILE_EYE_COVERING_TRAIT_ID = uint256(
    keccak256("profile_eye_covering")
);

// Avatar's headwear
uint256 constant PROFILE_HEADWEAR_TRAIT_ID = uint256(
    keccak256("profile_headwear")
);

// Avatar's (Mages only) gem color
uint256 constant PROFILE_MAGE_GEM_TRAIT_ID = uint256(
    keccak256("profile_mage_gem")
);

// ------
// Dungeon traits

// Whether this token template is a dungeon trigger
uint256 constant IS_DUNGEON_TRIGGER_TRAIT_ID = uint256(
    keccak256("is_dungeon_trigger")
);

// Dungeon start time trait
uint256 constant DUNGEON_START_TIME_TRAIT_ID = uint256(
    keccak256("dungeon.start_time")
);

// Dungeon end time trait
uint256 constant DUNGEON_END_TIME_TRAIT_ID = uint256(
    keccak256("dungeon.end_time")
);

// Dungeon SoT map id trait
uint256 constant DUNGEON_MAP_TRAIT_ID = uint256(keccak256("dungeon.map_id"));

// Whether this token template is a mob
uint256 constant IS_MOB_TRAIT_ID = uint256(keccak256("is_mob"));

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

uint256 constant ID = uint256(keccak256("game.piratenation.cooldownsystem"));

/**
 * @title ICooldownSystem
 *
 * Interface for general CooldownSystem
 */
interface ICooldownSystem {
    /**
     * @dev Map an entity to a system cooldown Id to a timeStamp
     * @param entity can be address, nft, round, ability, etc
     * @param cooldownId keccak to system using cooldown
     * @param cooldownTime cooldown time limit to set for entity, example 12 hours
     * @return true if block.timestamp is past timeStamp + cooldownTime
     */
    function updateAndCheckCooldown(
        uint256 entity,
        uint256 cooldownId,
        uint32 cooldownTime
    ) external returns (bool);

    /**
     * @dev View function to check if entity is in cooldown
     * @param entity can be address, nft, round, ability, etc
     * @param cooldownId keccak to system using cooldown
     * @return true if block.timestamp is before entities cooldown timestamp, meaning entity is still in cooldown
     */
    function isInCooldown(
        uint256 entity,
        uint256 cooldownId
    ) external view returns (bool);

    /**
     * @dev View function return entity cooldown timestamp
     * @param entity can be address, nft, round, ability, etc
     * @param cooldownId keccak to system using cooldown
     * @return uint32 entity cooldown timestamp
     */
    function getCooldown(
        uint256 entity,
        uint256 cooldownId
    ) external view returns (uint32);

    /**
     * @dev Function for cleaning up an entity cooldown timestamp
     * @param entity can be address, nft, round, ability, etc
     * @param cooldownId keccak to system using cooldown
     */
    function deleteCooldown(uint256 entity, uint cooldownId) external;

    /**
     * @dev Function to reduce desired cooldown by cooldownTime
     * @param entity can be address, nft, round, ability, etc
     * @param cooldownId keccak to system using cooldown
     * @param cooldownTime time to reduce cooldown by
     */
    function reduceCooldown(
        uint256 entity,
        uint256 cooldownId,
        uint32 cooldownTime
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

uint256 constant MAX_UINT96 = 2 ** 96 - 1;

/** @title Entity related helpers **/
library EntityLibrary {
    /** ERRORS **/
    error TokenIdExceedsMaxValue(uint256 tokenId);

    /** INTERNAL **/

    /**
     * @dev Note this function will require the tokenId is < uint96.MAX
     * Unpacks a token address from a single uint256 which is the entity ID
     *
     * @return tokenAddress Address of the unpacked token
     */
    function entityToAddress(
        uint256 value
    ) internal pure returns (address tokenAddress) {
        tokenAddress = address(uint160(value));
        uint256 tokenId = uint256(value >> 160);
        uint256 verify = (tokenId << 160) | uint160(tokenAddress);
        require(verify == value);
    }

    /**
     * Packs an address into a single uint256 entity
     *
     * @param addr    Address to convert to entity
     * @return Converted address to entity
     */
    function addressToEntity(address addr) internal pure returns (uint256) {
        return uint160(addr);
    }

    /**
     * @dev Note this function will require the tokenId is < uint96.MAX
     * Unpacks a token address and token id from a single uint256
     *
     * @return tokenAddress Address of the unpacked token
     * @return tokenId      Id of the unpacked token
     */
    function entityToToken(
        uint256 value
    ) internal pure returns (address tokenAddress, uint256 tokenId) {
        tokenAddress = address(uint160(value));
        tokenId = uint256(value >> 160);
        uint256 verify = (tokenId << 160) | uint160(tokenAddress);
        require(verify == value);
    }

    /**
     * @dev Note this function will require the tokenId is < uint96.MAX
     * Packs a token address and token id into a single uint256
     *
     * @param tokenAddress  Address of the unpacked token
     * @param tokenId       Id of the unpacked token
     * @return              Token address and token id packed into single uint256
     */
    function tokenToEntity(
        address tokenAddress,
        uint256 tokenId
    ) internal pure returns (uint256) {
        if (tokenId > MAX_UINT96) {
            revert TokenIdExceedsMaxValue(tokenId);
        }
        return (tokenId << 160) | uint160(tokenAddress);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// @title Interface the game's ACL / Management Layer
interface IGameRegistry is IERC165 {
    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasAccessRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    /** @return Whether or not the registry is paused */
    function paused() external view returns (bool);

    /**
     * Registers a system by id
     *
     * @param systemId          Id of the system
     * @param systemAddress     Address of the system contract
     */
    function registerSystem(uint256 systemId, address systemAddress) external;

    /** @return System based on an id */
    function getSystem(uint256 systemId) external view returns (address);

    /**
     * Registers a component using an id and contract address
     * @param componentId Id of the component to register
     * @param componentAddress Address of the component contract
     */
    function registerComponent(
        uint256 componentId,
        address componentAddress
    ) external;

    /** @return A component's contract address given its ID */
    function getComponent(uint256 componentId) external view returns (address);

    /** @return A component's id given its contract address */
    function getComponentIdFromAddress(
        address componentAddr
    ) external view returns (uint256);

    /**
     * Register a component value update.
     * Emits the `ComponentValueSet` event for clients to reconstruct the state.
     */
    function registerComponentValueSet(
        uint256 entity,
        bytes calldata data
    ) external;

    /**
     * Register a component value removal.
     * Emits the `ComponentValueRemoved` event for clients to reconstruct the state.
     */
    function registerComponentValueRemoved(uint256 entity) external;

    /**
     * Generate a new general-purpose entity GUID
     */
    function generateGUID() external returns (uint256);

    /** @return Authorized Player account for an address
     * @param operatorAddress   Address of the Operator account
     */
    function getPlayerAccount(
        address operatorAddress
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Defines a system the game engine
 */
interface ISystem {
    /** @return The ID for the system. Ex: a uint256 casted keccak256 hash */
    function getId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

uint256 constant ID = uint256(keccak256("game.piratenation.countingsystem"));

/**
 * @title Simple Counting System
 */
interface ICountingSystem {
    /**
     * Get the stored counter's value.
     *
     * @param entityId  The entityId in the mapping.
     * @param key       The key in the mapping.
     * @return value    The value in the mapping.
     */
    function getCount(uint256 entityId, uint256 key)
        external
        view
        returns (uint256);

    /**
     * Set the stored counter's value.
     * (Mostly intended for debug purposes.)
     *
     * @param entityId  The entityId in the mapping.
     * @param key       The key in the mapping.
     * @param value     The value in the mapping.
     */
    function setCount(
        uint256 entityId,
        uint256 key,
        uint256 value
    ) external;

    /**
     * Increments the stored counter by some amount.
     *
     * @param entityId  The entityId in the mapping.
     * @param key       The key in the mapping.
     * @param amount    The amount to increment by.
     */
    function incrementCount(
        uint256 entityId,
        uint256 key,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./IERC721BridgableChild.sol";

/// @notice This contract implements the Matic/Polygon bridging logic to allow tokens to be bridged back to mainnet
abstract contract ERC721BridgableChild is
    ERC721Enumerable,
    IERC721BridgableChild
{
    // Max batch size
    uint256 public constant BATCH_LIMIT = 20;

    /** EVENTS **/

    // Emitted when a token is deposited
    event DepositFromBridge(address indexed to, uint256 indexed tokenId);

    // @notice this event needs to be like this and unchanged so that the L1 can pick up the changes
    // @dev We don't use this event, everything is a single withdraw so metadata is always transferred
    // event WithdrawnBatch(address indexed user, uint256[] tokenIds);

    // @notice this event needs to be like this and unchanged so that the L1 can pick up the changes
    event TransferWithMetadata(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        bytes metaData
    );

    /** ERRORS **/

    /// @notice Call was not made by owner
    error NotOwner();

    /// @notice Tried to withdraw too many tokens at once
    error ExceedsBatchLimit();

    /** EXTERNAL **/

    /**
     * @notice called when to wants to withdraw token back to root chain
     * @dev Should burn to's token. This transaction will be verified when exiting on root chain
     * @param tokenId tokenId to withdraw
     */
    function withdraw(uint256 tokenId) external {
        _withdrawWithMetadata(tokenId);
    }

    /**
     * @notice called when to wants to withdraw multiple tokens back to root chain
     * @dev Should burn to's tokens. This transaction will be verified when exiting on root chain
     * @param tokenIds tokenId list to withdraw
     */
    function withdrawBatch(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        if (length > BATCH_LIMIT) {
            revert ExceedsBatchLimit();
        }
        for (uint256 i; i < length; ++i) {
            uint256 tokenId = tokenIds[i];
            _withdrawWithMetadata(tokenId);
        }
    }

    /**
     * @notice called when to wants to withdraw token back to root chain with arbitrary metadata
     * @dev Should handle withraw by burning to's token.
     *
     * This transaction will be verified when exiting on root chain
     *
     * @param tokenId tokenId to withdraw
     */
    function withdrawWithMetadata(uint256 tokenId) external {
        _withdrawWithMetadata(tokenId);
    }

    /**
     * @notice This method is supposed to be called by client when withdrawing token with metadata
     * and pass return value of this function as second paramter of `withdrawWithMetadata` method
     *
     * It can be overridden by clients to encode data in a different form, which needs to
     * be decoded back by them correctly during exiting
     *
     * @param tokenId Token for which URI to be fetched
     */
    function encodeTokenMetadata(uint256 tokenId)
        external
        view
        virtual
        returns (bytes memory)
    {
        // You're always free to change this default implementation
        // and pack more data in byte array which can be decoded back
        // in L1
        return abi.encode(tokenURI(tokenId));
    }

    /** @return Whether or not the given tokenId has been minted/exists */
    function exists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721BridgableChild).interfaceId ||
            ERC721Enumerable.supportsInterface(interfaceId);
    }

    /** INTERNAL **/

    /// @dev executes the withdraw
    function _withdrawWithMetadata(uint256 tokenId) internal {
        if (_msgSender() != ownerOf(tokenId)) {
            revert NotOwner();
        }

        // Encoding metadata associated with tokenId & emitting event
        // This event needs to be exactly like this for the bridge to work
        emit TransferWithMetadata(
            _msgSender(),
            address(0),
            tokenId,
            this.encodeTokenMetadata(tokenId)
        );

        _burn(tokenId);
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required tokenId for to
     * Make sure minting is done only by this function
     * @param to address for whom deposit is being done
     * @param depositData abi encoded tokenId
     */
    function _deposit(address to, bytes calldata depositData) internal virtual {
        // deposit single
        if (depositData.length == 32) {
            uint256 tokenId = abi.decode(depositData, (uint256));
            _safeMint(to, tokenId);

            emit DepositFromBridge(to, tokenId);
        } else {
            // deposit batch
            uint256[] memory tokenIds = abi.decode(depositData, (uint256[]));
            uint256 length = tokenIds.length;
            for (uint256 i; i < length; ++i) {
                _safeMint(to, tokenIds[i]);
                emit DepositFromBridge(to, tokenIds[i]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IGameNFT} from "./IGameNFT.sol";
import {DEPOSITOR_ROLE} from "../Constants.sol";

import {ITraitsProvider} from "../interfaces/ITraitsProvider.sol";

import {SafeCast, ITraitsConsumer, TraitsConsumer, GameRegistryConsumer} from "../traits/TraitsConsumer.sol";
import {IERC721BeforeTokenTransferHandler} from "../tokens/IERC721BeforeTokenTransferHandler.sol";

import "./ERC721BridgableChild.sol";

/** @title NFT base contract for all game NFTs. Exposes traits for the NFT and respects GameRegistry/Soulbound/LockingSystem access control */
contract GameNFT is IERC165, TraitsConsumer, IGameNFT, ERC721BridgableChild {
    /// @notice Whether or not the token has had its traits initialized. Prevents re-initialization when bridging
    mapping(uint256 => bool) private _traitsInitialized;

    /// @notice Max supply for this NFT. If zero, it is unlimited supply.
    uint256 private immutable _maxSupply;

    /// @notice The amount of time a token has been held by a given account
    mapping(uint256 => mapping(address => uint32)) private _timeHeld;

    /// @notice Last transfer time for the token
    mapping(uint256 => uint32) public lastTransfer;

    /// @notice Current contract metadata URI for this collection
    string private _contractURI;

    /// @notice Handler for before token transfer events
    address public beforeTokenTransferHandler;

    /** EVENTS **/

    /// @notice Emitted when contractURI has changed
    event ContractURIUpdated(string uri);

    /** ERRORS **/

    /// @notice Account must be non-null
    error InvalidAccountAddress();

    /// @notice Token id is not valid
    error InvalidTokenId();

    /// @notice tokenId exceeds max supply for this NFT
    error TokenIdExceedsMaxSupply();

    /// @notice Amount to mint exceeds max supply
    error NotEnoughSupply(uint256 needed, uint256 actual);

    /** SETUP **/

    constructor(
        uint256 tokenMaxSupply,
        string memory name,
        string memory symbol,
        address gameRegistryAddress,
        uint256 id
    ) ERC721(name, symbol) TraitsConsumer(gameRegistryAddress, id) {
        _maxSupply = tokenMaxSupply;
    }

    /**
     * Sets the current contractURI for the contract
     *
     * @param _uri New contract URI
     */
    function setContractURI(string calldata _uri) public onlyOwner {
        _contractURI = _uri;
        emit ContractURIUpdated(_uri);
    }

    /**
     * @return Contract metadata URI for the NFT contract, used by NFT marketplaces to display collection inf
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by DEPOSITOR_ROLE and call _deposit
     */
    function deposit(
        address to,
        bytes calldata depositData
    ) external override onlyRole(DEPOSITOR_ROLE) {
        _deposit(to, depositData);
    }

    /** @return Max supply for this token */
    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @return Generates a dynamic tokenURI based on the traits associated with the given token
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        // Make sure this still errors according to ERC721 spec
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return _tokenURI(tokenId);
    }

    /**
     * @param account Account to check hold time of
     * @param tokenId Id of the token
     * @return The time in seconds a given account has held a token
     */
    function getTimeHeld(
        address account,
        uint256 tokenId
    ) external view returns (uint32) {
        address owner = ownerOf(tokenId);
        if (account == address(0)) {
            revert InvalidAccountAddress();
        }

        uint32 totalTime = _timeHeld[tokenId][account];

        if (owner == account) {
            uint32 lastTransferTime = lastTransfer[tokenId];
            uint32 currentTime = SafeCast.toUint32(block.timestamp);

            totalTime += (currentTime - lastTransferTime);
        }

        return totalTime;
    }

    /**
     * Sets the before token transfer handler
     *
     * @param handlerAddress  Address to the transfer hook handler contract
     */
    function setBeforeTokenTransferHandler(
        address handlerAddress
    ) external onlyOwner {
        beforeTokenTransferHandler = handlerAddress;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(IERC165, TraitsConsumer, ERC721BridgableChild)
        returns (bool)
    {
        return
            interfaceId == type(IGameNFT).interfaceId ||
            ERC721BridgableChild.supportsInterface(interfaceId) ||
            TraitsConsumer.supportsInterface(interfaceId);
    }

    /** INTERNAL **/

    /** Initializes traits for the given tokenId */
    function _initializeTraits(uint256 tokenId) internal virtual {
        // Do nothing by default
    }

    /**
     * Mint token to recipient
     *
     * @param to        The recipient of the token
     * @param tokenId   Id of the token to mint
     */
    function _safeMint(address to, uint256 tokenId) internal override {
        if (_maxSupply != 0 && tokenId > _maxSupply) {
            revert TokenIdExceedsMaxSupply();
        }

        if (tokenId == 0) {
            revert InvalidTokenId();
        }

        super._safeMint(to, tokenId);

        // Conditionally initialize traits
        if (_traitsInitialized[tokenId] == false) {
            _initializeTraits(tokenId);
            _traitsInitialized[tokenId] = true;
        }
    }

    /**
     * @notice Checks for soulbound status before transfer
     * @inheritdoc ERC721
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        if (beforeTokenTransferHandler != address(0)) {
            IERC721BeforeTokenTransferHandler handlerRef = IERC721BeforeTokenTransferHandler(
                    beforeTokenTransferHandler
                );
            handlerRef.beforeTokenTransfer(
                address(this),
                _msgSender(),
                from,
                to,
                firstTokenId,
                batchSize
            );
        }

        // Track hold time
        for (uint256 idx = 0; idx < batchSize; idx++) {
            uint256 tokenId = firstTokenId + idx;
            uint32 lastTransferTime = lastTransfer[tokenId];
            uint32 currentTime = SafeCast.toUint32(block.timestamp);
            if (lastTransferTime > 0) {
                _timeHeld[tokenId][from] += (currentTime - lastTransferTime);
            }
            lastTransfer[tokenId] = currentTime;
        }

        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * Message sender override to get Context to work with meta transactions
     *
     */
    function _msgSender()
        internal
        view
        override(Context, GameRegistryConsumer)
        returns (address)
    {
        return GameRegistryConsumer._msgSender();
    }

    /**
     * Message data override to get Context to work with meta transactions
     *
     */
    function _msgData()
        internal
        view
        override(Context, GameRegistryConsumer)
        returns (bytes memory)
    {
        return GameRegistryConsumer._msgData();
    }

    function getLastTransfer(uint256 tokenId) external view returns (uint32) {
        return lastTransfer[tokenId];
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

// @notice Interface for Polygon bridgable NFTs on L2-chain
interface IERC721BridgableChild is IERC721Enumerable {
    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager and call _deposit
     *
     * @param to            Address being deposited to
     * @param depositData   ABI encoded ids being deposited
     */
    function deposit(address to, bytes calldata depositData) external;

    /** @return Whether or not the given tokenId has been minted/exists */
    function exists(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import {IERC721BridgableChild} from "./IERC721BridgableChild.sol";
import {IHoldingConsumer} from "../interfaces/IHoldingConsumer.sol";

/**
 * @title Interface for game NFTs that have stats and other properties
 */
interface IGameNFT is IHoldingConsumer, IERC721BridgableChild {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

import {COMBAT_MODIFIERS_TRAIT_ID, EQUIPMENT_TYPE_TRAIT_ID, GAME_ITEMS_CONTRACT_ROLE} from "../Constants.sol";
import {EntityLibrary} from "../core/EntityLibrary.sol";
import {ITraitsProvider} from "../interfaces/ITraitsProvider.sol";
import {Item, IEquippable} from "./IEquippable.sol";

import "../GameRegistryConsumerUpgradeable.sol";

/**
 * @title Equippable
 *
 * @dev implement this to add equipment loadout management to a contract
 * @dev requires role GAME_LOGIC_CONTRACT_ROLE and MINTER_ROLE
 */
abstract contract Equippable is GameRegistryConsumerUpgradeable, IEquippable {
    /** ERRORS **/

    /// @notice Invalid item cannot be equipped by parent
    error InvalidItem(uint256 parentEntity, uint256 itemEntity);

    /// @notice Item cannot be equipped by invalid parent
    error InvalidParent();

    /// @notice Desired slot is invalid for item
    error InvalidSlot(uint256 slottedItemEntity, uint256 replaceItemEntity);

    /// @notice Desired slot index is invalid
    error InvalidSlotIndex(uint256 index);

    /** EXTERNAL **/

    /**
     * @inheritdoc IEquippable
     */
    function getCombatModifiers(
        uint256 parentEntity
    ) external view override returns (int256[] memory) {
        ITraitsProvider traitsProvider = _traitsProvider();

        // Get all slot types
        uint256[] memory slotTypes = _getSlotTypes(parentEntity);

        // Loop through slot types and get equipment loadout for each
        int256[] memory combatModifiers = new int256[](5);
        for (uint256 i = 0; i < slotTypes.length; i++) {
            uint256[] memory equipment = _getItems(
                parentEntity,
                slotTypes[i],
                traitsProvider
            );
            for (uint256 j = 0; j < equipment.length; j++) {
                // Get combat modifiers for item
                int256[] memory itemCombatModifiers = _getItemCombatModifiers(
                    equipment[j],
                    traitsProvider
                );

                // Add item combat modifiers to parent combat modifiers
                for (uint256 k = 0; k < itemCombatModifiers.length; k++) {
                    combatModifiers[k] += itemCombatModifiers[k];
                }
            }
        }

        return combatModifiers;
    }

    /**
     * @inheritdoc IEquippable
     */
    function getItems(
        uint256 parentEntity,
        uint256 slotType
    ) external view returns (uint256[] memory) {
        return _getItems(parentEntity, slotType, _traitsProvider());
    }

    /**
     * @inheritdoc IEquippable
     */
    function getSlotCount(
        uint256 parentEntity,
        uint256 slotType
    ) public view virtual returns (uint256);

    /**
     * @inheritdoc IEquippable
     */
    function removeItems(
        uint256 parentEntity,
        Item[] calldata items
    ) external whenNotPaused {
        address account = _getPlayerAccount(_msgSender());

        // Vaidate parentEntity belongs to caller
        if (!_isParentOwner(account, parentEntity)) {
            revert InvalidParent();
        }

        for (uint256 i = 0; i < items.length; ++i) {
            _removeItem(account, parentEntity, items[i], _traitsProvider());
        }
    }

    /**
     * @inheritdoc IEquippable
     */
    function setItems(
        uint256 parentEntity,
        uint256[] calldata existingItems,
        Item[] calldata items
    ) external whenNotPaused {
        address account = _getPlayerAccount(_msgSender());

        // Vaidate parentEntity belongs to caller
        if (!_isParentOwner(account, parentEntity)) {
            revert InvalidParent();
        }

        for (uint256 i = 0; i < items.length; ++i) {
            _setItem(
                account,
                parentEntity,
                existingItems[items[i].slotIndex],
                items[i]
            );
        }
    }

    /** INTERNAL **/

    /**
     * @dev Returns the equipment loadout at a parent entity's slotType, or initializes a new one
     */
    function _getItems(
        uint256 parentEntity,
        uint256 slotType,
        ITraitsProvider traitsProvider
    ) internal view returns (uint256[] memory) {
        (address tokenContract, uint256 tokenId) = EntityLibrary.entityToToken(
            parentEntity
        );

        // Pull current slots from trait provider or initialize new array if no trait exists
        return
            traitsProvider.hasTrait(tokenContract, tokenId, slotType)
                ? traitsProvider.getTraitUint256Array(
                    tokenContract,
                    tokenId,
                    slotType
                )
                : new uint256[](getSlotCount(parentEntity, slotType));
    }

    /**
     * @dev Returns the combat modifiers for an item
     */
    function _getItemCombatModifiers(
        uint256 itemEntity,
        ITraitsProvider traitsProvider
    ) internal view returns (int256[] memory) {
        (address tokenContract, uint256 tokenId) = EntityLibrary.entityToToken(
            itemEntity
        );

        // Return combat modifiers for item if it has them
        return
            traitsProvider.hasTrait(
                tokenContract,
                tokenId,
                COMBAT_MODIFIERS_TRAIT_ID
            )
                ? traitsProvider.getTraitInt256Array(
                    tokenContract,
                    tokenId,
                    COMBAT_MODIFIERS_TRAIT_ID
                )
                : new int256[](5);
    }

    /**
     * @dev Returns the slot types available for a parent entity
     * @param parentEntity A packed tokenId and address for a parent entity which equips items
     */
    function _getSlotTypes(
        uint256 parentEntity
    ) internal view virtual returns (uint256[] memory);

    /**
     * @dev Function to override with custom validation logic
     * @param parentEntity A packed tokenId and address for a parent entity which equips items
     * @param item Item params which specify entity, slot type, and slot index to remove
     * @param traitsProvider Reference to TraitsProvider system for reading traits
     */
    function _isItemEquippable(
        uint256 parentEntity,
        Item calldata item,
        ITraitsProvider traitsProvider
    ) internal virtual returns (bool);

    /**
     * @dev Returns boolean representing if account is the owner of parent
     */
    function _isParentOwner(
        address account,
        uint256 parentEntity
    ) internal view returns (bool) {
        (address parentContract, uint256 parentTokenId) = EntityLibrary
            .entityToToken(parentEntity);
        return IERC721(parentContract).ownerOf(parentTokenId) == account;
    }

    /**
     * @dev Reverts if an item is not safe to equip to parent
     */
    function _requireValidItem(
        address account,
        uint256 parentEntity,
        uint256 existingItemEntity,
        Item calldata item,
        ITraitsProvider traitsProvider
    ) internal {
        (address tokenContract, uint256 tokenId) = EntityLibrary.entityToToken(
            item.itemEntity
        );

        // Ensure item a burnable game item; for now must be ERC1155
        // Also requires item to implement TraitConsumer which aids in reading traits
        if (_hasAccessRole(GAME_ITEMS_CONTRACT_ROLE, tokenContract) == false) {
            revert InvalidItem(parentEntity, item.itemEntity);
        }

        // Check if parent is owner of item
        if (IERC1155(tokenContract).balanceOf(account, tokenId) == 0) {
            revert InvalidItem(parentEntity, item.itemEntity);
        }

        // Check if valid slot index for parent
        if (getSlotCount(parentEntity, item.slotType) <= item.slotIndex) {
            revert InvalidSlotIndex(item.slotIndex);
        }

        // Check if slot is occupied; if so it must match existingItemEntity
        uint256[] memory slots = _getItems(
            parentEntity,
            item.slotType,
            traitsProvider
        );
        if (
            slots[item.slotIndex] != 0 &&
            slots[item.slotIndex] != existingItemEntity
        ) {
            revert InvalidSlot(slots[item.slotIndex], existingItemEntity);
        }

        // Check item has `equipment_type` trait
        if (
            !traitsProvider.hasTrait(
                tokenContract,
                tokenId,
                EQUIPMENT_TYPE_TRAIT_ID
            )
        ) {
            revert InvalidItem(parentEntity, item.itemEntity);
        }

        // Run custom validation checks:
        // > Check that item is valid for parent
        // > Check that slot type is valid for implementor
        if (!_isItemEquippable(parentEntity, item, traitsProvider)) {
            revert InvalidItem(parentEntity, item.itemEntity);
        }
    }

    /**
     * @dev Safely sets an item to parent entity at slotType and slotIndex
     */
    function _setItem(
        address account,
        uint256 parentEntity,
        uint256 existingItemEntity,
        Item calldata item
    ) internal {
        ITraitsProvider traitsProvider = _traitsProvider();
        uint256[] memory currentSlots = _getItems(
            parentEntity,
            item.slotType,
            traitsProvider
        );

        // Validate item and parent are compatible
        _requireValidItem(
            account,
            parentEntity,
            existingItemEntity,
            item,
            traitsProvider
        );

        (address tokenContract, uint256 tokenId) = EntityLibrary.entityToToken(
            item.itemEntity
        );

        // Burn the item when storing it in a slot
        ERC1155Burnable(tokenContract).burn(account, tokenId, 1);

        // For now we do not mint items back to the user, but we can someday
        // Check if slot is occupied and remove it if so
        // if (currentSlots[item.slotIndex] != 0) {
        //     _removeItem(
        //         account,
        //         parentEntity,
        //         Item({
        //             itemEntity: currentSlots[item.slotIndex],
        //             slotType: item.slotType,
        //             slotIndex: item.slotIndex
        //         }),
        //         traitsProvider
        //     );
        // }

        // Set item in traits provider; for now this clobbers any equipped item
        currentSlots[item.slotIndex] = item.itemEntity;
        (tokenContract, tokenId) = EntityLibrary.entityToToken(parentEntity);
        traitsProvider.setTraitUint256Array(
            tokenContract,
            tokenId,
            item.slotType,
            currentSlots
        );
    }

    /**
     * @dev Removes and mints an item from parent entity at slotType if present
     */
    function _removeItem(
        address,
        uint256 parentEntity,
        Item memory item,
        ITraitsProvider traitsProvider
    ) internal {
        uint256[] memory slots = _getItems(
            parentEntity,
            item.slotType,
            traitsProvider
        );

        // Check equipped slot at slotIndex
        if (
            slots[item.slotIndex] == 0 ||
            slots[item.slotIndex] != item.itemEntity
        ) {
            revert InvalidItem(parentEntity, item.itemEntity);
        }

        // Remove item from slots
        delete slots[item.slotIndex];

        (address tokenContract, uint256 tokenId) = EntityLibrary.entityToToken(
            parentEntity
        );
        traitsProvider.setTraitUint256Array(
            tokenContract,
            tokenId,
            item.slotType,
            slots
        );

        // Default behavior is not to mint the item back to caller
        // (tokenContract, tokenId) = EntityLibrary.entityToToken(item.itemEntity);
        // IGameItems(tokenContract).mint(account, tokenId, 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Enum describing the kind of items that can be equipped
enum EquipmentType {
    UNDEFINED,
    SHIPS,
    length // This must remain as last member in enum; currently == 2
}

/**
 * Input for setting an item to a slot; may remove any existing items in slot
 * @param itemEntity Entity of item to equip
 * @param slotType Keccak256 identifier of the slot type to equip item to
 * @param slotIndex Slot index to equip item to
 */
struct Item {
    uint256 itemEntity;
    uint256 slotType;
    uint256 slotIndex;
}

/**
 * @title IEquippable
 *
 * IEquippable is an interface for defining how game nft's can be equipped with other entities.
 */
interface IEquippable {
    /**
     * @dev Returns the total combat modifiers given a parent entity's equipment loadout
     * @param parentEntity A packed tokenId and address for a parent entity which equips items
     */
    function getCombatModifiers(
        uint256 parentEntity
    ) external view returns (int256[] memory);

    /**
     * @dev Returns the equipment loadout at a parent entity's slotType, or initializes a new one
     * @param parentEntity A packed tokenId and address for the parent entity which will equip the item
     * @param slotType Keccak256 identifier of the slot type to get equipment loadout for
     */
    function getItems(
        uint256 parentEntity,
        uint256 slotType
    ) external view returns (uint256[] memory);

    /**
     * @dev Return the number of item slots a parent entity has for a specific slot type
     * @param parentEntity A packed tokenId and address for the parent entity which will equip the item
     * @param slotType Keccak256 identifier of the slot type to equip item to return item count for
     */
    function getSlotCount(
        uint256 parentEntity,
        uint256 slotType
    ) external view returns (uint256);

    /**
     * @dev Stores an array of items to equipment slots
     * @param parentEntity A packed tokenId and address for the parent entity which will equip the item
     * @param existingItems Array of existing items that are expected to be overrode
     * @param items Array of params which specify entity, slot type, and slot index to equip to
     */
    function setItems(
        uint256 parentEntity,
        uint256[] calldata existingItems,
        Item[] calldata items
    ) external;

    /**
     * @dev Removes an array of items from equipment slots
     * @param parentEntity A packed tokenId and address for the parent entity which will equip the item
     * @param items Array of params which specify entity, slot type, and slot index to remove from
     */
    function removeItems(uint256 parentEntity, Item[] calldata items) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {EQUIPMENT_TYPE_TRAIT_ID, IS_SHIP_TRAIT_ID, ITEM_SLOTS_TRAIT_ID} from "../Constants.sol";
import {EntityLibrary} from "../core/EntityLibrary.sol";
import {ITraitsProvider} from "../interfaces/ITraitsProvider.sol";
import {ITokenTemplateSystem, ID as TOKEN_TEMPLATE_SYSTEM_ID} from "../tokens/ITokenTemplateSystem.sol";
import {Equippable} from "./Equippable.sol";
import {EquipmentType, Item} from "./IEquippable.sol";

// Constants
uint256 constant ID = uint256(keccak256("game.piratenation.shipequipment"));
uint256 constant SHIP_CORE_SLOT_TYPE = uint256(
    keccak256("equipment.ship.core")
);

contract ShipEquipment is Equippable {
    /** SETUP **/

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     */
    function initialize(address gameRegistryAddress) public initializer {
        __GameRegistryConsumer_init(gameRegistryAddress, ID);
    }

    /** EXTERNAL **/

    /**
     * @dev Return the number of item slots a parent entity has for a specific slot type
     * @param parentEntity A packed tokenId and address for the parent entity which will equip the item
     * @param slotType Keccak256 identifier of the slot type to equip item to return item count for
     */
    function getSlotCount(
        uint256 parentEntity,
        uint256 slotType
    ) public view override returns (uint256) {
        ITokenTemplateSystem tokenTemplateSystem = ITokenTemplateSystem(
            _getSystem(TOKEN_TEMPLATE_SYSTEM_ID)
        );

        // Ships only have a single slot type
        if (slotType != SHIP_CORE_SLOT_TYPE) {
            return 0;
        }

        // Get ITEM_SLOTS_TRAIT_ID from TokenTemplateSystem
        (address tokenContract, uint256 tokenId) = EntityLibrary.entityToToken(
            parentEntity
        );
        return
            tokenTemplateSystem.hasTrait(
                tokenContract,
                tokenId,
                ITEM_SLOTS_TRAIT_ID
            )
                ? tokenTemplateSystem.getTraitUint256(
                    tokenContract,
                    tokenId,
                    ITEM_SLOTS_TRAIT_ID
                )
                : 0;
    }

    /** INTERNAL **/

    /**
     * @dev Returns the slot types available for a parent entity
     */
    function _getSlotTypes(
        uint256
    ) internal pure override returns (uint256[] memory) {
        uint256[] memory slotTypes = new uint256[](1);
        slotTypes[0] = SHIP_CORE_SLOT_TYPE;
        return slotTypes;
    }

    /**
     * @dev Function to override with custom validation logic
     */
    function _isItemEquippable(
        uint256 parentEntity,
        Item calldata item,
        ITraitsProvider traitsProvider
    ) internal view override returns (bool) {
        (address tokenContract, uint256 tokenId) = EntityLibrary.entityToToken(
            parentEntity
        );

        // Check is valid slot type
        if (item.slotType != SHIP_CORE_SLOT_TYPE) {
            return false;
        }

        // Check that parent is a ship
        if (
            traitsProvider.getTraitBool(
                tokenContract,
                tokenId,
                IS_SHIP_TRAIT_ID
            ) == false
        ) {
            return false;
        }

        // Check if item is equippable by parent
        (tokenContract, tokenId) = EntityLibrary.entityToToken(item.itemEntity);
        if (
            traitsProvider.getTraitUint256(
                tokenContract,
                tokenId,
                EQUIPMENT_TYPE_TRAIT_ID
            ) != uint256(EquipmentType.SHIPS)
        ) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.gameglobals"));

/** @title Provides a set of globals to a set of ERC721/ERC1155 contracts */
interface IGameGlobals is IERC165 {
    // Type of data to allow in the global
    enum GlobalDataType {
        NOT_INITIALIZED, // Global has not been initialized
        BOOL, // bool data type
        INT256, // uint256 data type
        INT256_ARRAY, // int256[] data type
        UINT256, // uint256 data type
        UINT256_ARRAY, // uint256[] data type
        STRING, // string data type
        STRING_ARRAY // string[] data type
    }

    // Holds metadata for a given global type
    struct GlobalMetadata {
        // Name of the global, used in tokenURIs
        string name;
        // Global type
        GlobalDataType dataType;
    }

    /**
     * Sets the value for the string global, also checks to make sure global can be modified
     *
     * @param globalId        Id of the global to modify
     * @param value          New value for the given global
     */
    function setString(uint256 globalId, string calldata value) external;

    /**
     * Sets the value for the string global, also checks to make sure global can be modified
     *
     * @param globalId        Id of the global to modify
     * @param value          New value for the given global
     */
    function setStringArray(uint256 globalId, string[] calldata value) external;

    /**
     * Sets several string globals
     *
     * @param globalIds       Ids of globals to set
     * @param values         Values of globals to set
     */
    function batchSetString(
        uint256[] calldata globalIds,
        string[] calldata values
    ) external;

    /**
     * Sets the value for the bool global, also checks to make sure global can be modified
     *
     * @param globalId       Id of the global to modify
     * @param value          New value for the given global
     */
    function setBool(uint256 globalId, bool value) external;

    /**
     * Sets the value for the uint256 global, also checks to make sure global can be modified
     *
     * @param globalId       Id of the global to modify
     * @param value          New value for the given global
     */
    function setUint256(uint256 globalId, uint256 value) external;

    /**
     * Sets the value for the int256 global, also checks to make sure global can be modified
     *
     * @param globalId       Id of the global to modify
     * @param value          New value for the given global
     */
    function setInt256(uint256 globalId, int256 value) external;

    /**
     * Sets the value for the uint256 global, also checks to make sure global can be modified
     *
     * @param globalId        Id of the global to modify
     * @param value          New value for the given global
     */
    function setUint256Array(uint256 globalId, uint256[] calldata value)
        external;

    /**
     * Sets the value for the int256 global, also checks to make sure global can be modified
     *
     * @param globalId       Id of the global to modify
     * @param value          New value for the given global
     */
    function setInt256Array(uint256 globalId, int256[] calldata value) external;

    /**
     * Sets several uint256 globals for a given token
     *
     * @param globalIds       Ids of globals to set
     * @param values         Values of globals to set
     */
    function batchSetUint256(
        uint256[] calldata globalIds,
        uint256[] calldata values
    ) external;

    /**
     * Sets several int256 globals for a given token
     *
     * @param globalIds      Ids of globals to set
     * @param values         Values of globals to set
     */
    function batchSetInt256(
        uint256[] calldata globalIds,
        int256[] calldata values
    ) external;

    /**
     * Retrieves a bool global for the given token
     *
     * @param globalId         Id of the global to retrieve
     *
     * @return The value of the global if it exists, reverts if the global has not been set or is of a different type.
     */
    function getBool(uint256 globalId) external view returns (bool);

    /**
     * Retrieves a uint256 global for the given token
     *
     * @param globalId         Id of the global to retrieve
     *
     * @return The value of the global if it exists, reverts if the global has not been set or is of a different type.
     */
    function getUint256(uint256 globalId) external view returns (uint256);

    /**
     * Retrieves a uint256 array global for the given token
     *
     * @param globalId         Id of the global to retrieve
     *
     * @return The value of the global if it exists, reverts if the global has not been set or is of a different type.
     */
    function getUint256Array(uint256 globalId)
        external
        view
        returns (uint256[] memory);

    /**
     * Retrieves a int256 global for the given token
     *
     * @param globalId         Id of the global to retrieve
     *
     * @return The value of the global if it exists, reverts if the global has not been set or is of a different type.
     */
    function getInt256(uint256 globalId) external view returns (int256);

    /**
     * Retrieves a int256 array global for the given token
     *
     * @param globalId         Id of the global to retrieve
     *
     * @return The value of the global if it exists, reverts if the global has not been set or is of a different type.
     */
    function getInt256Array(uint256 globalId)
        external
        view
        returns (int256[] memory);

    /**
     * Retrieves a string global
     *
     * @param globalId         Id of the global to retrieve
     *
     * @return The value of the global if it exists, reverts if the global has not been set or is of a different type.
     */
    function getString(uint256 globalId) external view returns (string memory);

    /**
     * Returns data for a global variable containing an array of strings
     *
     * @param globalId  Id of the global to retrieve
     *
     * @return Global value as a string[]
     */
    function getStringArray(uint256 globalId)
        external
        view
        returns (string[] memory);

    /**
     * @param globalId  Id of the global to get metadata for
     * @return Metadata for the given global
     */
    function getMetadata(uint256 globalId)
        external
        view
        returns (GlobalMetadata memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@opengsn/contracts/src/interfaces/IERC2771Recipient.sol";

import {IGameRegistry} from "./core/IGameRegistry.sol";
import {ISystem} from "./core/ISystem.sol";

import {TRUSTED_FORWARDER_ROLE} from "./Constants.sol";

import {ITraitsProvider, ID as TRAITS_PROVIDER_ID} from "./interfaces/ITraitsProvider.sol";
import {ILockingSystem, ID as LOCKING_SYSTEM_ID} from "./locking/ILockingSystem.sol";
import {IRandomizer, IRandomizerCallback, ID as RANDOMIZER_ID} from "./randomizer/IRandomizer.sol";
import {ILootSystem, ID as LOOT_SYSTEM_ID} from "./loot/ILootSystem.sol";

/** @title Contract that lets a child contract access the GameRegistry contract */
abstract contract GameRegistryConsumer is
    ISystem,
    Ownable,
    IERC2771Recipient,
    IRandomizerCallback
{
    /// @notice Whether or not the contract is paused
    bool private _paused;

    /// @notice Id for the system/component
    uint256 private _id;

    /// @notice Read access contract
    IGameRegistry private _gameRegistry;

    /** EVENTS **/

    /// @dev Emitted when the pause is triggered by `account`.
    event Paused(address account);

    /// @dev Emitted when the pause is lifted by `account`.
    event Unpaused(address account);

    /** ERRORS **/

    /// @notice Not authorized to perform action
    error MissingRole(address account, bytes32 expectedRole);

    /** MODIFIERS **/

    // Modifier to verify a user has the appropriate role to call a given function
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
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

    /** ERRORS **/

    /// @notice gameRegistryAddress does not implement IGameRegistry
    error InvalidGameRegistry();

    /** SETUP **/

    /** Sets the GameRegistry contract address for this contract  */
    constructor(address gameRegistryAddress, uint256 id) {
        _gameRegistry = IGameRegistry(gameRegistryAddress);
        _id = id;

        if (gameRegistryAddress == address(0)) {
            revert InvalidGameRegistry();
        }

        _paused = true;
    }

    /** EXTERNAL **/

    /** @return ID for this system */
    function getId() public view override returns (uint256) {
        return _id;
    }

    /**
     * Pause/Unpause the contract
     *
     * @param shouldPause Whether or pause or unpause
     */
    function setPaused(bool shouldPause) external onlyOwner {
        if (shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev Returns true if the contract OR the GameRegistry is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused || _gameRegistry.paused();
    }

    /**
     * Sets the GameRegistry contract address for this contract
     *
     * @param gameRegistryAddress  Address for the GameRegistry contract
     */
    function setGameRegistry(address gameRegistryAddress) external onlyOwner {
        _gameRegistry = IGameRegistry(gameRegistryAddress);

        if (gameRegistryAddress == address(0)) {
            revert InvalidGameRegistry();
        }
    }

    /** @return GameRegistry contract for this contract */
    function getGameRegistry() external view returns (IGameRegistry) {
        return _gameRegistry;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasAccessRole(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return _gameRegistry.hasAccessRole(role, account);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) virtual internal view {
        if (!_gameRegistry.hasAccessRole(role, account)) {
            revert MissingRole(account, role);
        }
    }

    /** @return Returns the traits provider for this contract */
    function _traitsProvider() internal view returns (ITraitsProvider) {
        return ITraitsProvider(_getSystem(TRAITS_PROVIDER_ID));
    }

    /** @return Interface to the LockingSystem */
    function _lockingSystem() internal view returns (ILockingSystem) {
        return ILockingSystem(_gameRegistry.getSystem(LOCKING_SYSTEM_ID));
    }

    /** @return Interface to the LootSystem */
    function _lootSystem() internal view returns (ILootSystem) {
        return ILootSystem(_gameRegistry.getSystem(LOOT_SYSTEM_ID));
    }

    /** @return Interface to the Randomizer */
    function _randomizer() internal view returns (IRandomizer) {
        return IRandomizer(_gameRegistry.getSystem(RANDOMIZER_ID));
    }

    /** @return Address for a given system */
    function _getSystem(uint256 systemId) internal view returns (address) {
        return _gameRegistry.getSystem(systemId);
    }

    /**
     * Requests randomness from the game's Randomizer contract
     *
     * @param numWords Number of words to request from the VRF
     *
     * @return Id of the randomness request
     */
    function _requestRandomWords(uint32 numWords) internal returns (uint256) {
        return
            _randomizer().requestRandomWords(
                IRandomizerCallback(this),
                numWords
            );
    }

    /**
     * Callback for when a random number request has returned with random words
     *
     * @param requestId     Id of the request
     * @param randomWords   Random words
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external virtual override {
        // Do nothing by default
    }

    /**
     * Returns the Player address for the Operator account
     * @param operatorAccount address of the Operator account to retrieve the player for
     */
    function _getPlayerAccount(
        address operatorAccount
    ) internal view returns (address playerAccount) {
        return _gameRegistry.getPlayerAccount(operatorAccount);
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(
        address forwarder
    ) public view virtual override returns (bool) {
        return
            address(_gameRegistry) != address(0) &&
            _hasAccessRole(TRUSTED_FORWARDER_ROLE, forwarder);
    }

    /** INTERNAL **/

    /// @inheritdoc IERC2771Recipient
    function _msgSender()
        internal
        view
        virtual
        override(Context, IERC2771Recipient)
        returns (address ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData()
        internal
        view
        virtual
        override(Context, IERC2771Recipient)
        returns (bytes calldata ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    /** PAUSABLE **/

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
    function _pause() internal virtual {
        require(_paused == false, "Pausable: not paused");
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
    function _unpause() internal virtual {
        require(_paused == true, "Pausable: not paused");
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@opengsn/contracts/src/interfaces/IERC2771Recipient.sol";

import {PERCENTAGE_RANGE, TRUSTED_FORWARDER_ROLE} from "./Constants.sol";

import {ISystem} from "./core/ISystem.sol";
import {ITraitsProvider, ID as TRAITS_PROVIDER_ID} from "./interfaces/ITraitsProvider.sol";
import {ILockingSystem, ID as LOCKING_SYSTEM_ID} from "./locking/ILockingSystem.sol";
import {IRandomizer, IRandomizerCallback, ID as RANDOMIZER_ID} from "./randomizer/IRandomizer.sol";
import {ILootSystem, ID as LOOT_SYSTEM_ID} from "./loot/ILootSystem.sol";
import {IGameRegistry, IERC165} from "./core/IGameRegistry.sol";

/** @title Contract that lets a child contract access the GameRegistry contract */
abstract contract GameRegistryConsumerUpgradeable is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC2771Recipient,
    IRandomizerCallback,
    ISystem
{
    /// @notice Whether or not the contract is paused
    bool private _paused;

    /// @notice Reference to the game registry that this contract belongs to
    IGameRegistry internal _gameRegistry;

    /// @notice Id for the system/component
    uint256 private _id;

    /** EVENTS **/

    /// @dev Emitted when the pause is triggered by `account`.
    event Paused(address account);

    /// @dev Emitted when the pause is lifted by `account`.
    event Unpaused(address account);

    /** ERRORS **/

    /// @notice Not authorized to perform action
    error MissingRole(address account, bytes32 expectedRole);

    /** MODIFIERS **/

    /// @notice Modifier to verify a user has the appropriate role to call a given function
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
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

    /** ERRORS **/

    /// @notice Error if the game registry specified is invalid
    error InvalidGameRegistry();

    /** SETUP **/

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     * @param id                  Id of the system/component
     */
    function __GameRegistryConsumer_init(
        address gameRegistryAddress,
        uint256 id
    ) internal onlyInitializing {
        __Ownable_init();
        __ReentrancyGuard_init();

        _gameRegistry = IGameRegistry(gameRegistryAddress);

        if (gameRegistryAddress == address(0)) {
            revert InvalidGameRegistry();
        }

        _paused = true;
        _id = id;
    }

    /** @return ID for this system */
    function getId() public view override returns (uint256) {
        return _id;
    }

    /**
     * Pause/Unpause the contract
     *
     * @param shouldPause Whether or pause or unpause
     */
    function setPaused(bool shouldPause) external onlyOwner {
        if (shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev Returns true if the contract OR the GameRegistry is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused || _gameRegistry.paused();
    }

    /**
     * Sets the GameRegistry contract address for this contract
     *
     * @param gameRegistryAddress  Address for the GameRegistry contract
     */
    function setGameRegistry(address gameRegistryAddress) external onlyOwner {
        _gameRegistry = IGameRegistry(gameRegistryAddress);

        if (gameRegistryAddress == address(0)) {
            revert InvalidGameRegistry();
        }
    }

    /** @return GameRegistry contract for this contract */
    function getGameRegistry() external view returns (IGameRegistry) {
        return _gameRegistry;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(
        address forwarder
    ) public view virtual override(IERC2771Recipient) returns (bool) {
        return
            address(_gameRegistry) != address(0) &&
            _hasAccessRole(TRUSTED_FORWARDER_ROLE, forwarder);
    }

    /**
     * Callback for when a random number request has returned with random words
     *
     * @param requestId     Id of the request
     * @param randomWords   Random words
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external virtual override {
        // Do nothing by default
    }

    /** INTERNAL **/

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasAccessRole(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return _gameRegistry.hasAccessRole(role, account);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!_gameRegistry.hasAccessRole(role, account)) {
            revert MissingRole(account, role);
        }
    }

    /** @return Returns the traits provider for this contract */
    function _traitsProvider() internal view returns (ITraitsProvider) {
        return ITraitsProvider(_getSystem(TRAITS_PROVIDER_ID));
    }

    /** @return Interface to the LockingSystem */
    function _lockingSystem() internal view returns (ILockingSystem) {
        return ILockingSystem(_gameRegistry.getSystem(LOCKING_SYSTEM_ID));
    }

    /** @return Interface to the LootSystem */
    function _lootSystem() internal view returns (ILootSystem) {
        return ILootSystem(_gameRegistry.getSystem(LOOT_SYSTEM_ID));
    }

    /** @return Interface to the Randomizer */
    function _randomizer() internal view returns (IRandomizer) {
        return IRandomizer(_gameRegistry.getSystem(RANDOMIZER_ID));
    }

    /** @return Address for a given system */
    function _getSystem(uint256 systemId) internal view returns (address) {
        return _gameRegistry.getSystem(systemId);
    }

    /**
     * Requests randomness from the game's Randomizer contract
     *
     * @param numWords Number of words to request from the VRF
     *
     * @return Id of the randomness request
     */
    function _requestRandomWords(uint32 numWords) internal returns (uint256) {
        return
            _randomizer().requestRandomWords(
                IRandomizerCallback(this),
                numWords
            );
    }

    /**
     * Returns the Player address for the Operator account
     * @param operatorAccount address of the Operator account to retrieve the player for
     */
    function _getPlayerAccount(
        address operatorAccount
    ) internal view returns (address playerAccount) {
        return _gameRegistry.getPlayerAccount(operatorAccount);
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, IERC2771Recipient)
        returns (address ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, IERC2771Recipient)
        returns (bytes calldata ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    /** PAUSABLE **/

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
    function _pause() internal virtual {
        require(_paused == false, "Pausable: not paused");
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
    function _unpause() internal virtual {
        require(_paused == true, "Pausable: not paused");
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IHoldingConsumer {
    /**
     * @param account Account to check hold time of
     * @param tokenId Id of the token
     * @return The time in seconds a given account has held a token
     */
    function getTimeHeld(
        address account,
        uint256 tokenId
    ) external view returns (uint32);

    /**
     * @param tokenId Id of the token
     * @return The time in seconds a given account has held the token
     */
    function getLastTransfer(uint256 tokenId) external view returns (uint32);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import {ITraitsProvider} from "./ITraitsProvider.sol";

/** @title Consumer of traits, exposes functions to get traits for this contract */
interface ITraitsConsumer {
    /** @return Token name for the given tokenId */
    function tokenName(uint256 tokenId) external view returns (string memory);

    /** @return Token name for the given tokenId */
    function tokenDescription(uint256 tokenId)
        external
        view
        returns (string memory);

    /** @return Image URI for the given tokenId */
    function imageURI(uint256 tokenId) external view returns (string memory);

    /** @return External URI for the given tokenId */
    function externalURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.traitsprovider"));

// Enum describing how the trait can be modified
enum TraitBehavior {
    NOT_INITIALIZED, // Trait has not been initialized
    UNRESTRICTED, // Trait can be changed unrestricted
    IMMUTABLE, // Trait can only be set once and then never changed
    INCREMENT_ONLY, // Trait can only be incremented
    DECREMENT_ONLY // Trait can only be decremented
}

// Type of data to allow in the trait
enum TraitDataType {
    NOT_INITIALIZED, // Trait has not been initialized
    INT, // int256 data type
    UINT, // uint256 data type
    BOOL, // bool data type
    STRING, // string data type
    INT_ARRAY, // int256 array data type
    UINT_ARRAY // uint256 array data type
}

// Holds metadata for a given trait type
struct TraitMetadata {
    // Name of the trait, used in tokenURIs
    string name;
    // How the trait can be modified
    TraitBehavior behavior;
    // Trait type
    TraitDataType dataType;
    // Whether or not the trait is a top-level property and should not be in the attribute array
    bool isTopLevelProperty;
    // Whether or not the trait should be hidden from end-users
    bool hidden;
}

// Used to pass traits around for URI generation
struct TokenURITrait {
    string name;
    bytes value;
    TraitDataType dataType;
    bool isTopLevelProperty;
    bool hidden;
}

/** @title Provides a set of traits to a set of ERC721/ERC1155 contracts */
interface ITraitsProvider is IERC165 {
    /**
     * Sets the value for the string trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitString(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        string calldata value
    ) external;

    /**
     * Sets several string traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitString(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        string[] calldata values
    ) external;

    /**
     * Sets the value for the uint256 trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitUint256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256 value
    ) external;

    /**
     * Sets several uint256 traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitUint256(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        uint256[] calldata values
    ) external;

    /**
     * Sets the value for the int256 trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitInt256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        int256 value
    ) external;

    /**
     * Sets several int256 traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitInt256(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        int256[] calldata values
    ) external;

    /**
     * Sets the value for the int256[] trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitInt256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        int256[] calldata value
    ) external;

    /**
     * Sets the value for the uint256[] trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitUint256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256[] calldata value
    ) external;

    /**
     * Sets the value for the bool trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitBool(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        bool value
    ) external;

    /**
     * Sets several bool traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitBool(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        bool[] calldata values
    ) external;

    /**
     * Increments the trait for a token by the given amount
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to increment trait by
     */
    function incrementTrait(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256 amount
    ) external;

    /**
     * Decrements the trait for a token by the given amount
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to decrement trait by
     */
    function decrementTrait(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256 amount
    ) external;

    /**
     * Returns the trait data for a given token
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     *
     * @return A struct containing all traits for the token
     */
    function getTraitIds(
        address tokenContract,
        uint256 tokenId
    ) external view returns (uint256[] memory);

    /**
     * Retrieves a raw abi-encoded byte data for the given trait
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitBytes(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bytes memory);

    /**
     * Retrieves a int256 trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitInt256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (int256);

    /**
     * Retrieves a int256 array trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitInt256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (int256[] memory);

    /**
     * Retrieves a uint256 trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitUint256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (uint256);

    /**
     * Retrieves a uint256 array trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitUint256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (uint256[] memory);

    /**
     * Retrieves a bool trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitBool(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bool);

    /**
     * Retrieves a string trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitString(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (string memory);

    /**
     * Returns whether or not the given token has a trait
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to retrieve
     *
     * @return Whether or not the token has the trait
     */
    function hasTrait(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bool);

    /**
     * @param traitId  Id of the trait to get metadata for
     * @return Metadata for the given trait
     */
    function getTraitMetadata(
        uint256 traitId
    ) external view returns (TraitMetadata memory);

    /**
     * Generate a tokenURI based on a set of global properties and traits
     *
     * @param tokenContract     Address of the token contract
     * @param tokenId           Id of the token to generate traits for
     *
     * @return base64-encoded fully-formed tokenURI
     */
    function generateTokenURI(
        address tokenContract,
        uint256 tokenId,
        TokenURITrait[] memory extraTraits
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.lockingsystem"));

/// @title Interface for the LockingSystem that allows tokens to be locked by the game to prevent transfer
interface ILockingSystem is IERC165 {
    /**
     * Whether or not an NFT is locked
     *
     * @param tokenContract Token contract address
     * @param tokenId       Id of the token
     */
    function isNFTLocked(address tokenContract, uint256 tokenId)
        external
        view
        returns (bool);

    /**
     * Amount of token locked in the system by a given owner
     *
     * @param account   	  Token owner
     * @param tokenContract	Token contract address
     * @param tokenId       Id of the token
     *
     * @return Number of tokens locked
     */
    function itemAmountLocked(
        address account,
        address tokenContract,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * Amount of tokens available for unlock
     *
     * @param account       Token owner
     * @param tokenContract Token contract address
     * @param tokenId       Id of the token
     *
     * @return Number of tokens locked
     */
    function itemAmountUnlocked(
        address account,
        address tokenContract,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * Whether or not the given items can be transferred
     *
     * @param account   	    Token owner
     * @param tokenContract	    Token contract address
     * @param ids               Ids of the tokens
     * @param amounts           Amounts of the tokens
     *
     * @return Whether or not the given items can be transferred
     */
    function canTransferItems(
        address account,
        address tokenContract,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external view returns (bool);

    /**
     * Lets the game add a reservation to a given NFT, this prevents the NFT from being unlocked
     *
     * @param tokenContract   Token contract address
     * @param tokenId         Token id to reserve
     * @param exclusive       Whether or not the reservation is exclusive. Exclusive reservations prevent other reservations from using the tokens by removing them from the pool.
     * @param data            Data determined by the reserver, can be used to identify the source of the reservation for display in UI
     */
    function addNFTReservation(
        address tokenContract,
        uint256 tokenId,
        bool exclusive,
        uint32 data
    ) external returns (uint32);

    /**
     * Lets the game remove a reservation from a given token
     *
     * @param tokenContract Token contract
     * @param tokenId       Id of the token
     * @param reservationId Id of the reservation to remove
     */
    function removeNFTReservation(
        address tokenContract,
        uint256 tokenId,
        uint32 reservationId
    ) external;

    /**
     * Lets the game add a reservation to a given token, this prevents the token from being unlocked
     *
     * @param account  			    Owner of the token to reserver
     * @param tokenContract   Token contract address
     * @param tokenId  				Token id to reserve
     * @param amount 					Number of tokens to reserve (1 for NFTs, >=1 for ERC1155)
     * @param exclusive				Whether or not the reservation is exclusive. Exclusive reservations prevent other reservations from using the tokens by removing them from the pool.
     * @param data            Data determined by the reserver, can be used to identify the source of the reservation for display in UI
     */
    function addItemReservation(
        address account,
        address tokenContract,
        uint256 tokenId,
        uint256 amount,
        bool exclusive,
        uint32 data
    ) external returns (uint32);

    /**
     * Lets the game remove a reservation from a given token
     *
     * @param account   			Owner to remove reservation from
     * @param tokenContract	Token contract
     * @param tokenId  			Id of the token
     * @param reservationId Id of the reservation to remove
     */
    function removeItemReservation(
        address account,
        address tokenContract,
        uint256 tokenId,
        uint32 reservationId
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.lootsystem"));

/// @title Interface for the LootSystem that gives player loot (tokens, XP, etc) for playing the game
interface ILootSystem is IERC165 {
    // Type of loot
    enum LootType {
        UNDEFINED,
        ERC20,
        ERC721,
        ERC1155,
        LOOT_TABLE,
        CALLBACK
    }

    // Individual loot to grant
    struct Loot {
        // Type of fulfillment (ERC721, ERC1155, ERC20, LOOT_TABLE)
        LootType lootType;
        // Contract to grant tokens from
        address tokenContract;
        // Id of the token to grant (ERC1155/LOOT TABLE/CALLBACK types only)
        uint256 lootId;
        // Amount of token to grant (XP, ERC20, ERC1155)
        uint256 amount;
    }

    /**
     * Grants the given user loot(s), calls VRF to ensure it's truly random
     *
     * @param to          Address to grant loot to
     * @param loots       Loots to grant
     */
    function grantLoot(address to, Loot[] calldata loots) external;

    /**
     * Grants the given user loot(s), calls VRF to ensure it's truly random
     *
     * @param to          Address to grant loot to
     * @param loots       Loots to grant
     * @param randomWord  Optional random word to skip VRF callback if we already have words generated / are in a VRF callback
     */
    function grantLootWithRandomWord(
        address to,
        Loot[] calldata loots,
        uint256 randomWord
    ) external;

    /**
     * Grants the given user loot(s) in batches. Presumes no randomness or loot tables
     *
     * @param to          Address to grant loot to
     * @param loots       Loots to grant
     * @param amount      Amount of each loot to grant
     */
    function batchGrantLootWithoutRandomness(
        address to,
        Loot[] calldata loots,
        uint8 amount
    ) external;

    /**
     * Validate that loots are properly formed. Reverts if the loots are not valid
     *
     * @param loots Loots to validate
     * @return needsVRF Whether or not the loots specified require VRF to generate
     */
    function validateLoots(
        Loot[] calldata loots
    ) external view returns (bool needsVRF);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../combat/BossBattleSystem.sol";

contract BossBattleSystemMock is BossBattleSystem {
    bool public useFullValidationFlag;

    function setFullValidationFlag(bool flag) external {
        require(useFullValidationFlag != flag);
        useFullValidationFlag = flag;
    }

    function getBattle(
        uint256 battleEntity
    ) external view returns (Battle memory) {
        return _getBattle(battleEntity);
    }

    function getEntity(uint256 tokenId) external view returns (uint256) {
        return EntityLibrary.tokenToEntity(address(this), tokenId);
    }

    function getToken(
        uint256 entity
    ) external pure returns (address tokenAddress, uint256 tokenId) {
        return EntityLibrary.entityToToken(entity);
    }

    function getCurrentBattleId() external view returns (uint256) {
        return _getCurrentBattleId();
    }

    function rewindAccountCooldown(uint32 rewindTime) external {
        ICooldownSystem cooldown = ICooldownSystem(
            _getSystem(COOLDOWN_SYSTEM_ID)
        );

        cooldown.reduceCooldown(
            EntityLibrary.addressToEntity(_msgSender()),
            BOSS_BATTLE_COOLDOWN_ID,
            rewindTime
        );
    }

    function rewindShipCooldown(
        uint256 shipEntity,
        uint32 rewindTime
    ) external {
        ICooldownSystem cooldown = ICooldownSystem(
            _getSystem(COOLDOWN_SYSTEM_ID)
        );

        cooldown.reduceCooldown(
            shipEntity,
            BOSS_BATTLE_COOLDOWN_ID,
            rewindTime
        );
    }

    function rewindBattleTimelimit(
        uint256 battleEntity,
        uint32 rewindTime
    ) external {
        ICooldownSystem cooldown = ICooldownSystem(
            _getSystem(COOLDOWN_SYSTEM_ID)
        );

        cooldown.reduceCooldown(
            battleEntity,
            BOSS_BATTLE_COOLDOWN_ID,
            rewindTime
        );
    }

    /**
     * @dev Resolves an active battle with validations
     * @param params Struct of EndBattleParams inputs
     */
    function endBattleMock(
        EndBattleParams calldata params
    ) external nonReentrant {
        // Check caller is executing their own battle || battle entity != 0
        address account = _getPlayerAccount(_msgSender());
        if (
            _getBattleEntity(account) != params.battleEntity ||
            params.battleEntity == 0
        ) {
            revert InvalidCallToEndBattle();
        }

        // Check if call to end-battle still within battle time limit
        if (
            !ICooldownSystem(_getSystem(COOLDOWN_SYSTEM_ID)).isInCooldown(
                params.battleEntity,
                BOSS_BATTLE_COOLDOWN_ID
            )
        ) {
            revert BattleExpired();
        }

        // Get Active battle
        Battle memory battle = _getBattle(params.battleEntity);

        if (
            params.moves.length >
            IGameGlobals(_getSystem(GAME_GLOBALS_ID)).getUint256(
                BOSS_BATTLE_MAX_MOVE_COUNT
            ) ||
            params.moves.length == 0
        ) {
            revert InvalidEndBattleParams();
        }

        ITraitsProvider traitsProvider = _traitsProvider();

        // Get ship starting health & boss starting health
        uint256 shipStartingHealth = battle.defenderCombatable.getCurrentHealth(
            battle.attackerEntity,
            traitsProvider
        );
        uint256 bossStartingHealth = battle.defenderCombatable.getCurrentHealth(
            battle.defenderEntity,
            traitsProvider
        );

        // Record the killing blow
        bool isFinalBlow;
        if (
            bossStartingHealth != 0 &&
            params.totalDamageDealt >= bossStartingHealth
        ) {
            isFinalBlow = true;
            bossEntityToFinalBlow[battle.defenderEntity] = FinalBlow(
                battle.attackerEntity,
                account
            );
        }

        _updateBossBattleCount(
            account,
            battle.defenderEntity,
            params.totalDamageDealt
        );

        // Emit results and set new health values of Boss & Ship
        emit BossBattleResult(
            account,
            battle.attackerEntity,
            battle.defenderEntity,
            params.battleEntity,
            shipStartingHealth,
            params.totalDamageDealt == 0
                ? bossStartingHealth
                : battle.defenderCombatable.decreaseHealth(
                    battle.defenderEntity,
                    params.totalDamageDealt
                ),
            params.totalDamageDealt,
            params.totalDamageTaken,
            isFinalBlow
        );

        // Clear battle record
        _clearBattleEntity(account);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IRandomizerCallback} from "./IRandomizerCallback.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.randomizer"));

interface IRandomizer is IERC165 {
    /**
     * Starts a VRF random number request
     *
     * @param callbackAddress Address to callback with the random numbers
     * @param numWords        Number of words to request from VRF
     *
     * @return requestId for the random number, will be passed to the callback contract
     */
    function requestRandomWords(
        IRandomizerCallback callbackAddress,
        uint32 numWords
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRandomizerCallback {
    /**
     * Callback for when the Chainlink request returns
     *
     * @param requestId     Id of the random word request
     * @param randomWords   Random words that were generated by the VRF
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IGameNFTV2} from "./IGameNFTV2.sol";
import {MANAGER_ROLE} from "../../Constants.sol";

import {ITraitsProvider} from "../../interfaces/ITraitsProvider.sol";

import {ITraitsConsumer, TraitsConsumer, GameRegistryConsumer} from "../../traits/TraitsConsumer.sol";
import {IERC721BeforeTokenTransferHandler} from "../IERC721BeforeTokenTransferHandler.sol";

import {ERC721ContractURI} from "@proofofplay/erc721-extensions/src/ERC721ContractURI.sol";
import {ERC721OperatorFilter} from "@proofofplay/erc721-extensions/src/ERC721OperatorFilter.sol";
import {ERC721MirroredL2} from "@proofofplay/erc721-extensions/src/L2/ERC721MirroredL2.sol";

//todo: can we mix in mirrored on demand?
/** @title NFT base contract for all game NFTs. Exposes traits for the NFT and respects GameRegistry/Soulbound/LockingSystem access control */
contract GameNFTV2 is
    TraitsConsumer,
    ERC721OperatorFilter,
    ERC721MirroredL2,
    ERC721ContractURI,
    IGameNFTV2
{
    /// @notice Whether or not the token has had its traits initialized. Prevents re-initialization when bridging
    mapping(uint256 => bool) private _traitsInitialized;

    /// @notice Max supply for this NFT. If zero, it is unlimited supply.
    uint256 private immutable _maxSupply;

    /// @notice The amount of time a token has been held by a given account
    mapping(uint256 => mapping(address => uint32)) private _timeHeld;

    /// @notice Last transfer time for the token
    mapping(uint256 => uint32) public lastTransfer;

    /** ERRORS **/

    /// @notice Account must be non-null
    error InvalidAccountAddress();

    /// @notice Token id is not valid
    error InvalidTokenId();

    /// @notice tokenId exceeds max supply for this NFT
    error TokenIdExceedsMaxSupply();

    /// @notice Amount to mint exceeds max supply
    error NotEnoughSupply(uint256 needed, uint256 actual);

    /** EVENTS **/

    /// @notice Emitted when time held time is updated
    event TimeHeldSet(uint256 tokenId, address account, uint32 timeHeld);

    /// @notice Emitted when last transfer time is updated
    event LastTransferSet(uint256 tokenId, uint32 lastTransferTime);

    /** SETUP **/

    constructor(
        uint256 tokenMaxSupply,
        string memory name,
        string memory symbol,
        address gameRegistryAddress,
        uint256 id
    ) ERC721(name, symbol) TraitsConsumer(gameRegistryAddress, id) {
        _maxSupply = tokenMaxSupply;
    }

    /** @return Max supply for this token */
    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @param tokenId token id to check
     * @return Whether or not the given tokenId has been minted
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @return Generates a dynamic tokenURI based on the traits associated with the given token
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        // Make sure this still errors according to ERC721 spec
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return _tokenURI(tokenId);
    }

    /**
     * @dev a method that bulk sets initialized imported NFTs
     * @param tokenIds List of TokenIds to be initialized
     */
    function setTraitsInitialized(
        uint256[] calldata tokenIds
    ) external onlyRole(MANAGER_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _traitsInitialized[tokenIds[i]] = true;
        }
    }

    /**
     * @param account Account to check hold time of
     * @param tokenId Id of the token
     * @return The time in seconds a given account has held a token
     */
    function getTimeHeld(
        address account,
        uint256 tokenId
    ) external view override returns (uint32) {
        address owner = ownerOf(tokenId);
        if (account == address(0)) {
            revert InvalidAccountAddress();
        }

        uint32 totalTime = _timeHeld[tokenId][account];

        if (owner == account) {
            uint32 lastTransferTime = lastTransfer[tokenId];
            uint32 currentTime = SafeCast.toUint32(block.timestamp);

            totalTime += (currentTime - lastTransferTime);
        }

        return totalTime;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(IERC165, ERC721, TraitsConsumer)
        returns (bool)
    {
        return
            interfaceId == type(IGameNFTV2).interfaceId ||
            TraitsConsumer.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId);
    }

    /** INTERNAL **/

    /** Initializes traits for the given tokenId */
    function _initializeTraits(uint256 tokenId) internal virtual {
        // Do nothing by default
    }

    /**
     * Mint token to recipient
     *
     * @param to        The recipient of the token
     * @param tokenId   Id of the token to mint
     */
    function _safeMint(address to, uint256 tokenId) internal override {
        if (_maxSupply != 0 && tokenId > _maxSupply) {
            revert TokenIdExceedsMaxSupply();
        }

        if (tokenId == 0) {
            revert InvalidTokenId();
        }

        super._safeMint(to, tokenId);

        // Conditionally initialize traits
        if (_traitsInitialized[tokenId] == false) {
            _initializeTraits(tokenId);
            _traitsInitialized[tokenId] = true;
        }
    }

    /**
     * @notice Checks for soulbound status before transfer
     * @inheritdoc ERC721
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721MirroredL2, ERC721OperatorFilter) {
        // Track hold time
        for (uint256 idx = 0; idx < batchSize; idx++) {
            uint256 tokenId = firstTokenId + idx;
            uint32 lastTransferTime = lastTransfer[tokenId];
            uint32 currentTime = SafeCast.toUint32(block.timestamp);
            if (lastTransferTime > 0) {
                _timeHeld[tokenId][from] += (currentTime - lastTransferTime);
            }
            lastTransfer[tokenId] = currentTime;
        }

        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * Message sender override to get Context to work with meta transactions
     *
     */
    function _msgSender()
        internal
        view
        override(Context, GameRegistryConsumer)
        returns (address)
    {
        return GameRegistryConsumer._msgSender();
    }

    /**
     * Message data override to get Context to work with meta transactions
     *
     */
    function _msgData()
        internal
        view
        override(Context, GameRegistryConsumer)
        returns (bytes memory)
    {
        return GameRegistryConsumer._msgData();
    }

    function _checkRole(
        bytes32 role,
        address account
    ) internal view virtual override(GameRegistryConsumer, ERC721MirroredL2) {
        GameRegistryConsumer._checkRole(role, account);
    }

    function getLastTransfer(
        uint256 tokenId
    ) external view override returns (uint32) {
        return lastTransfer[tokenId];
    }

    function _setTimeHeld(
        uint256 tokenId,
        address account,
        uint32 timeHeld
    ) internal {
        _timeHeld[tokenId][account] = timeHeld;

        emit TimeHeldSet(tokenId, account, timeHeld);
    }

    function _setLastTransfer(
        uint256 tokenId,
        uint32 lastTransferTime
    ) internal {
        lastTransfer[tokenId] = lastTransferTime;

        emit LastTransferSet(tokenId, lastTransferTime);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IHoldingConsumer} from "../../interfaces/IHoldingConsumer.sol";

/**
 * @title Interface for game NFTs that have stats and other properties
 */
interface IGameNFTV2 is IHoldingConsumer, IERC721 {
    /**
     * @param account Account to check hold time of
     * @param tokenId Id of the token
     * @return The time in seconds a given account has held a token
     */
    function getTimeHeld(
        address account,
        uint256 tokenId
    ) external view returns (uint32);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IERC721BeforeTokenTransferHandler {
    /**
     * Before transfer hook for NFTs. Performs any trait checks needed before transfer
     *
     * @param tokenContract     Address of the token contract
     * @param tokenId           Id of the token to generate traits for
     * @param from              From address
     * @param to                To address
     * @param operator          Operator address
     */
    function beforeTokenTransfer(
        address tokenContract,
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import {TokenURITrait} from "../interfaces/ITraitsProvider.sol";

uint256 constant ID = uint256(
    keccak256("game.piratenation.tokentemplatesystem")
);

/**
 * @title Interface to access token template system
 */
interface ITokenTemplateSystem {
    /**
     * @return Whether or not a template has been defined yet
     *
     * @param templateId    TemplateId to check
     */
    function exists(uint256 templateId) external view returns (bool);

    /**
     * Sets a template for a given token
     *
     * @param tokenContract Token contract to set template for
     * @param tokenId       Token id to set template for
     * @param templateId    Id of the template to set
     */
    function setTemplate(
        address tokenContract,
        uint256 tokenId,
        uint256 templateId
    ) external;

    /**
     * @return Returns the template token for the given token contract/token id, if it exists
     *
     * @param tokenContract Token to get the template for
     * @param tokenId to get the template for
     */
    function getTemplate(
        address tokenContract,
        uint256 tokenId
    ) external view returns (address, uint256);

    /**
     * Generates a token URI for a given token that inherits traits from its templates
     *
     * @param tokenContract     Address of the token contract
     * @param tokenId           Id of the token to generate traits for
     *
     * @return base64-encoded fully-formed tokenURI
     */
    function generateTokenURI(
        address tokenContract,
        uint256 tokenId
    ) external view returns (string memory);

    /**
     * Generates a token URI for a given token that inherits traits from its templates
     *
     * @param tokenContract     Address of the token contract
     * @param tokenId           Id of the token to generate traits for
     * @param extraTraits       Dyanmically generated traits to add on to the generated url
     *
     * @return base64-encoded fully-formed tokenURI
     */
    function generateTokenURIWithExtra(
        address tokenContract,
        uint256 tokenId,
        TokenURITrait[] memory extraTraits
    ) external view returns (string memory);

    /**
     * Returns whether or not the given token has a trait recursively
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to retrieve
     *
     * @return Whether or not the token has the trait
     */
    function hasTrait(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bool);

    /**
     * Returns the trait data for a given token and checks the templates
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to retrieve
     *
     * @return Trait value as abi-encoded bytes
     */
    function getTraitBytes(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bytes memory);

    /**
     * Retrieves a int256 trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitInt256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (int256);

    /**
     * Retrieves a uint256 trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitUint256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (uint256);

    /**
     * Retrieves a bool trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitBool(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bool);

    /**
     * Retrieves a string trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitString(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface ITokenURIHandler {
    /**
     * Generates the TokenURI for a given token
     *
     * @param operator          Sender requesting the tokenURI
     * @param tokenContract     TokenContract to get URI for
     * @param tokenId           Id of the token to get URI for
     *
     * @return TokenURI for the given token
     */
    function tokenURI(
        address operator,
        address tokenContract,
        uint256 tokenId
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

import {ERC721ContractURI} from "@proofofplay/erc721-extensions/src/ERC721ContractURI.sol";

import "./gamenft/GameNFTV2.sol";
import {GENERATION_TRAIT_ID, XP_TRAIT_ID, IS_PIRATE_TRAIT_ID, LEVEL_TRAIT_ID, NAME_TRAIT_ID} from "../Constants.sol";
import {MINTER_ROLE} from "../Constants.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.piratenft"));

/** @title The latest PirateNFT */
contract PirateNFTL2 is GameNFTV2 {
    using Strings for uint256;
    error InvalidInput();

    uint256 constant MAX_SUPPLY = 9999;

    constructor(
        address gameRegistryAddress
    ) GameNFTV2(MAX_SUPPLY, "Pirate", "PIRATE", gameRegistryAddress, ID) {
        _defaultDescription = "Take to the seas with your pirate crew! Explore the world and gather XP, loot, and untold riches in a race to become the world's greatest pirate captain! Play at https://piratenation.game";
        _defaultImageURI = "ipfs://QmUeMG7QPySPiBp4hTc9u1FPcq5MKJzyYLgQh1t7FefECX?";
    }

    /**
     * @notice Returns the total supply of the token
     */
    function totalSupply() public view virtual returns (uint256) {
        return MAX_SUPPLY;
    }

    /**
     * @notice Used for bulk minting for initializing our migration
     * @param tokenIds  Array of tokenIds to mint
     * @param addresses Array of addresses to mint to
     */
    function claim(
        uint256[] calldata tokenIds,
        address[] calldata addresses
    ) external onlyRole(MINTER_ROLE) {
        if (tokenIds.length != addresses.length) {
            revert InvalidInput();
        }

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            //todo: can we do optimizations
            if (tokenIds[i] == 0) {
                revert InvalidInput();
            }
            _safeMint(addresses[i], tokenIds[i]);
        }
    }

    /** Initializes traits for the given tokenId */
    function _initializeTraits(uint256 tokenId) internal override {
        ITraitsProvider traitsProvider = _traitsProvider();

        traitsProvider.setTraitUint256(
            address(this),
            tokenId,
            GENERATION_TRAIT_ID,
            0
        );

        traitsProvider.setTraitUint256(address(this), tokenId, XP_TRAIT_ID, 0);

        traitsProvider.setTraitUint256(
            address(this),
            tokenId,
            LEVEL_TRAIT_ID,
            1
        );

        traitsProvider.setTraitBool(
            address(this),
            tokenId,
            IS_PIRATE_TRAIT_ID,
            true
        );
    }

    /** @return Token name for the given tokenId */
    function tokenName(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (_hasTrait(tokenId, NAME_TRAIT_ID) == true) {
            // If token has a name trait set, use that
            return _getTraitString(tokenId, NAME_TRAIT_ID);
        } else {
            return string(abi.encodePacked("Pirate #", tokenId.toString()));
        }
    }

    function batchSetTimeHeld(
        uint256[] calldata tokenIds,
        address[] calldata addresses,
        uint32[] calldata timeHeldValues
    ) external onlyRole(MINTER_ROLE) {
        if (
            tokenIds.length != addresses.length ||
            tokenIds.length != timeHeldValues.length
        ) {
            revert InvalidInput();
        }

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            if (tokenIds[i] == 0) {
                revert InvalidInput();
            }
            // Migrate the amount of time a token has been held by a given account
            _setTimeHeld(tokenIds[i], addresses[i], timeHeldValues[i]);
        }
    }

    function batchSetLastTransfer(
        uint256[] calldata tokenIds,
        uint32[] calldata lastTransferValues
    ) external onlyRole(MINTER_ROLE) {
        if (tokenIds.length != lastTransferValues.length) {
            revert InvalidInput();
        }

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            if (tokenIds[i] == 0) {
                revert InvalidInput();
            }
            // Migrate the last transfer time for the token
            _setLastTransfer(tokenIds[i], lastTransferValues[i]);
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import {IGameNFT} from "../../deprecated/IGameNFT.sol";

/**
 * @title Interface for game NFTs that have stats and other properties
 */
interface IShipNFT is IGameNFT {
    /**
     * Mint a token
     *
     * @param to account to mint to
     * @param id of the token
     */
    function mint(address to, uint256 id) external;

    /**
     * Burn a token - any payment / game logic should be handled in the game contract.
     *
     * @param id        Id of the token to burn
     */
    function burn(uint256 id) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../../deprecated/GameNFT.sol";
import {GENERATION_TRAIT_ID, LEVEL_TRAIT_ID, NAME_TRAIT_ID, IS_SHIP_TRAIT_ID, MINTER_ROLE, GAME_LOGIC_CONTRACT_ROLE} from "../../Constants.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.shipnft"));

/** @title Pirate NFTs on L2 */
contract ShipNFT is GameNFT {
    using Strings for uint256;

    // 0 max supply = infinite
    uint256 constant MAX_SUPPLY = 0;

    constructor(address gameRegistryAddress)
        GameNFT(MAX_SUPPLY, "Ship", "SHIP", gameRegistryAddress, ID)
    {
        _defaultDescription = "Take to the seas with your pirate crew! Explore the world and gather XP, loot, and untold riches in a race to become the world's greatest pirate captain! Play at https://piratenation.game";
        _defaultImageURI = "ipfs://QmUeMG7QPySPiBp4hTc9u1FPcq5MKJzyYLgQh1t7FefECX?";
    }

    /** Initializes traits for the given tokenId */
    function _initializeTraits(uint256 tokenId) internal override {
        ITraitsProvider traitsProvider = _traitsProvider();

        traitsProvider.setTraitBool(
            address(this),
            tokenId,
            IS_SHIP_TRAIT_ID,
            true
        );
    }

    /** @return Token name for the given tokenId */
    function tokenName(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (_hasTrait(tokenId, NAME_TRAIT_ID) == true) {
            // If token has a name trait set, use that
            return _getTraitString(tokenId, NAME_TRAIT_ID);
        } else {
            return string(abi.encodePacked("Ship #", tokenId.toString()));
        }
    }

    /**
     * Mints the ERC721 token
     *
     * @param to        Recipient of the token
     * @param id        Id of token to mint
     */
    function mint(address to, uint256 id)
        external
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        _safeMint(to, id);
    }

    /**
     * Burn a token - any payment / game logic should be handled in the game contract.
     *
     * @param id        Id of the token to burn
     */
    function burn(uint256 id)
        external
        onlyRole(GAME_LOGIC_CONTRACT_ROLE)
        whenNotPaused
    {
        _burn(id);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {GAME_LOGIC_CONTRACT_ROLE, NAME_TRAIT_ID, DESCRIPTION_TRAIT_ID, IMAGE_TRAIT_ID} from "../Constants.sol";

import {ITraitsConsumer} from "../interfaces/ITraitsConsumer.sol";
import {ITokenURIHandler} from "../tokens/ITokenURIHandler.sol";
import {GameRegistryConsumer} from "../GameRegistryConsumer.sol";

/** @title Contract that lets a child contract access the TraitsProvider contract */
abstract contract TraitsConsumer is
    ITraitsConsumer,
    GameRegistryConsumer,
    IERC165
{
    using Strings for uint256;

    /// @notice Override URI for the NFT contract. If not set, on-chain data is used instead
    string public _overrideURI;

    /// @notice Pointer to the handler for TokenURI calls
    address public tokenURIHandler;

    /// @notice Base URI for images, tokenId is appended to make final uri
    string public _baseImageURI;

    /// @notice Base URI for external link, tokenId is appended to make final uri
    string public _baseExternalURI;

    /// @notice Default image URI for the token
    /// @dev Should be set in the constructor
    string public _defaultImageURI;

    /// @notice Default description for the token
    string public _defaultDescription;

    /** ERRORS */

    /// @notice traitsProviderAddress does not implement ITraitsProvvider
    error InvalidTraitsProvider();

    /** SETUP **/

    /** Set game registry  */
    constructor(
        address _gameRegistryAddress,
        uint256 _id
    ) GameRegistryConsumer(_gameRegistryAddress, _id) {}

    /** Sets the override URI for the tokens */
    function setURI(string calldata newURI) external onlyOwner {
        _overrideURI = newURI;
    }

    /** Sets base image URI for the tokens */
    function setBaseImageURI(string calldata newURI) external onlyOwner {
        _baseImageURI = newURI;
    }

    /** Sets base external URI for the tokens */
    function setBaseExternalURI(string calldata newURI) external onlyOwner {
        _baseExternalURI = newURI;
    }

    /** @return Token name for the given tokenId */
    function tokenName(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        if (_hasTrait(tokenId, NAME_TRAIT_ID)) {
            // If token has a name trait set, use that
            return _getTraitString(tokenId, NAME_TRAIT_ID);
        } else {
            return string(abi.encodePacked("#", tokenId.toString()));
        }
    }

    /** @return Token name for the given tokenId */
    function tokenDescription(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        if (_hasTrait(tokenId, DESCRIPTION_TRAIT_ID)) {
            // If token has a description trait set, use that
            return _getTraitString(tokenId, DESCRIPTION_TRAIT_ID);
        }

        return _defaultDescription;
    }

    /** @return Image URI for the given tokenId */
    function imageURI(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        if (_hasTrait(tokenId, IMAGE_TRAIT_ID)) {
            // If token has a description trait set, use that
            return _getTraitString(tokenId, IMAGE_TRAIT_ID);
        }

        if (bytes(_baseImageURI).length > 0) {
            return string(abi.encodePacked(_baseImageURI, tokenId.toString()));
        }

        return _defaultImageURI;
    }

    /** @return External URI for the given tokenId */
    function externalURI(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        if (bytes(_baseExternalURI).length > 0) {
            return
                string(abi.encodePacked(_baseExternalURI, tokenId.toString()));
        }

        return "";
    }

    /**
     * Sets the tokenURI handler for this token
     *
     * @param handler  Address of the handler contract to use
     */
    function setTokenURIHandler(address handler) external onlyOwner {
        tokenURIHandler = handler;
    }

    /** INTERNAL **/

    /**
     * @param tokenId Id of the token to get a trait value for
     * @param traitId Id of the trait to get the value for
     *
     * @return Trait int256 value for the given token and trait
     */
    function _getTraitInt256(
        uint256 tokenId,
        uint256 traitId
    ) internal view returns (int256) {
        return
            _traitsProvider().getTraitInt256(address(this), tokenId, traitId);
    }

    /**
     * @param tokenId Id of the token to get a trait value for
     * @param traitId Id of the trait to get the value for
     *
     * @return Trait string value for the given token and trait
     */
    function _getTraitString(
        uint256 tokenId,
        uint256 traitId
    ) internal view returns (string memory) {
        return
            _traitsProvider().getTraitString(address(this), tokenId, traitId);
    }

    /**
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to retrieve
     *
     * @return Whether or not the token has the trait
     */
    function _hasTrait(
        uint256 tokenId,
        uint256 traitId
    ) internal view returns (bool) {
        return _traitsProvider().hasTrait(address(this), tokenId, traitId);
    }

    /**
     * Sets the int256 trait value for this token
     *
     * @param tokenId Id of the token to set trait for
     * @param traitId Id of the trait to set
     * @param value   New value of the trait
     */
    function _setTraitInt256(
        uint256 tokenId,
        uint256 traitId,
        int256 value
    ) internal {
        _traitsProvider().setTraitInt256(
            address(this),
            tokenId,
            traitId,
            value
        );
    }

    /**
     * Sets the string trait value for this token
     *
     * @param tokenId Id of the token to set trait for
     * @param traitId Id of the trait to set
     * @param value   New value of the trait
     */
    function _setTraitString(
        uint256 tokenId,
        uint256 traitId,
        string memory value
    ) internal {
        _traitsProvider().setTraitString(
            address(this),
            tokenId,
            traitId,
            value
        );
    }

    /**
     * @notice Generates metadata for the given tokenId
     * @param tokenId  Token to generate metadata for
     * @return A base64 encoded JSON metadata string
     */
    function _tokenURI(
        uint256 tokenId
    ) internal view virtual returns (string memory) {
        // If override URI is set, return the URI with tokenId appended instead of on-chain data
        if (bytes(_overrideURI).length > 0) {
            return string(abi.encodePacked(_overrideURI, tokenId.toString()));
        }

        if (tokenURIHandler == address(0)) {
            return "";
        }

        return
            ITokenURIHandler(tokenURIHandler).tokenURI(
                _msgSender(),
                address(this),
                tokenId
            );
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(ITraitsConsumer).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}