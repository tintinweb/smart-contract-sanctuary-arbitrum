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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.15;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '../interfaces/IBribe.sol';
import '../interfaces/IVoter.sol';

interface IVe {
    function vote(address user, int256 voteDelta) external;
}

/// Voter can handle gauge voting. WOM rewards are distributed to different gauges (MasterWombat->LpToken pair)
/// according to the base allocation & voting weights.
///
/// veWOM holders can participate in gauge voting to determine `voteAllocation()` of the WOM emission. They can
///  allocate their vote (1 veWOM = 1 vote) to one or more gauges. WOM accumulation to a gauge is proportional
/// to the amount of vote it receives.
///
/// Real-time WOM accumulation and epoch-based WOM distribution:
/// Voting gauges accumulates WOM seconds by seconds according to the voting weight. When a user applies new
/// allocation for their votes, accumulation rate of WOM of the gauge updates immediately. Note that only whitelisted
/// gauges are able to accumulate WOM from users' votes.
/// Accumulated WOM is distributed to LP in the next epoch at an even rate. 1 epoch last for 7 days.
///
/// Base Allocation:
/// `baseAllocation` of WOM emissions is distributed to gauges according to the allocation by `owner`.
/// Other WOM emissions are deteremined by `votes` of veWOM holders.
///
/// Flow to distribute reward:
/// 1. `Voter.distribute(lpToken)` is called
/// 2. WOM index (`baseIndex` and `voteIndex`) is updated and corresponding WOM accumulated over this period (`GaugeInfo.claimable`)
///    is updated.
/// 3. At the beginning of each epoch, `GaugeInfo.claimable` amount of WOM is sent to the respective gauge
///    via `MasterWombat.notifyRewardAmount(IERC20 _lpToken, uint256 _amount)`
/// 4. MasterWombat will update the corresponding `pool.rewardRate` and `pool.periodFinish`
///
/// Bribe
/// Bribe is natively supported by `Voter`. Third Party protocols can bribe to attract more votes from veWOM holders
/// to increase WOM emissions to their tokens.
///
/// Flow of bribe:
/// 1. When users vote/unvote, `bribe.onVote` is called. The bribe contract works similar to `MultiRewarderPerSec`.
///
/// Note: This should also works with boosted pool. But it doesn't work with interest rate model
/// Note 2: Please refer to the comment of MasterWombatV3.notifyRewardAmount for front-running risk
contract Voter is IVoter, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    struct GaugeInfo {
        uint104 supplyBaseIndex; // 19.12 fixed point. distributed reward per alloc point
        uint104 supplyVoteIndex; // 19.12 fixed point. distributed reward per vote weight
        uint40 nextEpochStartTime;
        uint128 claimable; // 20.18 fixed point. Rewards pending distribution in the next epoch
        bool whitelist;
        IGauge gaugeManager;
        IBribe bribe; // address of bribe
    }

    uint256 internal constant ACC_TOKEN_PRECISION = 1e12;
    uint256 internal constant EPOCH_DURATION = 7 days;

    IERC20 public wom;
    IVe public veWom;
    IERC20[] public lpTokens; // all LP tokens

    // emission related storage
    uint40 public lastRewardTimestamp; // last timestamp to count
    uint104 public baseIndex; // 19.12 fixed point. Accumulated reward per alloc point
    uint104 public voteIndex; // 19.12 fixed point. Accumulated reward per vote weight

    uint128 public totalWeight;
    uint128 public totalAllocPoint;

    uint40 public firstEpochStartTime;
    uint88 public womPerSec; // 8.18 fixed point
    uint16 public baseAllocation; // (e.g. 300 for 30%)

    mapping(IERC20 => GaugeWeight) public override weights; // lpToken => gauge weight
    mapping(address => mapping(IERC20 => uint256)) public override votes; // user address => lpToken => votes
    mapping(IERC20 => GaugeInfo) public override infos; // lpToken => GaugeInfo

    address public bribeFactory;

    event UpdateEmissionPartition(uint256 baseAllocation, uint256 votePartition);
    event UpdateVote(address user, IERC20 lpToken, uint256 amount);
    event DistributeReward(IERC20 lpToken, uint256 amount);

    /// @dev Note: set bribe factory after initialization
    function initialize(
        IERC20 _wom,
        IVe _veWom,
        uint88 _womPerSec,
        uint40 _startTimestamp,
        uint40 _firstEpochStartTime,
        uint16 _baseAllocation
    ) external initializer {
        require(_firstEpochStartTime >= block.timestamp, 'invalid _firstEpochStartTime');
        require(address(_wom) != address(0), 'wom address cannot be zero');
        require(address(_veWom) != address(0), 'veWom address cannot be zero');
        require(_baseAllocation <= 1000);
        require(_womPerSec <= 10000e18);

        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        wom = _wom;
        veWom = _veWom;
        womPerSec = _womPerSec;
        lastRewardTimestamp = _startTimestamp;
        firstEpochStartTime = _firstEpochStartTime;
        baseAllocation = _baseAllocation;
    }

    /// @dev this check save more gas than a modifier
    function _checkGaugeExist(IERC20 _lpToken) internal view {
        require(address(infos[_lpToken].gaugeManager) != address(0), 'Voter: gaugeManager not exist');
    }

    /// @notice returns LP tokens length
    function lpTokenLength() external view returns (uint256) {
        return lpTokens.length;
    }

    /// @notice getter function to return vote of a LP token for a user
    function getUserVotes(address _user, IERC20 _lpToken) external view returns (uint256) {
        return votes[_user][_lpToken];
    }

    /// @notice Vote and unvote WOM emission for LP tokens.
    /// User can vote/unvote a un-whitelisted pool. But no WOM will be emitted.
    /// Bribes are also distributed by the Bribe contract.
    /// Amount of vote should be checked by veWom.vote().
    /// This can also used to distribute bribes when _deltas are set to 0
    /// @param _lpVote address to LP tokens to vote
    /// @param _deltas change of vote for each LP tokens
    function vote(
        IERC20[] calldata _lpVote,
        int256[] calldata _deltas
    ) external nonReentrant returns (uint256[][] memory bribeRewards) {
        // 1. call _updateFor() to update WOM emission
        // 2. update related lpToken weight and total lpToken weight
        // 3. update used voting power and ensure there's enough voting power
        // 4. call IBribe.onVote() to update bribes
        require(_lpVote.length == _deltas.length, 'voter: array length not equal');

        // update voteIndex
        _distributeWom();

        uint256 voteCnt = _lpVote.length;
        int256 voteDelta;

        bribeRewards = new uint256[][](voteCnt);

        for (uint256 i; i < voteCnt; ++i) {
            IERC20 lpToken = _lpVote[i];
            _checkGaugeExist(lpToken);

            int256 delta = _deltas[i];
            uint256 originalWeight = weights[lpToken].voteWeight;
            if (delta != 0) {
                _updateFor(lpToken);

                // update vote and weight
                if (delta > 0) {
                    // vote
                    votes[msg.sender][lpToken] += uint256(delta);
                    weights[lpToken].voteWeight = to128(originalWeight + uint256(delta));
                    totalWeight += to128(uint256(delta));
                } else {
                    // unvote
                    require(votes[msg.sender][lpToken] >= uint256(-delta), 'voter: vote underflow');
                    votes[msg.sender][lpToken] -= uint256(-delta);
                    weights[lpToken].voteWeight = to128(originalWeight - uint256(-delta));
                    totalWeight -= to128(uint256(-delta));
                }

                voteDelta += delta;
                emit UpdateVote(msg.sender, lpToken, votes[msg.sender][lpToken]);
            }

            // update bribe
            if (address(infos[lpToken].bribe) != address(0)) {
                bribeRewards[i] = infos[lpToken].bribe.onVote(msg.sender, votes[msg.sender][lpToken], originalWeight);
            }
        }

        // notice veWom for the new vote, it reverts if vote is invalid
        veWom.vote(msg.sender, voteDelta);
    }

    /// @notice Claim bribes for LP tokens
    /// @dev This function looks safe from re-entrancy attack
    function claimBribes(IERC20[] calldata _lpTokens) external returns (uint256[][] memory bribeRewards) {
        bribeRewards = new uint256[][](_lpTokens.length);
        for (uint256 i; i < _lpTokens.length; ++i) {
            IERC20 lpToken = _lpTokens[i];
            _checkGaugeExist(lpToken);
            if (address(infos[lpToken].bribe) != address(0)) {
                bribeRewards[i] = infos[lpToken].bribe.onVote(
                    msg.sender,
                    votes[msg.sender][lpToken],
                    weights[lpToken].voteWeight
                );
            }
        }
    }

    /// @dev This function looks safe from re-entrancy attack
    function distribute(IERC20 _lpToken) external override {
        require(msg.sender == address(infos[_lpToken].gaugeManager), 'Caller is not gauge manager');
        _checkGaugeExist(_lpToken);
        _distributeWom();
        _updateFor(_lpToken);

        uint256 _claimable = infos[_lpToken].claimable;
        // 1. distribute WOM once in each epoch
        // 2. In case WOM is not fueled, it should not create DoS
        if (
            _claimable > 0 &&
            block.timestamp >= infos[_lpToken].nextEpochStartTime &&
            wom.balanceOf(address(this)) > _claimable
        ) {
            infos[_lpToken].claimable = 0;
            infos[_lpToken].nextEpochStartTime = getNextEpochStartTime();
            emit DistributeReward(_lpToken, _claimable);

            wom.transfer(address(infos[_lpToken].gaugeManager), _claimable);
            infos[_lpToken].gaugeManager.notifyRewardAmount(_lpToken, _claimable);
        }
    }

    /// @notice Update index for accrued WOM
    function _distributeWom() internal {
        if (block.timestamp <= lastRewardTimestamp) {
            return;
        }

        baseIndex = to104(_getBaseIndex());
        voteIndex = to104(_getVoteIndex());
        lastRewardTimestamp = uint40(block.timestamp);
    }

    /// @notice Update `supplyBaseIndex` and `supplyVoteIndex` for the gauge
    /// @dev Assumption: gaugeManager exists and is not paused, the caller should verify it
    /// @param _lpToken address of the LP token
    function _updateFor(IERC20 _lpToken) internal {
        // calculate claimable amount before update supplyVoteIndex
        infos[_lpToken].claimable = to128(_getClaimable(_lpToken, baseIndex, voteIndex));
        infos[_lpToken].supplyBaseIndex = baseIndex;
        infos[_lpToken].supplyVoteIndex = voteIndex;
    }

    /**
     * Permisioneed functions
     */

    /// @notice update the base and vote partition
    function setBaseAllocation(uint16 _baseAllocation) external onlyOwner {
        require(_baseAllocation <= 1000);
        _distributeWom();

        emit UpdateEmissionPartition(_baseAllocation, 1000 - _baseAllocation);
        baseAllocation = _baseAllocation;
    }

    function setAllocPoint(IERC20 _lpToken, uint128 _allocPoint) external onlyOwner {
        _distributeWom();
        _updateFor(_lpToken);
        totalAllocPoint = totalAllocPoint - weights[_lpToken].allocPoint + _allocPoint;
        weights[_lpToken].allocPoint = _allocPoint;
    }

    /// @notice Add LP token into the Voter
    function add(IGauge _gaugeManager, IERC20 _lpToken, IBribe _bribe) external onlyOwner {
        require(infos[_lpToken].whitelist == false, 'voter: already added');
        require(address(_gaugeManager) != address(0));
        require(address(_lpToken) != address(0));
        require(address(infos[_lpToken].gaugeManager) == address(0), 'Voter: gaugeManager is already exist');

        infos[_lpToken].whitelist = true;
        infos[_lpToken].gaugeManager = _gaugeManager;
        infos[_lpToken].bribe = _bribe; // 0 address is allowed
        infos[_lpToken].nextEpochStartTime = getNextEpochStartTime();
        lpTokens.push(_lpToken);
    }

    function setWomPerSec(uint88 _womPerSec) external onlyOwner {
        require(_womPerSec <= 10000e18, 'reward rate too high'); // in case `voteIndex` overflow
        _distributeWom();
        womPerSec = _womPerSec;
    }

    /// @dev to revoke bribe factory, set its address to 0
    function setBribeFactory(address _bribeFactory) external onlyOwner {
        bribeFactory = _bribeFactory;
    }

    /// @notice Pause vote emission of WOM tokens for the gauge.
    /// Users can still vote/unvote and receive bribes.
    function pauseVoteEmission(IERC20 _lpToken) external onlyOwner {
        require(infos[_lpToken].whitelist, 'voter: not whitelisted');
        _checkGaugeExist(_lpToken);

        _distributeWom();
        _updateFor(_lpToken);

        infos[_lpToken].whitelist = false;
    }

    /// @notice Resume vote accumulation of WOM tokens for the gauge.
    function resumeVoteEmission(IERC20 _lpToken) external onlyOwner {
        require(infos[_lpToken].whitelist == false, 'voter: not paused');
        _checkGaugeExist(_lpToken);

        // catch up supplyVoteIndex
        _distributeWom();
        _updateFor(_lpToken);

        infos[_lpToken].whitelist = true;
    }

    /// @notice Pause vote accumulation of WOM tokens for all assets
    /// Users can still vote/unvote and receive bribes.
    function pauseAll() external onlyOwner {
        _distributeWom();
        uint256 len = lpTokens.length;
        for (uint256 i; i < len; i++) {
            _updateFor(lpTokens[i]);
        }

        _pause();
    }

    /// @notice Resume vote accumulation of WOM tokens for all assets
    function resumeAll() external onlyOwner {
        _distributeWom();
        uint256 len = lpTokens.length;
        for (uint256 i; i < len; i++) {
            _updateFor(lpTokens[i]);
        }

        _unpause();
    }

    /// @notice get gaugeManager address for LP token
    function setGauge(IERC20 _lpToken, IGauge _gaugeManager) external onlyOwner {
        require(address(_gaugeManager) != address(0));
        _checkGaugeExist(_lpToken);

        infos[_lpToken].gaugeManager = _gaugeManager;
    }

    /// @notice get bribe address for LP token
    function setBribe(IERC20 _lpToken, IBribe _bribe) external override {
        require(
            bribeFactory == msg.sender || owner() == msg.sender,
            'Voter: caller is not the owner nor the bribe factory'
        );
        _checkGaugeExist(_lpToken);

        infos[_lpToken].bribe = _bribe; // 0 address is allowed
    }

    /// @notice In case we need to manually migrate WOM funds from Voter
    /// Sends all remaining wom from the contract to the owner
    function emergencyWomWithdraw() external onlyOwner {
        // SafeERC20 is not needed as WOM will revert if transfer fails
        wom.transfer(address(msg.sender), wom.balanceOf(address(this)));
    }

    /// @notice avoids loosing funds in case there is any tokens sent to this contract
    /// @dev only to be called by owner
    function emergencyTokenWithdraw(address token) public onlyOwner {
        // send that balance back to owner
        if (token == address(0)) {
            // is native token
            (bool success, ) = msg.sender.call{value: address(this).balance}('');
            require(success, 'Transfer failed');
        } else {
            IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }

    /**
     * Read-only functions
     */

    function voteAllocation() external view returns (uint256) {
        return 1000 - baseAllocation;
    }

    /// @notice Get pending bribes for LP tokens
    function pendingBribes(
        IERC20[] calldata _lpTokens,
        address _user
    )
        external
        view
        returns (
            IERC20[][] memory bribeTokenAddresses,
            string[][] memory bribeTokenSymbols,
            uint256[][] memory bribeRewards
        )
    {
        bribeTokenAddresses = new IERC20[][](_lpTokens.length);
        bribeTokenSymbols = new string[][](_lpTokens.length);
        bribeRewards = new uint256[][](_lpTokens.length);
        for (uint256 i; i < _lpTokens.length; ++i) {
            IERC20 lpToken = _lpTokens[i];
            if (address(infos[lpToken].bribe) != address(0)) {
                bribeRewards[i] = infos[lpToken].bribe.pendingTokens(_user);
                bribeTokenAddresses[i] = infos[lpToken].bribe.rewardTokens();

                uint256 len = bribeTokenAddresses[i].length;
                bribeTokenSymbols[i] = new string[](len);

                for (uint256 j; j < len; ++j) {
                    if (address(bribeTokenAddresses[i][j]) == address(0)) {
                        bribeTokenSymbols[i][j] = 'BNB';
                    } else {
                        bribeTokenSymbols[i][j] = IERC20Metadata(address(bribeTokenAddresses[i][j])).symbol();
                    }
                }
            }
        }
    }

    /// @notice Amount of pending WOM for the LP token
    function pendingWom(IERC20 _lpToken) external view returns (uint256) {
        return _getClaimable(_lpToken, _getBaseIndex(), _getVoteIndex());
    }

    /// @notice Get the start timestamp of the next epoch
    function getNextEpochStartTime() public view returns (uint40) {
        if (block.timestamp < firstEpochStartTime) {
            return firstEpochStartTime;
        }

        uint256 epochCount = (block.timestamp - firstEpochStartTime) / EPOCH_DURATION;
        return uint40(firstEpochStartTime + (epochCount + 1) * EPOCH_DURATION);
    }

    function _getBaseIndex() internal view returns (uint256) {
        if (block.timestamp <= lastRewardTimestamp || totalAllocPoint == 0 || paused()) {
            return baseIndex;
        }

        uint256 secondsElapsed = block.timestamp - lastRewardTimestamp;
        // use `max(totalAllocPoint, 1e18)` in case the value overflows uint104
        return
            baseIndex +
            (secondsElapsed * womPerSec * baseAllocation * ACC_TOKEN_PRECISION) /
            max(totalAllocPoint, 1e18) /
            1000;
    }

    /// @notice Calculate the latest value of `voteIndex`
    function _getVoteIndex() internal view returns (uint256) {
        if (block.timestamp <= lastRewardTimestamp || totalWeight == 0 || paused()) {
            return voteIndex;
        }

        uint256 secondsElapsed = block.timestamp - lastRewardTimestamp;
        // use `max(totalWeight, 1e18)` in case the value overflows uint104
        return
            voteIndex +
            (secondsElapsed * womPerSec * (1000 - baseAllocation) * ACC_TOKEN_PRECISION) /
            max(totalWeight, 1e18) /
            1000;
    }

    /// @notice Calculate the latest amount of `claimable` for a gauge
    function _getClaimable(IERC20 _lpToken, uint256 _baseIndex, uint256 _voteIndex) internal view returns (uint256) {
        uint256 baseIndexDelta = _baseIndex - infos[_lpToken].supplyBaseIndex;
        uint256 _baseShare = (weights[_lpToken].allocPoint * baseIndexDelta) / ACC_TOKEN_PRECISION;

        if (!infos[_lpToken].whitelist) {
            return infos[_lpToken].claimable + _baseShare;
        }

        uint256 voteIndexDelta = _voteIndex - infos[_lpToken].supplyVoteIndex;
        uint256 _voteShare = (weights[_lpToken].voteWeight * voteIndexDelta) / ACC_TOKEN_PRECISION;

        return infos[_lpToken].claimable + _baseShare + _voteShare;
    }

    function to128(uint256 val) internal pure returns (uint128) {
        require(val <= type(uint128).max, 'uint128 overflow');
        return uint128(val);
    }

    function to104(uint256 val) internal pure returns (uint104) {
        if (val > type(uint104).max) revert('uint104 overflow');
        return uint104(val);
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x : y;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IBribe {
    function onVote(
        address user,
        uint256 newVote,
        uint256 originalTotalVotes
    ) external returns (uint256[] memory rewards);

    function pendingTokens(address _user) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);

    function rewardLength() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './IBribe.sol';

interface IGauge {
    function notifyRewardAmount(IERC20 token, uint256 amount) external;
}

interface IVoter {
    struct GaugeWeight {
        uint128 allocPoint;
        uint128 voteWeight; // total amount of votes for an LP-token
    }

    function infos(
        IERC20 _lpToken
    )
        external
        view
        returns (
            uint104 supplyBaseIndex,
            uint104 supplyVoteIndex,
            uint40 nextEpochStartTime,
            uint128 claimable,
            bool whitelist,
            IGauge gaugeManager,
            IBribe bribe
        );

    // lpToken => weight, equals to sum of votes for a LP token
    function weights(IERC20 _lpToken) external view returns (uint128 allocPoint, uint128 voteWeight);

    // user address => lpToken => votes
    function votes(address _user, IERC20 _lpToken) external view returns (uint256);

    function setBribe(IERC20 _lpToken, IBribe _bribe) external;

    function distribute(IERC20 _lpToken) external;
}