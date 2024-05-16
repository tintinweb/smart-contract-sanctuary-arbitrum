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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
pragma solidity =0.8.19;
pragma abicoder v2;

import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { IERC721ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import { IMasterCakepie } from "../../interfaces/cakepie/IMasterCakepie.sol";

import { INonfungiblePositionManager } from "../../interfaces/pancakeswap/INonfungiblePositionManager.sol";
import { INonfungiblePositionManagerStruct } from "../../interfaces/pancakeswap/INonfungiblePositionManagerStruct.sol";
import { IMasterChefV3 } from "../../interfaces/pancakeswap/IMasterChefV3.sol";
import { IALMWrapper } from "../../interfaces/pancakeswap/IALMWrapper.sol";
import { IAdapter } from "../../interfaces/pancakeswap/IAdapter.sol";
import { IV2Wrapper } from "../../interfaces/pancakeswap/IV2Wrapper.sol";

import { ERC20FactoryLib } from "../../libraries/cakepie/ERC20FactoryLib.sol";
import { IMintableERC20 } from "../../interfaces/common/IMintableERC20.sol";
import { IRewardDistributor } from "../../interfaces/cakepie/IRewardDistributor.sol";
import { IPancakeV3PoolImmutables } from "../../interfaces/pancakeswap/IPancakeV3PoolImmutables.sol";
import { IPancakeV3Helper } from "../../interfaces/cakepie/IPancakeV3Helper.sol";
import "../../interfaces/cakepie/IBaseRewardPool.sol";

/// @title PancakeStakingBaseUpg
/// @notice PancakeStakingBaseUpg is the base contract that holds cakepie common features across all supported chains (BNB, ETH, ARB)
///         PancakeStakingBaseUpg is the main contract interacting with pancakeswap
/// @author Magpie Team

abstract contract PancakeStakingBaseUpg is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IERC721ReceiverUpgradeable
{
    using SafeERC20 for IERC20;

    /* ============ Structs ============ */

    struct Pool {
        address poolAddress; // For V2, V3, it's Lp address, for AML it's wrapper addresss
        address depositToken; // For V2, it's Lp address, For V3 it's single side token, For AML pools it's single side token address else Address(0)
        address rewarder; // only for V2 and AML,
        address receiptToken; // only for V2 and AML,
        uint256 lastHarvestTime; // only for V2 and AML,
        uint256 poolType; // specifying V2, V3 or AML pool
        uint256 v3Liquidity; // tracker for totla v3 liquidity
        bool isAmount0; // only applicable for AML pool, if the deposit token is token0 or token1 then true or false correspondingly , if the deposit token is Address(0) then false
        bool isNative;
        bool isActive;
    }

    /* ============ State Variables ============ */
    // Cakepie core addresses
    IERC20 public CAKE;
    IERC20 public mCake;
    address public voteManager;

    // IMasterCakepie public marketDepositHelper;
    IMasterCakepie public masterCakepie;
    IRewardDistributor public rewardDistributor;

    address public pancakeV3Helper;
    address public pancakeV2LPHelper;
    address public pancakeAMLHelper;

    // Pancake address to interact
    INonfungiblePositionManager public nonfungiblePositionManager; // For V3 pool
    IMasterChefV3 public masterChefV3; // For V3 pool

    mapping(address => Pool) public pools;
    address[] public poolList;
    uint256 public poolLength;

    uint256 public harvestTimeGap;

    mapping(address => bool) public allowedOperator;

    // 1st upgrade
    uint256 public V3Type;
    uint256 public V2Type;
    uint256 public AMLType;

    // 2nd upgrade
    uint256 public StableSwapType;

    uint256[46] private __gap;

    /* ============ Events ============ */

    event PoolAdded(address _poolAddress, address _rewarder, address _receiptToken);
    event NewTokenStaked(
        address indexed _user,
        address indexed _poolAddress,
        uint256 _tokenID,
        uint256 _liquidity
    );
    event NewTokenUnstaked(
        address indexed _user,
        address indexed _poolAddress,
        uint256 _tokenID,
        uint256 _liquidity
    );

    event NewV2Deposit(
        address indexed _user,
        address indexed _pool,
        uint256 _amount,
        address indexed _receptToken,
        uint256 _receptAmount
    );
    event NewAMLV2Withdraw(
        address indexed _user,
        address indexed _pool,
        uint256 _amount,
        address indexed _receptToken,
        uint256 _receptAmount
    );

    event NewAMLV3Deposit(
        address indexed _user,
        address indexed _pool,
        uint256 _amount0,
        uint256 _amount1,
        address indexed _receptToken,
        uint256 _receptAmount
    );

    event NewAMLV3Withdraw(
        address indexed _user,
        address indexed _pool,
        uint256 _amount,
        address indexed _receptToken,
        uint256 _receptAmount
    );

    event AllowedOperatorSet(address _operator, bool _active);
    event VoteManagerSet(address _oldVoteManager, address _newVoteManager);
    event V3PoolFeesPaidTo(
        address indexed _user,
        uint256 _positionId,
        address _token,
        uint256 _feeAmount
    );

    /* ============ Errors ============ */

    error OnlyFarmHelper();
    error OnlyActivePool();
    error PoolOccupied();
    error TimeGapTooMuch();
    error OnlyAMLHelper();
    error OnlyVoteManager();
    error LengthMismatch();
    error OnlyAllowedOperator();
    error InvalidPoolType();
    /* ============ Constructor ============ */

    function __PancakeStakingBaseUpg_init(
        address _CAKE,
        address _mCake,
        address _masterCakepie
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        CAKE = IERC20(_CAKE);
        mCake = IERC20(_mCake);
        masterCakepie = IMasterCakepie(_masterCakepie);
    }

    /* ============ Modifiers ============ */

    modifier _onlyPoolHelper(address _helper) {
        if (msg.sender != _helper) {
            revert("OnlyHelper");
        }
        _;
    }

    modifier _onlyAllowedOperator() {
        if (!allowedOperator[msg.sender]) revert OnlyAllowedOperator();
        _;
    }

    /* ============ External Functions ============ */

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function depositV3For(
        address _for,
        address _v3Pool,
        uint256 _tokenId
    ) external nonReentrant whenNotPaused _onlyPoolHelper(pancakeV3Helper) {
        Pool storage poolInfo = pools[_v3Pool];

        (, , , , , , , uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(_tokenId);

        nonfungiblePositionManager.safeTransferFrom(_for, address(this), _tokenId);
        nonfungiblePositionManager.safeTransferFrom(address(this), address(masterChefV3), _tokenId);

        emit NewTokenStaked(_for, poolInfo.poolAddress, _tokenId, liquidity);
    }

    function withdrawV3For(
        address _for,
        address _v3Pool,
        uint256 _tokenId
    ) external nonReentrant whenNotPaused _onlyPoolHelper(pancakeV3Helper) {
        Pool storage poolInfo = pools[_v3Pool];

        (uint256[] memory tokenId, ) = _toArray(_tokenId, address(0));

        (, , , , , , , uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(_tokenId);

        _harvestV3PoolFees(_for, tokenId);

        uint256 balBefore = IERC20(CAKE).balanceOf(address(this));

        masterChefV3.withdraw(_tokenId, address(this));

        _handleRewards(poolInfo.poolAddress, address(CAKE), balBefore, _for, false);

        INonfungiblePositionManager(nonfungiblePositionManager).safeTransferFrom(
            address(this),
            _for,
            _tokenId
        );

        emit NewTokenUnstaked(_for, poolInfo.poolAddress, _tokenId, liquidity);
    }

    function increaseLiquidityV3For(
        address _for,
        address _v3Pool,
        IMasterChefV3.IncreaseLiquidityParams calldata params
    ) external nonReentrant whenNotPaused _onlyPoolHelper(pancakeV3Helper) {
        Pool storage poolInfo = pools[_v3Pool];

        address token0 = IPancakeV3PoolImmutables(poolInfo.poolAddress).token0();
        address token1 = IPancakeV3PoolImmutables(poolInfo.poolAddress).token1();

        (uint256 balBeforeToken0, uint256 balBeforeToken1) = _checkTokenBalances(token0, token1);

        IERC20(token0).safeTransferFrom(msg.sender, address(this), params.amount0Desired);
        IERC20(token0).safeIncreaseAllowance(address(masterChefV3), params.amount0Desired);

        IERC20(token1).safeTransferFrom(msg.sender, address(this), params.amount1Desired);
        IERC20(token1).safeIncreaseAllowance(address(masterChefV3), params.amount1Desired);

        masterChefV3.increaseLiquidity(params);

        _refund(token0, _for, balBeforeToken0);
        _refund(token1, _for, balBeforeToken1);
    }

    function decreaseLiquidityV3For(
        address _for,
        address _v3Pool,
        IMasterChefV3.DecreaseLiquidityParams calldata params
    ) external nonReentrant whenNotPaused _onlyPoolHelper(pancakeV3Helper) {
        Pool storage poolInfo = pools[_v3Pool];

        (uint256[] memory tokenId, ) = _toArray(params.tokenId, address(0));

        masterChefV3.decreaseLiquidity(params);

        _harvestV3PoolFees(_for, tokenId);
    }

    function depositV2LPFor(
        address _for,
        address _pool,
        uint256 _amount
    ) external nonReentrant whenNotPaused _onlyPoolHelper(pancakeV2LPHelper) {
        Pool storage poolInfo = pools[_pool];

        IERC20(poolInfo.depositToken).safeTransferFrom(_for, address(this), _amount);
        IERC20(poolInfo.depositToken).safeIncreaseAllowance(poolInfo.poolAddress, _amount);

        uint256 balBefore = IERC20(CAKE).balanceOf(address(this));

        IV2Wrapper(poolInfo.poolAddress).deposit(_amount, false);

        _handleRewards(poolInfo.poolAddress, address(CAKE), balBefore, poolInfo.rewarder, true);

        IMintableERC20(poolInfo.receiptToken).mint(_for, _amount);

        emit NewV2Deposit(_for, poolInfo.poolAddress, _amount, poolInfo.receiptToken, _amount);
    }

    function withdrawV2LPFor(
        address _for,
        address _pool,
        uint256 _amount
    ) external nonReentrant whenNotPaused _onlyPoolHelper(pancakeV2LPHelper) {
        Pool storage poolInfo = pools[_pool];

        uint256 balBefore = IERC20(CAKE).balanceOf(address(this));

        IV2Wrapper(poolInfo.poolAddress).withdraw(_amount, false);

        _handleRewards(poolInfo.poolAddress, address(CAKE), balBefore, poolInfo.rewarder, true);

        IMintableERC20(poolInfo.receiptToken).burn(_for, _amount);

        IERC20(poolInfo.depositToken).safeTransfer(_for, _amount);

        emit NewAMLV2Withdraw(_for, poolInfo.poolAddress, _amount, poolInfo.receiptToken, _amount);
    }

    function depositAMLFor(
        address _for,
        address _pool,
        uint256 _amount0,
        uint256 _amount1
    ) external nonReentrant whenNotPaused _onlyPoolHelper(pancakeAMLHelper) {
        Pool memory poolInfo = pools[_pool];
        uint256 balBefore = IERC20(CAKE).balanceOf(address(this));
        (uint256 _liquidityBefore, ) = IALMWrapper(poolInfo.poolAddress).userInfo(address(this));

        _depositTokens(_for, poolInfo, _amount0, _amount1);

        (uint256 _liquidityAfter, ) = IALMWrapper(poolInfo.poolAddress).userInfo(address(this));
        _handleRewards(poolInfo.poolAddress, address(CAKE), balBefore, poolInfo.rewarder, true);
        IMintableERC20(poolInfo.receiptToken).mint(_for, _liquidityAfter - _liquidityBefore);

        emit NewAMLV3Deposit(
            _for,
            _pool,
            _amount0,
            _amount1,
            poolInfo.receiptToken,
            _liquidityAfter - _liquidityBefore
        );
    }

    function withdrawAMLFor(
        address _for,
        address _pool,
        uint256 _amount
    ) external nonReentrant whenNotPaused _onlyPoolHelper(pancakeAMLHelper) {
        Pool storage poolInfo = pools[_pool];

        address _adpaterAddress = IALMWrapper(poolInfo.poolAddress).adapterAddr();

        address token0 = IAdapter(_adpaterAddress).token0();
        address token1 = IAdapter(_adpaterAddress).token1();

        (, address[] memory poolAddressed) = _toArray(0, address(poolInfo.poolAddress));
        // We have to harvest first since CAKE token can be reward or liquidity
        _harvestLP(poolAddressed, false);

        _handleWithdrawAML(_for, poolInfo.poolAddress, _amount, token0, token1, poolInfo.rewarder);

        IMintableERC20(poolInfo.receiptToken).burn(_for, _amount);

        emit NewAMLV3Withdraw(_for, poolInfo.poolAddress, _amount, poolInfo.receiptToken, _amount);
    }

    function harvestV3(
        address _for,
        uint256[] memory _tokenIds
    ) external nonReentrant _onlyPoolHelper(pancakeV3Helper) {
        _harvestV3(_for, _tokenIds);
    }

    function harvestV3PoolFees(
        address _for,
        uint256[] memory _tokenIds
    ) external nonReentrant _onlyPoolHelper(pancakeV3Helper) {
        _harvestV3PoolFees(_for, _tokenIds);
    }

    function harvestV2LP(address[] memory _pool) external nonReentrant {
        _harvestLP(_pool, true);
    }

    function harvestAML(address[] memory _pool) external nonReentrant {
        _harvestLP(_pool, false);
    }

    function genericHarvest(address _pool) external nonReentrant {
        Pool storage poolInfo = pools[_pool];

        address[] memory poolsToHarvest = new address[](1);
        poolsToHarvest[0] = _pool;

        if (poolInfo.poolType == V3Type) revert InvalidPoolType();
        else if (poolInfo.poolType == V2Type || poolInfo.poolType == StableSwapType) _harvestLP(poolsToHarvest, true);
        else if (poolInfo.poolType == AMLType) _harvestLP(poolsToHarvest, false);
        else revert InvalidPoolType();
    }

    /* ============ Admin Functions ============ */

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function registerPool(
        address _poolAddress, // can be V3, V2 or AML Wrapper
        uint256 _allocPoints, // only for V2 and AML
        address _depositToken, // for V2, it's LP, for AML it's single side token, not applicable for V3
        uint256 _poolType,
        string memory _name,
        string memory _symbol,
        bool _isAmount0, // only applicable for AML
        bool _isNative
    ) external onlyOwner {
        if (pools[_poolAddress].isActive != false) revert PoolOccupied();

        if (_poolType != V3Type && _poolType != V2Type && _poolType != AMLType && _poolType != StableSwapType)
            revert InvalidPoolType();

        IERC20 newToken;
        address rewarder;

        if (_poolType != V3Type) {
            newToken = IERC20(
                ERC20FactoryLib.createReceipt(
                    _poolAddress,
                    address(masterCakepie),
                    address(this),
                    _name,
                    _symbol
                )
            );

            rewarder = masterCakepie.createRewarder(
                address(newToken),
                address(CAKE),
                address(rewardDistributor)
            );
        }

        // for v3 pool, we just registered the token address
        IMasterCakepie(masterCakepie).add(
            _poolType == V3Type ? 0 : _allocPoints,
            address(_poolAddress),
            address(newToken),
            address(rewarder),
            _poolType == V3Type ? true : false
        );

        pools[_poolAddress] = Pool({
            poolAddress: _poolAddress,
            depositToken: _poolType == V3Type ? address(0) : _depositToken,
            rewarder: address(rewarder),
            receiptToken: address(newToken),
            lastHarvestTime: block.timestamp,
            v3Liquidity: 0,
            poolType: _poolType,
            isAmount0: _isAmount0,
            isNative: _isNative,
            isActive: true
        });

        poolList.push(_poolAddress);
        poolLength += 1;

        emit PoolAdded(_poolAddress, address(rewarder), address(newToken));
    }

    function setPool(
        address _poolAddress, // can be V3, V2 or AML Wrapper
        uint256 _allocPoints, // only for V2 and AML
        address _depositToken, // for V2, it's LP, for AML it's single side token, not applicable for V3
        uint256 _poolType,
        bool _isAmount0, // only applicable for AML
        bool _isNative,
        address _rewarder
    ) external onlyOwner {
        Pool storage pool = pools[_poolAddress];

        pool.depositToken = _depositToken;
        pool.poolType = _poolType;
        pool.isAmount0 = _isAmount0;
        pool.isNative = _isNative;
        pool.rewarder = _rewarder;

        IMasterCakepie(masterCakepie).set(
            _poolAddress,
            _allocPoints,
            _rewarder
        );
    }

    function setHarvestTimeGap(uint256 _period) external onlyOwner {
        if (_period > 4 hours) revert TimeGapTooMuch();

        harvestTimeGap = _period;
    }

    function config(
        address _masterChefV3,
        address _masterCakepie,
        address _nonfungiblePositionManager,
        address _rewardDistributor,
        address _pancakeV3Helper,
        address _pancakeV2LPHelper,
        address _pancakeAMLHelper
    ) external onlyOwner {
        masterChefV3 = IMasterChefV3(_masterChefV3);
        masterCakepie = IMasterCakepie(_masterCakepie);
        nonfungiblePositionManager = INonfungiblePositionManager(_nonfungiblePositionManager);
        rewardDistributor = IRewardDistributor(_rewardDistributor);
        pancakeV3Helper = _pancakeV3Helper;
        pancakeV2LPHelper = _pancakeV2LPHelper;
        pancakeAMLHelper = _pancakeAMLHelper;

        V3Type = 1;
        V2Type = 2;
        AMLType = 3;
        StableSwapType = 0;
    }

    function setVoteManager(address _newVoteManager) external onlyOwner {
        address oldVoteManager = voteManager;
        voteManager = _newVoteManager;

        emit VoteManagerSet(oldVoteManager, _newVoteManager);
    }

    function setAllowedOperator(address _operator, bool _active) external onlyOwner {
        allowedOperator[_operator] = _active;
        emit AllowedOperatorSet(_operator, _active);
    }

    /* ============ Internal Functions ============ */

    function _harvestV3(address _for, uint256[] memory _tokenIds) internal {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            (, , , , , , , uint256 pid, ) = IMasterChefV3(masterChefV3).userPositionInfos(
                _tokenIds[i]
            );

            (, address _pool, , , , , ) = IMasterChefV3(masterChefV3).poolInfo(pid);

            uint256 balBefore = IERC20(CAKE).balanceOf(address(this));

            IMasterChefV3(masterChefV3).harvest(_tokenIds[i], address(this));

            _handleRewards(_pool, address(CAKE), balBefore, _for, false);
        }
    }

    // this function is shared by V2,StableSwap and AML pools
    function _harvestLP(address[] memory poolAddresses, bool _isV2) internal {
        for (uint256 i = 0; i < poolAddresses.length; i++) {
            Pool storage poolInfo = pools[poolAddresses[i]];
            if (!poolInfo.isActive) continue;

            if (poolInfo.lastHarvestTime + harvestTimeGap > block.timestamp) return;

            poolInfo.lastHarvestTime = block.timestamp;

            uint256 balBefore = IERC20(CAKE).balanceOf(address(this));

            if (_isV2) IV2Wrapper(poolInfo.poolAddress).deposit(0, false);
            else IALMWrapper(poolInfo.poolAddress).deposit(0, false);

            _handleRewards(poolInfo.poolAddress, address(CAKE), balBefore, poolInfo.rewarder, true);
        }
    }

    function _harvestV3PoolFees(address _for, uint256[] memory _tokenIds) internal {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            (, , address token0, address token1, , , , , , , , ) = INonfungiblePositionManager(
                nonfungiblePositionManager
            ).positions(_tokenIds[i]);

            (uint256 token0BalBefore, uint256 token1BalBefore) = _checkTokenBalances(
                token0,
                token1
            );

            INonfungiblePositionManagerStruct.CollectParams
                memory params = INonfungiblePositionManagerStruct.CollectParams({
                    tokenId: _tokenIds[i],
                    recipient: address(this),
                    amount0Max: 340282366920938463463374607431768211455,
                    amount1Max: 340282366920938463463374607431768211455
                });

            IMasterChefV3(masterChefV3).collect(params);
            (uint256 token0BalAfter, uint256 token1BalAfter) = _checkTokenBalances(token0, token1);

            // Since fee is not boosted, simply transfer to owner
            uint256 diff0 = token0BalAfter - token0BalBefore;
            if (diff0 > 0) {
                IERC20(token0).safeTransfer(_for, diff0);
                emit V3PoolFeesPaidTo(_for, _tokenIds[i], token0, diff0);
            }

            uint256 diff1 = token1BalAfter - token1BalBefore;
            if (diff1 > 0) {
                IERC20(token1).safeTransfer(_for, diff1);
                emit V3PoolFeesPaidTo(_for, _tokenIds[i], token1, diff1);
            }
        }
    }

    function _handleWithdrawAML(
        address _for,
        address _pool,
        uint256 _amount,
        address _token0,
        address _token1,
        address _rewarder
    ) internal {
        uint256 balBefore = IERC20(CAKE).balanceOf(address(this));

        (uint256 balBeforeToken0, uint256 balBeforeToken1) = _checkTokenBalances(_token0, _token1);
        IALMWrapper(_pool).withdrawThenBurn(_amount, false, "");
        (uint256 balAfterToken0, uint256 balAfterToken1) = _checkTokenBalances(_token0, _token1);

        IERC20(_token0).safeTransfer(_for, balAfterToken0 - balBeforeToken0);
        IERC20(_token1).safeTransfer(_for, balAfterToken1 - balBeforeToken1);

        _handleRewards(_pool, address(CAKE), balBefore, _rewarder, true);
    }

    function _handleRewards(
        address _poolAddress,
        address _rewardToken,
        uint256 _balBefore,
        address _to,
        bool _isRewarder
    ) internal {
        uint256 _pendingRewards = IERC20(_rewardToken).balanceOf(address(this)) - _balBefore;
        if (_pendingRewards > 0) {
            IERC20(_rewardToken).safeIncreaseAllowance(address(rewardDistributor), _pendingRewards);
            IRewardDistributor(rewardDistributor).sendRewards(
                _poolAddress,
                _rewardToken,
                _to,
                _pendingRewards,
                _isRewarder
            );
        }
    }

    function _toArray(
        uint256 _tokenId,
        address _poolAddress
    ) internal pure returns (uint256[] memory tokenId, address[] memory poolAddress) {
        tokenId = new uint256[](1);
        tokenId[0] = _tokenId;

        poolAddress = new address[](1);
        poolAddress[0] = _poolAddress;
    }

    function _checkTokenBalances(
        address _token0,
        address _token1
    ) internal view returns (uint256, uint256) {
        uint256 balBeforeToken0 = IERC20(_token0).balanceOf(address(this));
        uint256 balBeforeToken1 = IERC20(_token1).balanceOf(address(this));

        return (balBeforeToken0, balBeforeToken1);
    }

    function _refund(address _token, address _dustTo, uint256 _balBeforeToken) internal {
        uint256 dustTokenAmt = IERC20(_token).balanceOf(address(this)) - _balBeforeToken;
        if (dustTokenAmt > 0) IERC20(_token).safeTransfer(_dustTo, dustTokenAmt);
    }

    function _depositTokens(
        address _for,
        Pool memory _poolInfo,
        uint256 _amount0,
        uint256 _amount1
    ) internal {

        address adapterAddress = IALMWrapper(_poolInfo.poolAddress).adapterAddr();

        if (_amount0 > 0) {
            address token0 = IAdapter(adapterAddress).token0();
            IERC20(token0).safeTransferFrom(_for, address(this), _amount0);
            IERC20(token0).safeIncreaseAllowance(_poolInfo.poolAddress, _amount0);
        }

        if (_amount1 > 0) {
            address token1 = IAdapter(adapterAddress).token1();
            IERC20(token1).safeTransferFrom(_for, address(this), _amount1);
            IERC20(token1).safeIncreaseAllowance(_poolInfo.poolAddress, _amount1);
        }

        IALMWrapper(_poolInfo.poolAddress).mintThenDeposit(_amount0, _amount1, false, "");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;
pragma abicoder v2;

import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { PancakeStakingBaseUpg } from "../baseupgs/PancakeStakingBaseUpg.sol";

/// @title PancakeStaking
/// @notice PancakeStaking is the main contract interacting with pancakeswap side.
/// @author Magpie Team

contract PancakeStakingSideChain is PancakeStakingBaseUpg {
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    address public mCakeConvertorSideChain;

    /* ============ Events ============ */

    event mCakeConvertorSet(address _mCakeConvertor);

    /* ============ Errors ============ */

    error AddressZero();

    /* ============ Constructor ============ */

    receive() external payable {}

    constructor() {
        _disableInitializers();
    }

    function __PancakeStakingSideChain_init(
        address _CAKE,
        address _mCake,
        address _masterCakepie
    ) public initializer {
        __PancakeStakingBaseUpg_init(_CAKE, _mCake, _masterCakepie);
    }

    /* ============ Modifiers ============ */

    /* ============ Admin Functions ============ */

    function setMCakeConvertorSideChain(address _mCakeConvertoSideChain) external onlyOwner {
        if (_mCakeConvertoSideChain == address(0)) revert AddressZero();
        mCakeConvertorSideChain = _mCakeConvertoSideChain;
        emit mCakeConvertorSet(mCakeConvertorSideChain);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMasterCakepie } from "../../interfaces/cakepie/IMasterCakepie.sol";

import { IBaseRewardPool } from "../../interfaces/cakepie/IBaseRewardPool.sol";

/// @title A contract for managing rewards for a pool
/// @author Magpie Team
/// @notice You can use this contract for getting informations about rewards for a specific pools
contract BaseRewardPoolV3 is Ownable, IBaseRewardPool {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    uint256 public constant DENOMINATOR = 10 ** 12;

    address public immutable receiptToken;
    address public immutable operator; // master Radpie
    uint256 public immutable receiptTokenDecimals;

    address[] public rewardTokens;

    struct Reward {
        uint256 rewardPerTokenStored; // will apply a DENOMINATOR to prevent underflow
        uint256 queuedRewards;
    }

    struct UserInfo {
        uint256 userRewardPerTokenPaid;
        uint256 userRewards;
    }

    mapping(address => Reward) public rewards; // [rewardToken]
    // amount by [rewardToken][account],
    mapping(address => mapping(address => UserInfo)) public userInfos;
    mapping(address => bool) public isRewardToken;
    mapping(address => bool) public rewardQueuers;

    /* ============ Events ============ */

    event RewardAdded(uint256 _reward, address indexed _token);
    event Staked(address indexed _user, uint256 _amount);
    event Withdrawn(address indexed _user, uint256 _amount);
    event RewardPaid(
        address indexed _user,
        address indexed _receiver,
        uint256 _reward,
        address indexed _token
    );
    event RewardQueuerUpdated(address indexed _manager, bool _allowed);
    event EmergencyWithdrawn(address indexed _to, uint256 _amount);

    /* ============ Errors ============ */

    error OnlyRewardQueuer();
    error OnlyMasterRadpie();
    error NotAllowZeroAddress();
    error MustBeRewardToken();

    /* ============ Constructor ============ */

    constructor(
        address _receiptToken,
        address _rewardToken,
        address _masterRadpie,
        address _rewardQueuer
    ) {
        if (
            _receiptToken == address(0) ||
            _masterRadpie == address(0) ||
            _rewardQueuer == address(0)
        ) revert NotAllowZeroAddress();

        receiptToken = _receiptToken;
        receiptTokenDecimals = IERC20Metadata(receiptToken).decimals();
        operator = _masterRadpie;

        if (_rewardToken != address(0)) {
            rewards[_rewardToken] = Reward({ rewardPerTokenStored: 0, queuedRewards: 0 });
            rewardTokens.push(_rewardToken);

            isRewardToken[_rewardToken] = true;
        }

        rewardQueuers[_rewardQueuer] = true;
    }

    /* ============ Modifiers ============ */

    modifier onlyRewardQueuer() {
        if (!rewardQueuers[msg.sender]) revert OnlyRewardQueuer();
        _;
    }

    modifier onlyMasterRadpie() {
        if (msg.sender != operator) revert OnlyMasterRadpie();
        _;
    }

    modifier updateReward(address _account) {
        _updateFor(_account);
        _;
    }

    modifier updateRewards(address _account, address[] memory _rewards) {
        uint256 length = _rewards.length;
        uint256 userShare = balanceOf(_account);

        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = _rewards[index];
            UserInfo storage userInfo = userInfos[rewardToken][_account];
            // if a reward stopped queuing, no need to recalculate to save gas fee
            if (userInfo.userRewardPerTokenPaid == rewardPerToken(rewardToken)) continue;
            userInfo.userRewards = _earned(_account, rewardToken, userShare);
            userInfo.userRewardPerTokenPaid = rewardPerToken(rewardToken);
        }
        _;
    }

    /* ============ External Getters ============ */

    /// @notice Returns current amount of staked tokens
    /// @return Returns current amount of staked tokens
    function totalStaked() public view virtual override returns (uint256) {
        return IERC20(receiptToken).totalSupply();
    }

    /// @notice Returns amount of staked tokens in master Radpie by account
    /// @param _account Address account
    /// @return Returns amount of staked tokens by account
    function balanceOf(address _account) public view virtual override returns (uint256) {
        return IERC20(receiptToken).balanceOf(_account);
    }

    function stakingDecimals() external view virtual override returns (uint256) {
        return receiptTokenDecimals;
    }

    /// @notice Returns amount of reward token per staking tokens in pool in 10**12
    /// @param _rewardToken Address reward token
    /// @return Returns amount of reward token per staking tokens in pool in 10**12
    function rewardPerToken(address _rewardToken) public view override returns (uint256) {
        return rewards[_rewardToken].rewardPerTokenStored;
    }

    function rewardTokenInfos()
        external
        view
        override
        returns (address[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols)
    {
        uint256 rewardTokensLength = rewardTokens.length;
        bonusTokenAddresses = new address[](rewardTokensLength);
        bonusTokenSymbols = new string[](rewardTokensLength);
        for (uint256 i; i < rewardTokensLength; i++) {
            bonusTokenAddresses[i] = rewardTokens[i];
            bonusTokenSymbols[i] = IERC20Metadata(address(bonusTokenAddresses[i])).symbol();
        }
    }

    /// @notice Returns amount of reward token earned by a user
    /// @param _account Address account
    /// @param _rewardToken Address reward token
    /// @return Returns amount of reward token earned by a user
    function earned(address _account, address _rewardToken) public view override returns (uint256) {
        return _earned(_account, _rewardToken, balanceOf(_account));
    }

    /// @notice Returns amount of all reward tokens
    /// @param _account Address account
    /// @return pendingBonusRewards as amounts of all rewards.
    function allEarned(
        address _account
    ) external view override returns (uint256[] memory pendingBonusRewards) {
        uint256 length = rewardTokens.length;
        pendingBonusRewards = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            pendingBonusRewards[i] = earned(_account, rewardTokens[i]);
        }

        return pendingBonusRewards;
    }

    function getRewardLength() external view returns (uint256) {
        return rewardTokens.length;
    }

    /* ============ External Functions ============ */

    /// @notice Updates the reward information for one account
    /// @param _account Address account
    function updateFor(address _account) external override {
        _updateFor(_account);
    }

    function getReward(
        address _account,
        address _receiver
    ) public onlyMasterRadpie updateReward(_account) returns (bool) {
        uint256 length = rewardTokens.length;

        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = rewardTokens[index];
            uint256 reward = userInfos[rewardToken][_account].userRewards; // updated during updateReward modifier
            if (reward > 0) {
                _sendReward(rewardToken, _account, _receiver, reward);
            }
        }

        return true;
    }

    function getRewards(
        address _account,
        address _receiver,
        address[] memory _rewardTokens
    ) external override onlyMasterRadpie updateRewards(_account, _rewardTokens) {
        uint256 length = _rewardTokens.length;
        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = _rewardTokens[index];
            uint256 reward = userInfos[rewardToken][_account].userRewards; // updated during updateReward modifier
            if (reward > 0) {
                _sendReward(rewardToken, _account, _receiver, reward);
            }
        }
    }

    /// @notice Sends new rewards to be distributed to the users staking. Only possible to donate already registered token
    /// @param _amountReward Amount of reward token to be distributed
    /// @param _rewardToken Address reward token
    function donateRewards(uint256 _amountReward, address _rewardToken) external {
        if (!isRewardToken[_rewardToken]) revert MustBeRewardToken();

        _provisionReward(_amountReward, _rewardToken);
    }

    /* ============ Admin Functions ============ */

    function updateRewardQueuer(address _rewardManager, bool _allowed) external onlyOwner {
        rewardQueuers[_rewardManager] = _allowed;

        emit RewardQueuerUpdated(_rewardManager, rewardQueuers[_rewardManager]);
    }

    /// @notice Sends new rewards to be distributed to the users staking. Only callable by manager
    /// @param _amountReward Amount of reward token to be distributed
    /// @param _rewardToken Address reward token
    function queueNewRewards(
        uint256 _amountReward,
        address _rewardToken
    ) external override onlyRewardQueuer returns (bool) {
        if (!isRewardToken[_rewardToken]) {
            rewards[_rewardToken] = Reward({ rewardPerTokenStored: 0, queuedRewards: 0 });
            rewardTokens.push(_rewardToken);
            isRewardToken[_rewardToken] = true;
        }

        _provisionReward(_amountReward, _rewardToken);
        return true;
    }

    function emergencyWithdraw(address _rewardToken, address _to) external onlyMasterRadpie {
        uint256 amount = IERC20(_rewardToken).balanceOf(address(this));
        IERC20(_rewardToken).safeTransfer(_to, amount);
        emit EmergencyWithdrawn(_to, amount);
    }

    /* ============ Internal Functions ============ */

    function _provisionReward(uint256 _amountReward, address _rewardToken) internal {
        IERC20(_rewardToken).safeTransferFrom(msg.sender, address(this), _amountReward);
        Reward storage rewardInfo = rewards[_rewardToken];

        uint256 totalStake = totalStaked();
        if (totalStake == 0) {
            rewardInfo.queuedRewards += _amountReward;
        } else {
            if (rewardInfo.queuedRewards > 0) {
                _amountReward += rewardInfo.queuedRewards;
                rewardInfo.queuedRewards = 0;
            }
            rewardInfo.rewardPerTokenStored =
                rewardInfo.rewardPerTokenStored +
                (_amountReward * 10 ** receiptTokenDecimals * DENOMINATOR) /
                totalStake;
        }
        emit RewardAdded(_amountReward, _rewardToken);
    }

    function _earned(
        address _account,
        address _rewardToken,
        uint256 _userShare
    ) internal view returns (uint256) {
        UserInfo storage userInfo = userInfos[_rewardToken][_account];
        return
            ((_userShare * (rewardPerToken(_rewardToken) - userInfo.userRewardPerTokenPaid)) /
                (10 ** receiptTokenDecimals * DENOMINATOR)) + userInfo.userRewards;
    }

    function _sendReward(
        address _rewardToken,
        address _account,
        address _receiver,
        uint256 _amount
    ) internal {
        userInfos[_rewardToken][_account].userRewards = 0;
        IERC20(_rewardToken).safeTransfer(_receiver, _amount);
        emit RewardPaid(_account, _receiver, _amount, _rewardToken);
    }

    function _updateFor(address _account) internal {
        uint256 length = rewardTokens.length;
        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = rewardTokens[index];
            UserInfo storage userInfo = userInfos[rewardToken][_account];
            // if a reward stopped queuing, no need to recalculate to save gas fee
            if (userInfo.userRewardPerTokenPaid == rewardPerToken(rewardToken)) continue;

            userInfo.userRewards = earned(_account, rewardToken);
            userInfo.userRewardPerTokenPaid = rewardPerToken(rewardToken);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
pragma solidity ^0.8.19;

import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IMasterCakepie } from "../../interfaces/cakepie/IMasterCakepie.sol";
import { IPancakeStaking } from "../../interfaces/cakepie/IPancakeStaking.sol";

/// @title CakepieReceiptToken is to represent a Pancake pools deposited to cakepie posistion. CakepieReceiptToken is minted to user who deposited pools token
///        on Pancake staking to increase defi lego
///         
///         Reward from Magpie and on BaseReward should be updated upon every transfer.
///
/// @author Magpie Team
/// @notice Mater cakepie emit `CKP` reward token based on Time. For a pool, 

contract CakepieReceiptToken is ERC20, Ownable {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;

    address public underlying;  // pool address if a pancake pool, underlying otken if a masterCakepie pool
    address public immutable masterCakepie;
    address public immutable pancakeStaking;  // pancakStaking none zero address, means the receipt token represents a LP staked on cakepie getting boosted yield

    /* ============ Constructor ============ */

    constructor(address _underlying, address _masterCakepie, address _pancakeStaking, string memory name, string memory symbol) ERC20(name, symbol) {
        underlying = _underlying;
        masterCakepie = _masterCakepie;
        pancakeStaking = _pancakeStaking;
    } 

    // should only be called by 1. pancakestaking for Pancake pools deposits 2. masterCakepie for other general staking token such as mCAKEOFT or CKP Lp tokens
    function mint(address account, uint256 amount) external virtual onlyOwner {
        _mint(account, amount);
    }

    // should only be called by 1. pancakestaking for Pancake pools deposits 2. masterCakepie for other general staking token such as mCAKEOFT or CKP Lp tokens
    function burn(address account, uint256 amount) external virtual onlyOwner {
        _burn(account, amount);
    }

    /* ============ Internal Functions ============ */

    // rewards are calculated based on user's receipt token balance, so reward should be updated on master cakepie before transfer
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // no need to harvest again if mint or burn (trigger upon deposit or withdraw)
        if (from != address(0) && to != address(0)) _checkHarvestPancake(); 
        IMasterCakepie(masterCakepie).beforeReceiptTokenTransfer(from, to, amount);
    }

    // rewards are calculated based on user's receipt token balance, so balance should be updated on master cakepie before transfer
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // no need to harvest again if mint or burn (trigger upon deposit or withdraw)
        if (from != address(0) && to != address(0)) _checkHarvestPancake();
        IMasterCakepie(masterCakepie).afterReceiptTokenTransfer(from, to, amount);
    }

    function _checkHarvestPancake() internal {
        if (pancakeStaking != address(0)) {
            IPancakeStaking(pancakeStaking).genericHarvest(underlying);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IBaseRewardPool {
    function stakingDecimals() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function rewardPerToken(address token) external view returns (uint256);

    function rewardTokenInfos()
        external
        view
        returns (address[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols);

    function earned(address account, address token) external view returns (uint256);

    function allEarned(
        address account
    ) external view returns (uint256[] memory pendingBonusRewards);

    function queueNewRewards(uint256 _rewards, address token) external returns (bool);

    function getReward(address _account, address _receiver) external returns (bool);

    function getRewards(
        address _account,
        address _receiver,
        address[] memory _rewardTokens
    ) external;

    function updateFor(address account) external;

    function updateRewardQueuer(address _rewardManager, bool _allowed) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.19;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IMasterCakepie {
    function poolLength() external view returns (uint256);

    function setPoolManagerStatus(address _address, bool _bool) external;

    function add(
        uint256 _allocPoint,
        address _stakingTokenToken,
        address _receiptToken,
        address _rewarder,
        bool _isV3Pool
    ) external;

    function set(
        address _stakingToken,
        uint256 _allocPoint,
        address _rewarder
    ) external;

    function createRewarder(
        address _stakingTokenToken,
        address mainRewardToken,
        address rewardDistributor
    ) external returns (address);

    // View function to see pending GMPs on frontend.
    function getPoolInfo(
        address token
    )
        external
        view
        returns (uint256 emission, uint256 allocpoint, uint256 sizeOfPool, uint256 totalPoint);

    function pendingTokens(
        address _stakingToken,
        address _user,
        address token
    )
        external
        view
        returns (
            uint256 _pendingGMP,
            address _bonusTokenAddress,
            string memory _bonusTokenSymbol,
            uint256 _pendingBonusToken
        );

    // function allPendingTokensWithBribe(
    //     address _stakingToken,
    //     address _user,
    //     IBribeRewardDistributor.Claim[] calldata _proof
    // )
    //     external
    //     view
    //     returns (
    //         uint256 pendingCakepie,
    //         address[] memory bonusTokenAddresses,
    //         string[] memory bonusTokenSymbols,
    //         uint256[] memory pendingBonusRewards
    //     );

    function allPendingTokens(
        address _stakingToken,
        address _user
    )
        external
        view
        returns (
            uint256 pendingCakepie,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        );

    function massUpdatePools() external;

    function updatePool(address _stakingToken) external;

    function deposit(address _stakingToken, uint256 _amount) external;

    function depositFor(address _stakingToken, address _for, uint256 _amount) external;

    function withdraw(address _stakingToken, uint256 _amount) external;

    function beforeReceiptTokenTransfer(address _from, address _to, uint256 _amount) external;

    function afterReceiptTokenTransfer(address _from, address _to, uint256 _amount) external;

    function depositVlCakepieFor(uint256 _amount, address sender) external;

    function withdrawVlCakepieFor(uint256 _amount, address sender) external;

    function depositMCakeSVFor(uint256 _amount, address sender) external;

    function withdrawMCakeSVFor(uint256 _amount, address sender) external;

    function multiclaimFor(
        address[] calldata _stakingTokens,
        address[][] calldata _rewardTokens,
        address user_address
    ) external;

    function multiclaimOnBehalf(
        address[] memory _stakingTokens,
        address[][] calldata _rewardTokens,
        address user_address
    ) external;

    function multiclaim(address[] calldata _stakingTokens) external;

    function emergencyWithdraw(address _stakingToken, address sender) external;

    function updateEmissionRate(uint256 _gmpPerSec) external;

    function stakingInfo(
        address _stakingToken,
        address _user
    ) external view returns (uint256 depositAmount, uint256 availableAmount);

    function totalTokenStaked(address _stakingToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "../pancakeswap/IMasterChefV3.sol";

interface IPancakeStaking {
    function increaseLock(uint256 amount) external;

    function veCake() external returns (address);

    function pools(
        address _poolAddress
    )
        external
        view
        returns (
            address poolAddress,
            address depositToken,
            address rewarder,
            address receiptToken,
            uint256 lastHarvestTime,
            uint256 poolType,
            uint256 v3Liquidity,
            bool isAmount0,
            bool isNative,
            bool isActive
        );

    function depositV3For(address _for, address _v3Pool, uint256 _tokenId) external;

    function withdrawV3For(address _for, address _v3Pool, uint256 _tokenId) external;

    function increaseLiquidityV3For(
        address _for,
        address _v3Pool,
        IMasterChefV3.IncreaseLiquidityParams calldata params
    ) external;

    function decreaseLiquidityV3For(
        address _for,
        address _v3Pool,
        IMasterChefV3.DecreaseLiquidityParams calldata params
    ) external;

    function harvestV3(address _for, uint256[] memory tokenIds) external;

    function harvestV3PoolFees(address _for, uint256[] memory tokenIds) external payable;

    function depositV2LPFor(address _for, address _poolAddress, uint256 _amount) external;

    function withdrawV2LPFor(address _for, address _poolAddress, uint256 _amount) external;

    function harvestV2LP(address[] memory poolAddress) external;

    function depositAMLFor(address _for, address _poolAddress, uint256 _amount0, uint256 _amount1) external;

    function withdrawAMLFor(address _for, address _poolAddress, uint256 _amount) external;

    function harvestAMLV3(address[] memory poolAddress) external;

    function castVote(
        address[] memory _pools,
        uint256[] memory _weights,
        uint256[] memory _chainIds
    ) external;

    function harvestAML(address[] memory poolAddress) external;

    function genericHarvest(address poolAddress) external;

    function poolLength() external returns (uint256);

    function depositIFO(
        address _pancakeIFOHelper,
        address _pancakeIFO,
        uint8 _pid,
        address _depsoitToken,
        address _for,
        uint256 _amount
    ) external;

    function harvestIFO(
        address _pancakeIFOHelper,
        address _pancakeIFO,
        uint8 _pid,
        address _depositToken,
        address _rewardToken
    ) external;

    function releaseIFO(
        address _pancakeIFOHelper,
        address _pancakeIFO,
        bytes32 _vestingScheduleId,
        address _rewardToken
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface IPancakeV3Helper {
    function tokenToPool(uint256 _tokenId) external view returns (address);

    function harvestRewardAndFeeFor(address _for, uint256[] memory _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IRewardDistributor {
    struct Fees {
        uint256 value; // allocation denominated by DENOMINATOR
        address to;
        bool isAddress;
        bool isActive;
    }

    function pancakeFeeInfos(uint256 index) external view returns (Fees memory);

    function sendRewards(
        address poolAddress,
        address rewardToken,
        address _to,
        uint256 amount,
        bool isRewarder
    ) external;

    function sendVeReward(
        address _rewardSource,
        address _rewardToken,
        uint256 _amount,
        bool _isVeCake
    ) external;

    function CKPRatio() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity =0.8.19;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IMintableERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address, uint256) external;

    function faucet(uint256) external;

    function burn(address, uint256) external;

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
pragma solidity =0.8.19;

interface IAdapter {
    function token0() external returns (address);

    function token1() external returns (address);

    function deposit(
        uint256 _amount0,
        uint256 _amount1,
        address _user,
        bytes calldata _data
    ) external returns(uint256 _share);

    function withdraw(
        uint256 _share,
        address _user,
        bytes calldata _data
    ) external returns(uint256 _amount0, uint256 _amount1);

    function initialize(
        address _wrapper,
        address _vault,
        address _token0,
        address _token1,
        address _lpToken,
        address _admin
    ) external;

    function wrapper() external returns(address);

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface IALMWrapper {
    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to deposit (in stakeToken)
     */
    function deposit(uint256 _amount, bool _noHarvest) external;

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external;

    /*
     * @notice Mint then deposit staked tokens and collect reward tokens (if any)
     * @param _amount0: token0 amount to deposit (in token0)
     * @param _amount1: token0 amount to deposit (in token1)
     * @param _data: payload data from FE side
     */
    function mintThenDeposit(uint256 _amount0, uint _amount1, bool _noHarvest, bytes calldata _data) external;

    /*
     * @notice Withdraw then burn staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     * @param _data: payload data from FE side
     */
    function withdrawThenBurn(uint256 _amount, bool _noHarvest, bytes calldata _data) external;

    function pendingReward(address _user) external view returns (uint256);

    // TODO will have to update userInfo struct when new AMLWrapper deployed
    function userInfo(
        address userAddress
    ) external view returns (
        uint256 amount, // How many staked tokens the user has provided
        uint256 rewardDebt
        // uint256 boostMultiplier, // currently active multiplier
        // uint256 boostedAmount, // combined boosted amount
        // uint256 unsettledRewards // rewards haven't been transferred to users but already accounted in rewardDebt        
    );

    function adapterAddr() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.19;

import { INonfungiblePositionManagerStruct } from "./INonfungiblePositionManagerStruct.sol";

interface IMasterChefV3 is INonfungiblePositionManagerStruct {
    
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    struct UserPositionInfo {
        uint128 liquidity;
        uint128 boostLiquidity;
        int24 tickLower;
        int24 tickUpper;
        uint256 rewardGrowthInside;
        uint256 reward;
        address user;
        uint256 pid;
        uint256 boostMultiplier;
    }

    function userPositionInfos(
        uint256 tokenId
    )
        external
        view
        returns (
            uint128 liquidity,
            uint128 boostLiquidity,
            int24 tickLower,
            int24 tickUpper,
            uint256 rewardGrowthInside,
            uint256 reward,
            address user,
            uint256 pid,
            uint256 boostMultiplier
        );

    function updateLiquidity(uint256 _tokenId) external;

    function updatePools(uint256[] memory _pids) external;

    /// @notice Withdraw LP tokens from pool.
    /// @param _tokenId Token Id of NFT to deposit.
    /// @param _to Address to which NFT token to withdraw.
    /// @return reward Cake reward.
    function withdraw(uint256 _tokenId, address _to) external returns (uint256 reward);

    function balanceOf(address account) external view returns (uint256);

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams memory params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams memory params
    ) external returns (uint256 amount0, uint256 amount1);

    function pendingCake(uint256 _tokenId) external view returns (uint256 reward);

    /// @notice harvest cake from pool.
    /// @param _tokenId Token Id of NFT.
    /// @param _to Address to.
    /// @return reward Cake reward.
    function harvest(uint256 _tokenId, address _to) external returns (uint256 reward);

    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

    function unwrapWETH9(uint256 amountMinimum, address recipient) external;

    function sweepToken(address token, uint256 amountMinimum, address recipient) external;

    function collect(
        CollectParams memory params
    ) external returns (uint256 amount0, uint256 amount1);

    function poolInfo(
        uint256 poolId
    )
        external
        view
        returns (
            uint256 allocPoint,
            address v3Pool,
            address token0,
            address token1,
            uint24 fee,
            uint256 totalLiquidity,
            uint256 totalBoostLiquidity
        );
    function v3PoolAddressPid(address pool)  external view returns (uint256 pid);
    function WETH()  external view returns (address weth);
    function totalAllocPoint() external view returns (uint256 value);
    function latestPeriodCakePerSecond() external view returns (uint256 value);
    function poolLength() external view returns (uint256);
    function FARM_BOOSTER() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Non-fungible token for positions
/// @notice Wraps PancakeSwap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is IERC721Metadata, IERC721Enumerable {
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

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

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;

    function isApproved(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface INonfungiblePositionManagerStruct {
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.19;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IPancakeV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IPancakeV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface IV2Wrapper {
    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt;
        uint256 boostMultiplier; // currently active multiplier
        uint256 boostedAmount; // combined boosted amount
        uint256 unsettledRewards; // rewards haven't been transferred to users but already accounted in rewardDebt
    }

    function deposit(uint256 _amount, bool _noHarvest) external;

    function withdraw(uint256 _amount, bool _noHarvest) external;

    function pendingReward(address _userAddress) external view returns (uint256);

    function userInfo(address _userAddress) external view returns (UserInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { CakepieReceiptToken } from "../../cakepie/tokens/CakepieReceiptToken.sol";
import { BaseRewardPoolV3 } from "../../cakepie/rewards/BaseRewardPoolV3.sol";

library ERC20FactoryLib {

    function createReceipt(address _stakeToken, address _masterCakepie, address _pancakeStaking, string memory _name, string memory _symbol) public returns(address)
    {
        ERC20 token = new CakepieReceiptToken(_stakeToken, _masterCakepie, _pancakeStaking, _name, _symbol);
        return address(token);
    }

    function createRewarder(
        address _receiptToken,
        address mainRewardToken,
        address _masterCakepie,
        address _rewardQueuer
    ) external returns (address) {
        BaseRewardPoolV3 _rewarder = new BaseRewardPoolV3(
            _receiptToken,
            mainRewardToken,
            _masterCakepie,
            _rewardQueuer
        );
        return address(_rewarder);
    }    
}