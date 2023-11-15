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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface INonceCounter {
    /* ----- Events ----- */

    event CrossChainRouterUpdated(address crossChainRouter, bool flag);

    /* ----- State Variables ----- */

    function isCrossChainRouter(address sender) external view returns (bool flag);

    function outboundNonce(uint16 dstChainId) external view returns (uint256 nonce);

    /* ----- Functions ----- */

    function increment(uint16 dstChainId) external returns (uint256 nonce);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IWETH {
    /* ----- Functions ----- */

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IWOOFiDexCrossChainRouter {
    /* ----- Structs ----- */

    struct SrcInfos {
        address fromToken;
        uint256 fromAmount;
        address bridgeToken;
        uint256 minBridgeAmount;
    }

    struct DstInfos {
        uint16 chainId;
        address bridgedToken;
        address toToken;
        uint256 minToAmount;
        uint256 orderlyNativeFees;
    }

    struct DstVaultDeposit {
        bytes32 accountId;
        bytes32 brokerHash;
        bytes32 tokenHash;
    }

    struct PoolIds {
        uint256 src;
        uint256 dst;
    }

    /* ----- Events ----- */

    event WOOFiDexCrossSwapOnSrcChain(
        uint16 dstChainId,
        uint256 indexed nonce,
        address indexed sender,
        address indexed to,
        address fromToken,
        uint256 fromAmount,
        address bridgeToken,
        uint256 minBridgeAmount,
        uint256 bridgeAmount
    );

    event WOOFiDexCrossSwapOnDstChain(
        uint16 srcChainId,
        uint256 indexed nonce,
        address indexed sender,
        address indexed to,
        address bridgedToken,
        uint256 bridgedAmount,
        address toToken,
        uint256 minToAmount,
        address realToToken,
        uint256 realToAmount,
        uint256 orderlyNativeFees,
        bytes32 accountId,
        bytes32 brokerHash,
        bytes32 tokenHash,
        uint128 tokenAmount
    );

    /* ----- State Variables ----- */

    function nonceCounter() external view returns (address);

    function wooRouter() external view returns (address);

    function sgRouter() external view returns (address);

    function weth() external view returns (address);

    function bridgeSlippage() external view returns (uint256);

    function dstGasForSwapCall() external view returns (uint256);

    function dstGasForNoSwapCall() external view returns (uint256);

    function sgChainIdLocal() external view returns (uint16);

    function orderlyFeeToggle() external view returns (bool);

    function woofiDexCrossChainRouters(uint16 chainId) external view returns (address wooCrossChainRouter);

    function woofiDexVaults(uint16 chainId, address token) external view returns (address woofiDexVault);

    function sgETHs(uint16 chainId) external view returns (address sgETH);

    function sgPoolIds(uint16 chainId, address token) external view returns (uint256 poolId);

    /* ----- Functions ----- */

    function crossSwap(
        address payable to,
        SrcInfos calldata srcInfos,
        DstInfos calldata dstInfos,
        DstVaultDeposit calldata dstVaultDeposit
    ) external payable;

    function sgReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint256 nonce,
        address bridgedToken,
        uint256 amountLD,
        bytes memory payload
    ) external;

    function quoteLayerZeroFee(
        address to,
        DstInfos memory dstInfos,
        DstVaultDeposit calldata dstVaultDeposit
    ) external view returns (uint256 nativeAmount, uint256 zroAmount);

    function allDirectBridgeTokens() external view returns (address[] memory tokens);

    function allDirectBridgeTokensLength() external view returns (uint256 length);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IWOOFiDexVault {
    /* ----- Structs ----- */

    struct VaultDepositFE {
        bytes32 accountId;
        bytes32 brokerHash;
        bytes32 tokenHash;
        uint128 tokenAmount;
    }

    /* ----- Events ----- */

    event AccountDepositTo(
        bytes32 indexed accountId,
        address indexed userAddress,
        uint64 indexed depositNonce,
        bytes32 tokenHash,
        uint128 tokenAmount
    );

    /* ----- Functions ----- */

    function depositTo(address receiver, VaultDepositFE calldata data) external payable;

    function testWoofiDeposit(address receiver, VaultDepositFE calldata data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IStargateRouter {
    /* ----- Structs ----- */

    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    /* ----- Functions ----- */

    function addLiquidity(uint256 poolId, uint256 amountLD, address to) external;

    function swap(
        uint16 dstChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        address payable refundAddress,
        uint256 amountLD,
        uint256 minAmountLD,
        lzTxObj memory lzTxParams,
        bytes calldata to,
        bytes calldata payload
    ) external payable;

    function redeemRemote(
        uint16 dstChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        address payable refundAddress,
        uint256 amountLP,
        uint256 minAmountLD,
        bytes calldata to,
        lzTxObj memory lzTxParams
    ) external payable;

    function instantRedeemLocal(uint16 srcPoolId, uint256 amountLP, address to) external returns (uint256 amountSD);

    function redeemLocal(
        uint16 dstChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        address payable refundAddress,
        uint256 amountLP,
        bytes calldata to,
        lzTxObj memory lzTxParams
    ) external payable;

    function sendCredits(
        uint16 dstChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        address payable refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 dstChainId,
        uint8 functionType,
        bytes calldata toAddress,
        bytes calldata transferAndCallPayload,
        lzTxObj memory lzTxParams
    ) external view returns (uint256 nativeAmount, uint256 zroAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IWooRouterV2 {
    /* ----- State Variables ----- */

    function WETH() external view returns (address);

    function wooPool() external view returns (address);

    /* ----- Functions ----- */

    function querySwap(address fromToken, address toToken, uint256 fromAmount) external view returns (uint256 toAmount);

    function tryQuerySwap(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 toAmount);

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address payable to,
        address rebateTo
    ) external payable returns (uint256 realToAmount);

    function externalSwap(
        address approveTarget,
        address swapTarget,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address payable to,
        bytes calldata data
    ) external payable returns (uint256 realToAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// OpenZeppelin Contracts
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

// Uniswap Periphery
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

// Local Contracts
import {IStargateRouter} from "./interfaces/Stargate/IStargateRouter.sol";
import {IWooRouterV2} from "./interfaces/WOOFi/IWooRouterV2.sol";
import {INonceCounter} from "./interfaces/INonceCounter.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IWOOFiDexCrossChainRouter} from "./interfaces/IWOOFiDexCrossChainRouter.sol";
import {IWOOFiDexVault} from "./interfaces/IWOOFiDexVault.sol";

/// @title WOOFi Dex Router for Cross Chain Swap to Deposit
/// @custom:stargate-contracts https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses
contract WOOFiDexCrossChainRouter is
    IWOOFiDexCrossChainRouter,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /* ----- Constants ----- */

    address public constant NATIVE_PLACEHOLDER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant MAX_BRIDGE_SLIPPAGE = 10000;

    /* ----- Variables ----- */

    address public nonceCounter;
    address public wooRouter;
    address public sgRouter;

    address public weth;
    uint256 public bridgeSlippage; // default 0.2%
    uint256 public dstGasForSwapCall;
    uint256 public dstGasForNoSwapCall;

    uint16 public sgChainIdLocal; // stargate chainId on local chain

    bool public orderlyFeeToggle;

    mapping(uint16 => address) public woofiDexCrossChainRouters; // chainId => WOOFiDexCrossChainRouter address
    mapping(uint16 => mapping(address => address)) public woofiDexVaults; // chainId => token address => WOOFiDexVault address
    mapping(uint16 => address) public sgETHs; // chainId => SGETH token address
    mapping(uint16 => mapping(address => uint256)) public sgPoolIds; // chainId => token address => Stargate poolId

    EnumerableSetUpgradeable.AddressSet private directBridgeTokens;

    receive() external payable {}

    /* ----- Constructor ----- */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* ----- Functions ----- */

    function initialize(
        address _weth,
        address _nonceCounter,
        address _wooRouter,
        address _sgRouter,
        uint16 _sgChainIdLocal
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        nonceCounter = _nonceCounter;
        wooRouter = _wooRouter;
        sgRouter = _sgRouter;

        weth = _weth;
        bridgeSlippage = 20;
        dstGasForSwapCall = 750000;
        dstGasForNoSwapCall = 450000;

        sgChainIdLocal = _sgChainIdLocal;

        orderlyFeeToggle = false;

        _initSgETHs();
        _initSgPoolIds();
    }

    function crossSwap(
        address payable to,
        SrcInfos calldata srcInfos,
        DstInfos calldata dstInfos,
        DstVaultDeposit calldata dstVaultDeposit
    ) external payable whenNotPaused nonReentrant {
        require(to != address(0), "WOOFiDexCrossChainRouter: to not allow");
        require(srcInfos.fromToken != address(0), "WOOFiDexCrossChainRouter: srcInfos.fromToken not allow");
        require(
            dstInfos.toToken != address(0) && dstInfos.toToken != sgETHs[dstInfos.chainId],
            "WOOFiDexCrossChainRouter: dstInfos.toToken not allow"
        );
        require(
            woofiDexVaults[dstInfos.chainId][dstInfos.toToken] != address(0),
            "WOOFiDexCrossChainRouter: woofiDexVault not allow"
        );

        address sender = _msgSender();
        uint256 nativeAmount = msg.value;
        uint256 bridgeAmount;

        {
            address srcFromToken = srcInfos.fromToken;
            if (srcFromToken == NATIVE_PLACEHOLDER) {
                require(srcInfos.fromAmount <= nativeAmount, "WOOFiDexCrossChainRouter: nativeAmount not enough");
                srcFromToken = weth;
                IWETH(weth).deposit{value: srcInfos.fromAmount}();
                nativeAmount -= srcInfos.fromAmount;
            } else {
                TransferHelper.safeTransferFrom(srcFromToken, sender, address(this), srcInfos.fromAmount);
            }

            if (!directBridgeTokens.contains(srcFromToken) && srcFromToken != srcInfos.bridgeToken) {
                TransferHelper.safeApprove(srcFromToken, address(wooRouter), srcInfos.fromAmount);
                bridgeAmount = IWooRouterV2(wooRouter).swap(
                    srcFromToken,
                    srcInfos.bridgeToken,
                    srcInfos.fromAmount,
                    srcInfos.minBridgeAmount,
                    payable(address(this)),
                    to
                );
            } else {
                require(
                    srcInfos.fromAmount == srcInfos.minBridgeAmount,
                    "WOOFiDexCrossChainRouter: srcInfos.minBridgeAmount incorrect"
                );
                bridgeAmount = srcInfos.fromAmount;
            }

            require(
                bridgeAmount <= IERC20Upgradeable(srcInfos.bridgeToken).balanceOf(address(this)),
                "WOOFiDexCrossChainRouter: bridgeAmount exceed balance"
            );
        }

        uint256 nonce = INonceCounter(nonceCounter).increment(dstInfos.chainId);
        {
            uint256 dstMinBridgedAmount = (bridgeAmount * (MAX_BRIDGE_SLIPPAGE - bridgeSlippage)) / MAX_BRIDGE_SLIPPAGE;
            bytes memory payload = abi.encode(
                nonce,
                to,
                dstInfos.toToken,
                dstInfos.minToAmount,
                dstInfos.orderlyNativeFees,
                dstVaultDeposit
            );
            _bridgeByStargate(nativeAmount, bridgeAmount, dstMinBridgedAmount, payload, srcInfos, dstInfos);
        }

        emit WOOFiDexCrossSwapOnSrcChain(
            dstInfos.chainId,
            nonce,
            sender,
            to,
            srcInfos.fromToken,
            srcInfos.fromAmount,
            srcInfos.bridgeToken,
            srcInfos.minBridgeAmount,
            bridgeAmount
        );
    }

    function sgReceive(
        uint16 srcChainId,
        bytes memory, // srcAddress
        uint256, // nonce
        address bridgedToken,
        uint256 bridgedAmount,
        bytes memory payload
    ) external {
        address sender = _msgSender();
        require(sender == address(sgRouter), "WOOFiDexCrossChainRouter: invalid sender");

        (
            uint256 nonce,
            address to,
            address toToken,
            uint256 minToAmount,
            uint256 orderlyNativeFees,
            DstVaultDeposit memory dstVaultDeposit
        ) = abi.decode(payload, (uint256, address, address, uint256, uint256, DstVaultDeposit));

        if (bridgedToken == sgETHs[sgChainIdLocal]) {
            _handleNativeReceived(
                srcChainId,
                nonce,
                sender,
                to,
                bridgedAmount,
                toToken,
                minToAmount,
                orderlyNativeFees,
                dstVaultDeposit
            );
        } else {
            _handleERC20Received(
                srcChainId,
                nonce,
                sender,
                to,
                bridgedToken,
                bridgedAmount,
                toToken,
                minToAmount,
                orderlyNativeFees,
                dstVaultDeposit
            );
        }
    }

    function quoteLayerZeroFee(
        address to,
        DstInfos calldata dstInfos,
        DstVaultDeposit calldata dstVaultDeposit
    ) external view returns (uint256 nativeAmount, uint256 zroAmount) {
        uint256 nonce = INonceCounter(nonceCounter).outboundNonce(dstInfos.chainId) + 1;
        bytes memory payload = abi.encode(
            nonce,
            to,
            dstInfos.toToken,
            dstInfos.minToAmount,
            dstInfos.orderlyNativeFees,
            dstVaultDeposit
        );

        // only bridge via Stargate
        IStargateRouter.lzTxObj memory obj = _getLzTxObj(dstInfos);

        return
            IStargateRouter(sgRouter).quoteLayerZeroFee(
                dstInfos.chainId,
                1, // https://stargateprotocol.gitbook.io/stargate/developers/function-types
                obj.dstNativeAddr,
                payload,
                obj
            );
    }

    function allDirectBridgeTokens() external view returns (address[] memory) {
        uint256 length = directBridgeTokens.length();
        address[] memory tokens = new address[](length);
        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                tokens[i] = directBridgeTokens.at(i);
            }
        }
        return tokens;
    }

    function allDirectBridgeTokensLength() external view returns (uint256) {
        return directBridgeTokens.length();
    }

    function _initSgETHs() internal {
        sgETHs[101] = 0x72E2F4830b9E45d52F80aC08CB2bEC0FeF72eD9c; // Ethereum
        sgETHs[110] = 0x82CbeCF39bEe528B5476FE6d1550af59a9dB6Fc0; // Arbitrum
        sgETHs[111] = 0xb69c8CBCD90A39D8D3d3ccf0a3E968511C3856A0; // Optimism
        sgETHs[183] = 0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03; // Linea
        sgETHs[184] = 0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03; // Base
    }

    function _initSgPoolIds() internal {
        // poolId > 0 means able to be bridge token
        // Ethereum
        sgPoolIds[101][0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 1; // USDC
        sgPoolIds[101][0xdAC17F958D2ee523a2206206994597C13D831ec7] = 2; // USDT
        sgPoolIds[101][0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = 13; // WETH
        sgPoolIds[101][0x4691937a7508860F876c9c0a2a617E7d9E945D4B] = 20; // WOO
        // BNB Chain
        sgPoolIds[102][0x55d398326f99059fF775485246999027B3197955] = 2; // USDT
        sgPoolIds[102][0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56] = 5; // BUSD
        sgPoolIds[102][0x4691937a7508860F876c9c0a2a617E7d9E945D4B] = 20; // WOO
        // Avalanche
        sgPoolIds[106][0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E] = 1; // USDC
        sgPoolIds[106][0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7] = 2; // USDT
        sgPoolIds[106][0xaBC9547B534519fF73921b1FBA6E672b5f58D083] = 20; // WOO
        // Polygon
        sgPoolIds[109][0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174] = 1; // USDC
        sgPoolIds[109][0xc2132D05D31c914a87C6611C10748AEb04B58e8F] = 2; // USDT
        sgPoolIds[109][0x1B815d120B3eF02039Ee11dC2d33DE7aA4a8C603] = 20; // WOO
        // Arbitrum
        sgPoolIds[110][0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8] = 1; // USDC
        sgPoolIds[110][0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9] = 2; // USDT
        sgPoolIds[110][0x82aF49447D8a07e3bd95BD0d56f35241523fBab1] = 13; // WETH
        sgPoolIds[110][0xcAFcD85D8ca7Ad1e1C6F82F651fA15E33AEfD07b] = 20; // WOO
        // Optimism
        sgPoolIds[111][0x7F5c764cBc14f9669B88837ca1490cCa17c31607] = 1; // USDC
        sgPoolIds[111][0x4200000000000000000000000000000000000006] = 13; // WETH
        sgPoolIds[111][0x871f2F2ff935FD1eD867842FF2a7bfD051A5E527] = 20; // WOO
        // Fantom
        sgPoolIds[112][0x04068DA6C83AFCFA0e13ba15A6696662335D5B75] = 1; // USDC
        sgPoolIds[112][0x6626c47c00F1D87902fc13EECfaC3ed06D5E8D8a] = 20; // WOO
        // Linea
        sgPoolIds[183][0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f] = 13; // WETH
        // Base
        sgPoolIds[184][0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA] = 1; // USDC
        sgPoolIds[184][0x4200000000000000000000000000000000000006] = 13; // WETH
    }

    function _getLzTxObj(DstInfos memory dstInfos) internal view returns (IStargateRouter.lzTxObj memory) {
        uint256 dstGasForCall = dstInfos.toToken == dstInfos.bridgedToken ? dstGasForNoSwapCall : dstGasForSwapCall;

        return
            IStargateRouter.lzTxObj(
                dstGasForCall,
                dstInfos.orderlyNativeFees,
                abi.encodePacked(woofiDexCrossChainRouters[dstInfos.chainId])
            );
    }

    function _bridgeByStargate(
        uint256 nativeAmount,
        uint256 bridgeAmount,
        uint256 dstMinBridgedAmount,
        bytes memory payload,
        SrcInfos calldata srcInfos,
        DstInfos calldata dstInfos
    ) internal {
        // avoid stack too deep
        PoolIds memory poolIds;
        {
            poolIds = PoolIds(
                sgPoolIds[sgChainIdLocal][srcInfos.bridgeToken],
                sgPoolIds[dstInfos.chainId][dstInfos.bridgedToken]
            );
        }
        require(poolIds.src > 0, "WOOFiDexCrossChainRouter: poolIds.src not exist");
        require(poolIds.dst > 0, "WOOFiDexCrossChainRouter: poolIds.dst not exist");

        if (srcInfos.bridgeToken == weth) {
            IWETH(weth).withdraw(bridgeAmount);
            nativeAmount += bridgeAmount;
        } else {
            TransferHelper.safeApprove(srcInfos.bridgeToken, address(sgRouter), bridgeAmount);
        }

        IStargateRouter.lzTxObj memory obj = _getLzTxObj(dstInfos);
        IStargateRouter(sgRouter).swap{value: nativeAmount}(
            dstInfos.chainId, // dst chain id
            poolIds.src, // bridge token's pool id on src chain
            poolIds.dst, // bridge token's pool id on dst chain
            payable(_msgSender()), // rebate address
            bridgeAmount, // swap amount on src chain
            dstMinBridgedAmount, // min received amount on dst chain
            obj, // config: dstGasForCall, dstNativeAmount, dstNativeAddr
            abi.encodePacked(woofiDexCrossChainRouters[dstInfos.chainId]), // smart contract to call on dst chain
            payload // payload to piggyback
        );
    }

    function _handleNativeReceived(
        uint16 srcChainId,
        uint256 nonce,
        address sender,
        address to,
        uint256 bridgedAmount,
        address toToken,
        uint256 minToAmount,
        uint256 orderlyNativeFees,
        DstVaultDeposit memory dstVaultDeposit
    ) internal {
        if (toToken == NATIVE_PLACEHOLDER) {
            IWOOFiDexVault.VaultDepositFE memory vaultDepositFE = _depositTo(
                to,
                toToken,
                orderlyNativeFees,
                dstVaultDeposit,
                bridgedAmount
            );
            emit WOOFiDexCrossSwapOnDstChain(
                srcChainId,
                nonce,
                sender,
                to,
                weth,
                bridgedAmount,
                toToken,
                minToAmount,
                toToken,
                bridgedAmount,
                orderlyNativeFees,
                vaultDepositFE.accountId,
                vaultDepositFE.brokerHash,
                vaultDepositFE.tokenHash,
                vaultDepositFE.tokenAmount
            );
        } else {
            try
                IWooRouterV2(wooRouter).swap{value: bridgedAmount}(
                    NATIVE_PLACEHOLDER,
                    toToken,
                    bridgedAmount,
                    minToAmount,
                    payable(address(this)),
                    to
                )
            returns (uint256 realToAmount) {
                IWOOFiDexVault.VaultDepositFE memory vaultDepositFE = _depositTo(
                    to,
                    toToken,
                    orderlyNativeFees,
                    dstVaultDeposit,
                    realToAmount
                );
                emit WOOFiDexCrossSwapOnDstChain(
                    srcChainId,
                    nonce,
                    sender,
                    to,
                    weth,
                    bridgedAmount,
                    toToken,
                    minToAmount,
                    toToken,
                    realToAmount,
                    orderlyNativeFees,
                    vaultDepositFE.accountId,
                    vaultDepositFE.brokerHash,
                    vaultDepositFE.tokenHash,
                    vaultDepositFE.tokenAmount
                );
            } catch {
                TransferHelper.safeTransferETH(to, bridgedAmount + orderlyNativeFees);
                emit WOOFiDexCrossSwapOnDstChain(
                    srcChainId,
                    nonce,
                    sender,
                    to,
                    weth,
                    bridgedAmount,
                    toToken,
                    minToAmount,
                    NATIVE_PLACEHOLDER,
                    bridgedAmount,
                    orderlyNativeFees,
                    bytes32(0),
                    bytes32(0),
                    bytes32(0),
                    0
                );
            }
        }
    }

    function _handleERC20Received(
        uint16 srcChainId,
        uint256 nonce,
        address sender,
        address to,
        address bridgedToken,
        uint256 bridgedAmount,
        address toToken,
        uint256 minToAmount,
        uint256 orderlyNativeFees,
        DstVaultDeposit memory dstVaultDeposit
    ) internal {
        if (toToken == bridgedToken) {
            IWOOFiDexVault.VaultDepositFE memory vaultDepositFE = _depositTo(
                to,
                toToken,
                orderlyNativeFees,
                dstVaultDeposit,
                bridgedAmount
            );
            emit WOOFiDexCrossSwapOnDstChain(
                srcChainId,
                nonce,
                sender,
                to,
                bridgedToken,
                bridgedAmount,
                toToken,
                minToAmount,
                toToken,
                bridgedAmount,
                orderlyNativeFees,
                vaultDepositFE.accountId,
                vaultDepositFE.brokerHash,
                vaultDepositFE.tokenHash,
                vaultDepositFE.tokenAmount
            );
        } else {
            TransferHelper.safeApprove(bridgedToken, address(wooRouter), bridgedAmount);
            try
                IWooRouterV2(wooRouter).swap(
                    bridgedToken,
                    toToken,
                    bridgedAmount,
                    minToAmount,
                    payable(address(this)),
                    to
                )
            returns (uint256 realToAmount) {
                IWOOFiDexVault.VaultDepositFE memory vaultDepositFE = _depositTo(
                    to,
                    toToken,
                    orderlyNativeFees,
                    dstVaultDeposit,
                    realToAmount
                );
                emit WOOFiDexCrossSwapOnDstChain(
                    srcChainId,
                    nonce,
                    sender,
                    to,
                    bridgedToken,
                    bridgedAmount,
                    toToken,
                    minToAmount,
                    toToken,
                    realToAmount,
                    orderlyNativeFees,
                    vaultDepositFE.accountId,
                    vaultDepositFE.brokerHash,
                    vaultDepositFE.tokenHash,
                    vaultDepositFE.tokenAmount
                );
            } catch {
                TransferHelper.safeApprove(bridgedToken, address(wooRouter), 0);
                TransferHelper.safeTransfer(bridgedToken, to, bridgedAmount);
                if (orderlyNativeFees != 0) {
                    TransferHelper.safeTransferETH(to, orderlyNativeFees);
                }
                emit WOOFiDexCrossSwapOnDstChain(
                    srcChainId,
                    nonce,
                    sender,
                    to,
                    bridgedToken,
                    bridgedAmount,
                    toToken,
                    minToAmount,
                    bridgedToken,
                    bridgedAmount,
                    orderlyNativeFees,
                    bytes32(0),
                    bytes32(0),
                    bytes32(0),
                    0
                );
            }
        }
    }

    function _depositTo(
        address to,
        address toToken,
        uint256 orderlyNativeFees,
        DstVaultDeposit memory dstVaultDeposit,
        uint256 tokenAmount
    ) internal returns (IWOOFiDexVault.VaultDepositFE memory) {
        IWOOFiDexVault.VaultDepositFE memory vaultDepositFE = IWOOFiDexVault.VaultDepositFE(
            dstVaultDeposit.accountId,
            dstVaultDeposit.brokerHash,
            dstVaultDeposit.tokenHash,
            uint128(tokenAmount)
        );
        address woofiDexVault = woofiDexVaults[sgChainIdLocal][toToken];
        uint256 depositToFees = orderlyFeeToggle ? orderlyNativeFees : 0;
        if (toToken == NATIVE_PLACEHOLDER) {
            IWOOFiDexVault(woofiDexVault).testWoofiDeposit{value: tokenAmount + depositToFees}(to, vaultDepositFE);
        } else {
            TransferHelper.safeApprove(toToken, woofiDexVault, tokenAmount);
            if (depositToFees == 0) {
                IWOOFiDexVault(woofiDexVault).testWoofiDeposit(to, vaultDepositFE);
            } else {
                IWOOFiDexVault(woofiDexVault).testWoofiDeposit{value: depositToFees}(to, vaultDepositFE);
            }
        }

        return vaultDepositFE;
    }

    /* ----- Owner & Admin Functions ----- */

    function setNonceCounter(address _nonceCounter) external onlyOwner {
        require(_nonceCounter != address(0), "WOOFiDexCrossChainRouter: _nonceCounter cant be zero");
        nonceCounter = _nonceCounter;
    }

    function setWooRouter(address _wooRouter) external onlyOwner {
        require(_wooRouter != address(0), "WOOFiDexCrossChainRouter: _wooRouter cant be zero");
        wooRouter = _wooRouter;
    }

    function setSgRouter(address _sgRouter) external onlyOwner {
        require(_sgRouter != address(0), "WOOFiDexCrossChainRouter: _sgRouter cant be zero");
        sgRouter = _sgRouter;
    }

    function setBridgeSlippage(uint256 _bridgeSlippage) external onlyOwner {
        require(_bridgeSlippage <= MAX_BRIDGE_SLIPPAGE, "WOOFiDexCrossChainRouter: _bridgeSlippage exceed max");
        bridgeSlippage = _bridgeSlippage;
    }

    function setDstGasForSwapCall(uint256 _dstGasForSwapCall) external onlyOwner {
        dstGasForSwapCall = _dstGasForSwapCall;
    }

    function setDstGasForNoSwapCall(uint256 _dstGasForNoSwapCall) external onlyOwner {
        dstGasForNoSwapCall = _dstGasForNoSwapCall;
    }

    function setSgChainIdLocal(uint16 _sgChainIdLocal) external onlyOwner {
        sgChainIdLocal = _sgChainIdLocal;
    }

    function setOrderlyFeeToggle(bool _orderlyFeeToggle) external onlyOwner {
        orderlyFeeToggle = _orderlyFeeToggle;
    }

    function setWOOFiDexCrossChainRouter(uint16 chainId, address woofiDexCrossChainRouter) external onlyOwner {
        require(
            woofiDexCrossChainRouter != address(0),
            "WOOFiDexCrossChainRouter: woofiDexCrossChainRouter cant be zero"
        );
        woofiDexCrossChainRouters[chainId] = woofiDexCrossChainRouter;
    }

    function setWOOFiDexVault(uint16 chainId, address token, address woofiDexVault) external onlyOwner {
        require(woofiDexVault != address(0), "WOOFiDexCrossChainRouter: woofiDexVault cant be zero");
        woofiDexVaults[chainId][token] = woofiDexVault;
    }

    function setSgETH(uint16 chainId, address token) external onlyOwner {
        require(token != address(0), "WOOFiDexCrossChainRouter: token cant be zero");
        sgETHs[chainId] = token;
    }

    function setSgPoolId(uint16 chainId, address token, uint256 poolId) external onlyOwner {
        sgPoolIds[chainId][token] = poolId;
    }

    function addDirectBridgeToken(address token) external onlyOwner {
        bool success = directBridgeTokens.add(token);
        require(success, "WOOFiDexCrossChainRouter: token exist");
    }

    function removeDirectBridgeToken(address token) external onlyOwner {
        bool success = directBridgeTokens.remove(token);
        require(success, "WOOFiDexCrossChainRouter: token not exist");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function inCaseTokenGotStuck(address stuckToken) external onlyOwner {
        address sender = _msgSender();
        if (stuckToken == NATIVE_PLACEHOLDER) {
            TransferHelper.safeTransferETH(sender, address(this).balance);
        } else {
            uint256 amount = IERC20Upgradeable(stuckToken).balanceOf(address(this));
            TransferHelper.safeTransfer(stuckToken, sender, amount);
        }
    }
}