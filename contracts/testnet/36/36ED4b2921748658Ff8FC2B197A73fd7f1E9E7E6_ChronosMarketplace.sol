// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/utils/ERC721Holder.sol)

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
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
 * ```solidity
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
pragma solidity ^0.8.9;

import "./interfaces/IChronosMarketplace.sol";
import "./interfaces/IVoter.sol";
import "./Errors.sol";

contract ChronosMarketplace is
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721HolderUpgradeable,
    IChronosMarketPlace
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    address[] public chronosNftList;
    mapping(address => uint16) tokenType;
    mapping(uint256 => SellInfo) public sellInfos;
    mapping(uint256 => AuctionInfo) public auctionInfos;
    mapping(uint256 => OfferInfo) public offerInfos;
    uint256 public saleId;
    uint256 public auctionId;
    uint256 public offerId;

    mapping(address => EnumerableSet.UintSet) private userSaleIds;
    mapping(address => EnumerableSet.UintSet) private userAuctionIds;
    mapping(address => mapping(address => EnumerableSet.UintSet))
        private userOfferIds;

    EnumerableSet.UintSet private availableSaleIds;
    EnumerableSet.UintSet private availableAuctionIds;
    EnumerableSet.UintSet private availableOfferIds;

    uint16[] public platformFee;
    uint16 public constant FIXED_POINT = 1000;
    address public treasury;
    mapping(address => bool) public allowedTokens;
    IVoter vt;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _voterAddress,
        uint16[] memory _platformFee
    ) public initializer {
        __Ownable_init();
        require(_platformFee.length > 0, Errors.INVALID_FEE);
        saleId = 1;
        auctionId = 1;
        offerId = 1;
        vt = IVoter(_voterAddress);
        // Apply the 3 types of fee
        delete platformFee;
        for (uint16 i = 0; i < _platformFee.length; i++) {
            require(_platformFee[i] < FIXED_POINT, Errors.INVALID_FEE);
            platformFee.push(_platformFee[i]);
        }
    }

    /// @inheritdoc IChronosMarketPlace
    function setAllowedToken(
        address[] memory _tokens,
        bool _isAdd
    ) external override onlyOwner {
        uint256 length = _tokens.length;
        require(length > 0, Errors.INVALID_LENGTH);
        for (uint256 i = 0; i < length; i++) {
            allowedTokens[_tokens[i]] = _isAdd;
        }

        emit AllowedTokenSet(_tokens, _isAdd);
    }

    /// @inheritdoc IChronosMarketPlace
    function setPlatformFee(uint16[] memory _platformFee) external override onlyOwner {
        require(_platformFee.length > 0, Errors.INVALID_FEE);

        delete platformFee;
        for (uint16 i = 0; i < _platformFee.length; i++) {
            require(_platformFee[i] < FIXED_POINT, Errors.INVALID_FEE);
            platformFee.push(_platformFee[i]);
        }

        emit PlatformFeeSet(_platformFee);
    }

    /// @inheritdoc IChronosMarketPlace
    function setTreasury(address _treasury) external override onlyOwner {
        require(_treasury != address(0), Errors.INVALID_TREASURY_ADDRESS);
        treasury = _treasury;

        emit TreasurySet(_treasury);
    }

    /// @inheritdoc IChronosMarketPlace
    function setNftList(address[] memory _nftList) external override onlyOwner {
        require(_nftList.length > 0, Errors.EMPTY_NFTS);
        delete chronosNftList;

        for (uint16 i = 0; i < _nftList.length; i++) {
            chronosNftList.push(_nftList[i]);
            tokenType[_nftList[i]] = i + 1;
        }

        emit NftListSet(_nftList);
    }

    /// @inheritdoc IChronosMarketPlace
    function getChronosNftType(address _nft) public override returns (uint16) {
        if (tokenType[_nft] > 0) return tokenType[_nft];
        if (tokenType[_nft] == 0 && vt.isGauge(_nft)) {
            tokenType[_nft] = 3;
            return tokenType[_nft];
        }
        return 5;
    }

    /// @inheritdoc IChronosMarketPlace
    function isChronosNft(address _nft) public override returns (bool) {
        return getChronosNftType(_nft) != 5;
    }

    /// @inheritdoc IChronosMarketPlace
    function pause() external override whenNotPaused onlyOwner {
        _pause();
        emit Pause();
    }

    /// @inheritdoc IChronosMarketPlace
    function unpause() external override whenPaused onlyOwner {
        _unpause();
        emit Unpause();
    }

    /// Fixed Sale

    /// @inheritdoc IChronosMarketPlace
    function listNftForFixed(
        address _nft,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _saleDuration,
        uint256 _price
    ) external override whenNotPaused {
        address seller = msg.sender;
        require(isChronosNft(_nft), Errors.NOT_CHRONOS_NFT);
        require(allowedTokens[_paymentToken], Errors.INVALID_TOKEN);
        require(
            IERC721(_nft).ownerOf(_tokenId) == seller,
            Errors.SELLER_NOT_OWNER_OF_NFT
        );
        require(_saleDuration > 0, Errors.INVALID_SALE_DURATION);
        _setSaleId(saleId, seller, true);

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _saleDuration;

        IERC721(_nft).safeTransferFrom(seller, address(this), _tokenId);

        sellInfos[saleId++] = SellInfo(
            seller,
            address(0),
            _nft,
            _paymentToken,
            _tokenId,
            startTime,
            endTime,
            _price
        );

        emit ListNftForFixed(
            _nft,
            _tokenId,
            _paymentToken,
            saleId - 1,
            _saleDuration,
            _price
        );
    }

    /// @inheritdoc IChronosMarketPlace
    function getAvailableSaleIds()
        external
        view
        override
        returns (uint256[] memory)
    {
        return availableSaleIds.values();
    }

    /// @inheritdoc IChronosMarketPlace
    function getNftListForFixedOfUser(
        address _user
    ) external view override returns (uint256[] memory) {
        return userSaleIds[_user].values();
    }

    /// @inheritdoc IChronosMarketPlace
    function cancelListNftForFixed(
        uint256 _saleId
    ) external override nonReentrant whenNotPaused {
        require(availableSaleIds.contains(_saleId), Errors.NOT_EXISTED_SAILID);
        SellInfo memory sellInfo = sellInfos[_saleId];
        require(msg.sender == sellInfo.seller, Errors.NO_PERMISSION);

        IERC721(sellInfo.nft).safeTransferFrom(
            address(this),
            sellInfo.seller,
            sellInfo.tokenId
        );
        _setSaleId(_saleId, sellInfo.seller, false);

        emit CancelListNftForFixed(_saleId);
    }

    /// @inheritdoc IChronosMarketPlace
    function changeSaleInfo(
        uint256 _saleId,
        uint256 _saleDuration,
        uint256 _price
    ) external override nonReentrant whenNotPaused {
        require(availableSaleIds.contains(_saleId), Errors.NOT_EXISTED_SAILID);

        SellInfo memory sellInfo = sellInfos[_saleId];
        require(msg.sender == sellInfo.seller, Errors.NO_PERMISSION);
        require(_price > 0, Errors.INVALID_PRICE);
        require(_saleDuration > 0, Errors.INVALID_SALE_DURATION);

        sellInfo.startTime = block.timestamp;
        sellInfo.endTime = sellInfo.startTime + _saleDuration;
        sellInfo.price = _price;

        emit SaleInfoChanged(_saleId, sellInfo.price);
    }

    /// @inheritdoc IChronosMarketPlace
    function buyNow(
        uint256 _saleId
    ) external override whenNotPaused nonReentrant {
        address buyer = msg.sender;
        // uint256 amount = msg.value;
        uint256 currentTime = block.timestamp;
        require(availableSaleIds.contains(_saleId), Errors.NOT_EXISTED_SAILID);

        SellInfo storage saleInfo = sellInfos[_saleId];
        require(buyer != saleInfo.seller, Errors.INVALID_BUYER);

        require(currentTime < saleInfo.endTime, Errors.NOT_SALE_PERIOD);
        // require(amount > 0, Errors.INVALID_TOKEN_AMOUNT);
        require(saleInfo.buyer == address(0), Errors.ALREADY_SOLD);

        uint16 nftType = getChronosNftType(saleInfo.nft);
        uint256 fee = (saleInfo.price * platformFee[nftType - 1]) / FIXED_POINT;
        IERC20(saleInfo.paymentToken).safeTransferFrom(
            buyer,
            saleInfo.seller,
            saleInfo.price - fee
        );
        IERC20(saleInfo.paymentToken).safeTransferFrom(buyer, treasury, fee);

        IERC721(saleInfo.nft).safeTransferFrom(
            address(this),
            buyer,
            saleInfo.tokenId
        );
        saleInfo.buyer = buyer;

        _setSaleId(_saleId, saleInfo.seller, false);

        emit Bought(
            _saleId,
            saleInfo.nft,
            saleInfo.tokenId,
            saleInfo.seller,
            buyer,
            saleInfo.paymentToken,
            saleInfo.price
        );
    }

    /// Bid

    /// @inheritdoc IChronosMarketPlace
    function listNftForAuction(
        address _nft,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _saleDuration,
        uint256 _minimumPrice
    ) external override whenNotPaused {
        address seller = msg.sender;
        require(isChronosNft(_nft), Errors.NOT_CHRONOS_NFT);
        require(allowedTokens[_paymentToken], Errors.INVALID_TOKEN);
        require(_minimumPrice > 0, Errors.INVALID_PRICE);
        require(
            IERC721(_nft).ownerOf(_tokenId) == seller,
            Errors.SELLER_NOT_OWNER_OF_NFT
        );
        require(_saleDuration > 0, Errors.INVALID_SALE_DURATION);

        _setAuctionId(auctionId, seller, true);

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _saleDuration;

        IERC721(_nft).safeTransferFrom(seller, address(this), _tokenId);

        auctionInfos[auctionId++] = AuctionInfo(
            seller,
            _nft,
            _paymentToken,
            address(0),
            _tokenId,
            startTime,
            endTime,
            _minimumPrice,
            0
        );

        emit ListNftForAuction(
            _nft,
            _tokenId,
            _paymentToken,
            auctionId - 1,
            _saleDuration,
            _minimumPrice
        );
    }

    /// @inheritdoc IChronosMarketPlace
    function getAvailableAuctionIds()
        external
        view
        override
        returns (uint256[] memory)
    {
        return availableAuctionIds.values();
    }

    /// @inheritdoc IChronosMarketPlace
    function getNftListForAuctionOfUser(
        address _user
    ) external view override returns (uint256[] memory) {
        return userAuctionIds[_user].values();
    }

    /// @inheritdoc IChronosMarketPlace
    function cancelListNftForAuction(
        uint256 _auctionId
    ) external override whenNotPaused {

        require(
            availableAuctionIds.contains(_auctionId),
            Errors.NOT_EXISTED_AUCTIONID
        );

        AuctionInfo storage auctionInfo = auctionInfos[_auctionId];

        address seller = msg.sender;
        require(seller == auctionInfo.seller, Errors.NO_PERMISSION);

        _setAuctionId(_auctionId, auctionInfo.seller, false);

        if (auctionInfo.highestBidder != address(0)) {
            IERC20(auctionInfo.paymentToken).safeTransfer(
                auctionInfo.highestBidder,
                auctionInfo.highestBidPrice
            );
        }

        IERC721(auctionInfo.nft).safeTransferFrom(
            address(this),
            auctionInfo.seller,
            auctionInfo.tokenId
        );

        emit CancelListNftForAuction(_auctionId);
    }

    /// @inheritdoc IChronosMarketPlace
    function finishAuction(uint256 _auctionId) external override whenNotPaused {
        address sender = msg.sender;
        require(
            availableAuctionIds.contains(_auctionId),
            Errors.NOT_EXISTED_AUCTIONID
        );

        AuctionInfo storage auctionInfo = auctionInfos[_auctionId];

        //Auction maker and highestBidder can finish auction.
        require(
            auctionInfo.seller == sender || auctionInfo.highestBidder == sender,
            Errors.NO_PERMISSION
        );

        // HighestBidder can only finish auction after auction ends.
        if(sender == auctionInfo.highestBidder){
            require(
                block.timestamp >= auctionInfo.endTime ,
                Errors.BEFORE_AUCTION_MATURITY
            );
        }

        if (auctionInfo.highestBidder != address(0)) {
            uint256 price = auctionInfo.highestBidPrice;
            // Apply the different platform fee
            uint16 nftType = getChronosNftType(auctionInfo.nft);
            uint256 fee = (price * platformFee[nftType - 1]) / FIXED_POINT;
            IERC20(auctionInfo.paymentToken).safeTransfer(
                auctionInfo.seller,
                price - fee
            );
            IERC20(auctionInfo.paymentToken).safeTransfer(treasury, fee);
            IERC721(auctionInfo.nft).safeTransferFrom(
                address(this),
                auctionInfo.highestBidder,
                auctionInfo.tokenId
            );
        } else {
            IERC721(auctionInfo.nft).safeTransferFrom(
                address(this),
                auctionInfo.seller,
                auctionInfo.tokenId
            );
        }

        _setAuctionId(_auctionId, auctionInfo.seller, false);
        emit FinishAuction(_auctionId);
    }

    /// @inheritdoc IChronosMarketPlace
    function placeBid(
        uint256 _auctionId,
        uint256 _bidPrice
    ) external override whenNotPaused {
        address bidder = msg.sender;
        uint256 currentTime = block.timestamp;
        require(
            availableAuctionIds.contains(_auctionId),
            Errors.NOT_EXISTED_AUCTIONID
        );
        AuctionInfo storage auctionInfo = auctionInfos[_auctionId];

        require(auctionInfo.seller != msg.sender, Errors.INVALID_BUYER);

        require(
            currentTime >= auctionInfo.startTime &&
                currentTime < auctionInfo.endTime,
            Errors.NOT_SALE_PERIOD
        );

        uint256 minimumBidPrice = (auctionInfo.highestBidPrice == 0)
            ? auctionInfo.minimumPrice
            : auctionInfo.highestBidPrice;
        require(_bidPrice > minimumBidPrice, Errors.LOW_BID_PRICE);

        if (auctionInfo.highestBidder != address(0)) {
            IERC20(auctionInfo.paymentToken).safeTransfer(
                auctionInfo.highestBidder,
                auctionInfo.highestBidPrice
            );
        }

        IERC20(auctionInfo.paymentToken).safeTransferFrom(
            bidder,
            address(this),
            _bidPrice
        );

        auctionInfo.highestBidder = bidder;
        auctionInfo.highestBidPrice = _bidPrice;

        emit PlaceBid(bidder, _auctionId, _bidPrice);
    }

    /// Offer

    /// @inheritdoc IChronosMarketPlace
    function makeOffer(
        address _owner,
        address _nft,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _offerPrice
    ) external override whenNotPaused {
        require(isChronosNft(_nft), Errors.NOT_CHRONOS_NFT);
        require(allowedTokens[_paymentToken], Errors.INVALID_TOKEN);
        require(
            IERC721(_nft).ownerOf(_tokenId) == _owner ||
                IERC721(_nft).ownerOf(_tokenId) == address(this),
            Errors.INVALID_TOKEN_ID
        );
        address offeror = msg.sender;

        availableOfferIds.add(offerId);

        userOfferIds[_owner][_nft].add(offerId);

        offerInfos[offerId++] = OfferInfo(
            _owner,
            offeror,
            _paymentToken,
            _nft,
            _tokenId,
            _offerPrice
        );

        IERC20(_paymentToken).safeTransferFrom(
            offeror,
            address(this),
            _offerPrice
        );

        emit MakeOffer(
            offerId - 1,
            offeror,
            _paymentToken,
            _nft,
            _tokenId,
            _offerPrice
        );
    }

    /// @inheritdoc IChronosMarketPlace
    function getAvailableOffers(
        address _owner,
        address _nft
    ) external view override returns (OfferInfo[] memory, uint256[] memory) {
        uint256 length = userOfferIds[_owner][_nft].length();
        OfferInfo[] memory availableOffers = new OfferInfo[](length);
        uint256[] memory availableIds = userOfferIds[_owner][_nft].values();
        if (length == 0) {
            return (availableOffers, availableIds);
        }

        for (uint256 i = 0; i < length; i++) {
            uint256 id = availableIds[i];
            availableOffers[i] = offerInfos[id];
        }

        return (availableOffers, availableIds);
    }

    /// @inheritdoc IChronosMarketPlace
    function acceptOffer(uint256 _offerId) external override {
        address sender = msg.sender;
        OfferInfo memory offerInfo = offerInfos[_offerId];
        require(
            availableOfferIds.contains(_offerId),
            Errors.NOT_EXISTED_OFFERID
        );
        require(
            IERC721(offerInfo.nft).ownerOf(offerInfo.tokenId) == sender,
            Errors.NO_PERMISSION
        );

        uint256 price = offerInfo.offerPrice;

        uint16 nftType = getChronosNftType(offerInfo.nft);
        uint256 fee = (price * platformFee[nftType - 1]) / FIXED_POINT;
        IERC20(offerInfo.paymentToken).safeTransfer(sender, price - fee);
        IERC20(offerInfo.paymentToken).safeTransfer(treasury, fee);

        IERC721(offerInfo.nft).safeTransferFrom(
            sender,
            offerInfo.offeror,
            offerInfo.tokenId
        );

        _removeAllOfferIds(offerInfo.owner, offerInfo.nft);

        emit AcceptOffer(_offerId);
    }

    function _removeAllOfferIds(address _owner, address _nft) internal {
        uint256[] memory values = userOfferIds[_owner][_nft].values();
        uint256 length = values.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 value = values[i];
            userOfferIds[_owner][_nft].remove(value);
            availableOfferIds.remove(value);
        }
    }

    /// @inheritdoc IChronosMarketPlace
    function cancelOffer(uint256 _offerId) external override {
        address sender = msg.sender;
        OfferInfo storage offerInfo = offerInfos[_offerId];
        require(
            availableOfferIds.contains(_offerId),
            Errors.NOT_EXISTED_OFFERID
        );
        require(offerInfo.offeror == sender, Errors.NO_PERMISSION);

        IERC20(offerInfo.paymentToken).safeTransfer(
            sender,
            offerInfo.offerPrice
        );
        availableOfferIds.remove(_offerId);
        userOfferIds[offerInfo.owner][offerInfo.nft].remove(_offerId);
        emit CancelOffer(_offerId);
    }

    function _setSaleId(
        uint256 _saleId,
        address _seller,
        bool _isAdd
    ) internal {
        if (_isAdd) {
            availableSaleIds.add(_saleId);
            userSaleIds[_seller].add(_saleId);
        } else {
            availableSaleIds.remove(_saleId);
            userSaleIds[_seller].remove(_saleId);
        }
    }

    function _setAuctionId(
        uint256 _auctionId,
        address _auctionMaker,
        bool _isAdd
    ) internal {
        if (_isAdd) {
            availableAuctionIds.add(_auctionId);
            userAuctionIds[_auctionMaker].add(_auctionId);
        } else {
            availableAuctionIds.remove(_auctionId);
            userAuctionIds[_auctionMaker].remove(_auctionId);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Errors {
    string public constant INVALID_LENGTH= "invalid length";
    string public constant INVALID_FEE = "invalid platform fee";
    string public constant INVALID_TREASURY_ADDRESS = "invalid _treasury address";
    string public constant EMPTY_NFTS = "empty nftList";
    string public constant NOT_CHRONOS_NFT = "not chronos nft";
    string public constant SELLER_NOT_OWNER_OF_NFT = "caller is not token owner or approved";
    string public constant INVALID_TOKEN = "not allowed payment token";
    string public constant INVALID_ITEM_ID = "invalid item id";
    string public constant NOT_SALE_PERIOD = "not sale period";
    string public constant INVALID_TOKEN_AMOUNT = "invalid nativeToken amount";
    string public constant ALREADY_SOLD = "already sold";
    string public constant LOW_BID_PRICE = "low bid price";
    string public constant NOT_EXISTED_SAILID = "not exists sailId";
    string public constant NO_PERMISSION = "has no permission";
    string public constant INVALID_TOKEN_ID = "unavailable token id";
    string public constant INVALID_SALE_DURATION = "saleDuration should be bigger than 0";
    string public constant INVALID_PRICE = "invalid price";
    string public constant INVALID_BUYER = "buyer can't be same as seller";
    string public constant NOT_EXISTED_AUCTIONID = "unavailable auctionId";
    string public constant BEFORE_AUCTION_MATURITY = "before auction maturity";
    string public constant NOT_EXISTED_OFFERID = "unavailable offerId";
    string public constant NOT_ENOUGH_ALLOWANCE = "not enough allowance";
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IChronosMarketPlace {
    struct SellInfo {
        address seller;
        address buyer;
        address nft;
        address paymentToken;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
    }

    struct AuctionInfo {
        address seller;
        address nft;
        address paymentToken;
        address highestBidder;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 minimumPrice;
        uint256 highestBidPrice;
    }

    struct OfferInfo {
        address owner;
        address offeror;
        address paymentToken;
        address nft;
        uint256 tokenId;
        uint256 offerPrice;
    }

    /// @notice Set allowed payment token.
    /// @dev Users can't trade NFT with token that not allowed.
    ///      Only owner can call this function.
    /// @param tokens The token addresses.
    /// @param isAdd Add/Remove = true/false
    function setAllowedToken(address[] memory tokens, bool isAdd) external;

    /// @notice Set marketplace platform fee.
    /// @dev Only owner can call this function.
    function setPlatformFee(uint16[] memory platformFee) external;

    /// @notice Set marketplace Treasury address.
    /// @dev Only owner can call this function.
    function setTreasury(address treasury) external;

    /// @notice Set NftList available in the marketplace.
    /// @dev Only owner can call this function.
    function setNftList(address[] memory nftList) external;

    /// @notice return the token type of the nfts.
    function getChronosNftType(address nft) external returns (uint16);

    /// @notice Check if the nft is included in the available nfts.
    function isChronosNft(address nft) external returns (bool);

    /// @notice Pause marketplace
    /// @dev Only owner can call this function.
    function pause() external;

    /// @notice Unpause marketplace
    /// @dev Only owner can call this function.
    function unpause() external;

    /// @notice List Nft for sale in the marketplace.
    /// @dev    Only owner of Nft can call this function.
    ///         Nft owners should send their nfts to marketplace.
    /// @param  nft:            the address of nft to list
    /// @param  tokenId:        token Id of the nft
    /// @param  paymentToken:   the address that the buyer should pay with.
    /// @param  saleDuration:   the duration that the nft will be listed.
    /// @param  price:          price to sell
    function listNftForFixed(
        address nft,
        uint256 tokenId,
        address paymentToken,
        uint256 saleDuration,
        uint256 price
    ) external;

    /// @notice Get available saleIds of listNft for fixed
    function getAvailableSaleIds() external view returns (uint256[] memory);

    /// @notice Get available saleIds of User's Listed Nfts for fixed price.
    function getNftListForFixedOfUser(address user) external returns (uint256[] memory);

    /// @notice Cancel and retrieve the listed Nft for sale in the marketplace.
    /// @dev Only sale creator can call this function.
    function cancelListNftForFixed(uint256 saleId) external;

    /// @notice Change the SaleInfo of listed Nft of user.
    /// @dev only sale creator can call this function.
    function changeSaleInfo(
        uint256 saleId,
        uint256 saleDuration,
        uint256 price
    ) external;

    /// @notice Buy the listed Nft for fixed
    /// @dev Buyer can't same as seller.
    function buyNow(uint256 _saleId) external;

    /// @notice List the Nft for auction.
    /// @dev Only the owner of the nft can call this function.
    ///      Nft should be the available nft in the platform.
    ///      Nft owners should send their nfts to marketplace.
    /// @param  nft:          the address of the nft for auction.
    /// @param  tokenId:      id of the nft
    /// @param  paymentToken: the address that the winner should pay with.
    /// @param  saleDuration: the duration for auction
    /// @param  minimumPrice: the start price for auction.
    function listNftForAuction(
        address nft,
        uint256 tokenId,
        address paymentToken,
        uint256 saleDuration,
        uint256 minimumPrice
    ) external;

    /// @notice Get available ids of auction.
    function getAvailableAuctionIds() external view returns (uint256[] memory);

    /// @notice Cancel and retrieve the listed Nft for auction in the marketplace.
    /// @dev Only auction creator can call this function.
    function cancelListNftForAuction(uint256 auctionId) external;

    /// @notice Get available nftlist of user for auction.
    /// @dev Only auction creator can call this function.
    function getNftListForAuctionOfUser(address user) external returns (uint256[] memory);

    /// @notice Finish auction.
    /// @dev Caller should be the auction maker.
    ///      Winner receives the collection and auction maker gets token.
    function finishAuction(uint256 auctionId) external;

    /// @notice Bid to auction with certain auction Id.
    /// @dev Users can get auctionIds from `getAvailableAuctionIds`
    /// @dev Bidder should bid with price that higher than last highestBidder's bid price.
    /// @param auctionId The id of auction.
    /// @param bidPrice The price of token to bid.
    function placeBid(uint256 auctionId, uint256 bidPrice) external;

    /// @notice Anyone can place offer to certain nfts in this platform.
    function makeOffer(
        address owner,
        address nft,
        uint256 tokenId,
        address paymentToken,
        uint256 offerPrice
    ) external;

    /// @notice the owner of nft can get the available offers to his nft.
    function getAvailableOffers(
        address owner,
        address nft
    ) external returns (OfferInfo[] memory, uint256[] memory);

    /// @notice Nft owner accept offer with certain offer Id.
    /// @dev Nft owner can get available offer ids from `geetAvailableOffers` function.
    function acceptOffer(uint256 offerId) external;

    /// @notice Cancel the offer for the nft.
    /// @dev Only offer maker can call this function.
    function cancelOffer(uint256 offerId) external;

    event AllowedTokenSet(address[] tokens, bool isAdd);

    event PlatformFeeSet(uint16[] platformFee);

    event TreasurySet(address treasury);

    event NftListSet(address[] nftList);

    event Pause();

    event Unpause();

    event ListNftForFixed(
        address nft,
        uint256 tokenId,
        address paymentToken,
        uint256 saleId,
        uint256 saleDuration,
        uint256 fixedPrice
    );

    event CancelListNftForFixed(uint256 saleId);

    event SaleInfoChanged(uint256 saleId, uint256 price);

    event ListNftForAuction(
        address nft,
        uint256 tokenId,
        address paymentToken,
        uint256 auctionId,
        uint256 saleDuration,
        uint256 minimumPrice
    );

    event CancelListNftForAuction(uint256 auctionId);

    event FinishAuction(uint256 auctionId);

    event Bought(
        uint256 saleId,
        address nft,
        uint256 tokenId,
        address seller,
        address buyer,
        address paymentToken,
        uint256 price
    );

    event PlaceBid(
        address bidder,
        uint256 auctionId,
        uint256 bidPrice
    );

    event MakeOffer(
        uint256 offerId,
        address offeror,
        address paymentToken,
        address nft,
        uint256 tokenId,
        uint256 offerPrice
    );

    event AcceptOffer(uint256 offerId);
    event CancelOffer(uint256 offerId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVoter{
    function isGauge(address _nft) external view returns(bool);
}