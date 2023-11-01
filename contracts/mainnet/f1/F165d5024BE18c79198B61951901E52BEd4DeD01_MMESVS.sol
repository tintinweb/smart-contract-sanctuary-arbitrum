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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {Errors} from "../libraries/Errors.sol";
import {ILPTokenSVS} from "../interfaces/ILPTokenSVS.sol";
import {IVault1155} from "../interfaces/IVault1155.sol";
import {ISVS} from "../interfaces/ISVS.sol";
import {ISVSCollectionConnector} from "../interfaces/ISVSCollectionConnector.sol";

/**
 * @title LPTokenSVS
 * @author Souq.Finance
 * @notice The LP Token contract of each svs liquidity pool
 * @notice License: https://souq-exchange.s3.amazonaws.com/LICENSE.md
 */
contract LPTokenSVS is ILPTokenSVS, ERC20, ERC20Burnable, Pausable {
    using SafeERC20 for IERC20;
    IAddressesRegistry internal immutable addressesRegistry;
    address public immutable pool;
    uint8 public immutable tokenDecimals;

    constructor(
        address _pool,
        address registry,
        address[] memory tokens,
        string memory _symbol,
        string memory _name,
        uint8 _decimals
    ) ERC20(_name, _symbol) {
        require(_pool != address(0), Errors.ADDRESS_IS_ZERO);
        require(registry != address(0), Errors.ADDRESS_IS_ZERO);
        tokenDecimals = _decimals;
        pool = _pool;
        addressesRegistry = IAddressesRegistry(registry);
        for (uint256 i = 0; i < tokens.length; ++i) {
            ISVS(IVault1155(tokens[i]).getSVS()).setApprovalForAll(address(pool), true);
        }
    }

    /**
     * @dev modifier for when the the msg sender is the liquidity pool that created it only
     */
    modifier onlyPool() {
        require(_msgSender() == address(pool), Errors.CALLER_MUST_BE_POOL);
        _;
    }

    /**
     * @dev Returns the number of decimals for this token. Public due to override.
     * @return uint8 the number of decimals
     */
    function decimals() public view override(ERC20,ILPTokenSVS) returns (uint8) {
        return tokenDecimals;
    }

    /// @inheritdoc ILPTokenSVS
    function getTotal() external view returns (uint256) {
        return totalSupply();
    }

    /// @inheritdoc ILPTokenSVS
    function getBalanceOf(address account) external view returns (uint256) {
        return balanceOf(account);
    }

    /// @inheritdoc ILPTokenSVS
    function pause() external onlyPool {
        //_pause already emits an event
        _pause();
    }

    /// @inheritdoc ILPTokenSVS
    function unpause() external onlyPool {
        //_unpause already emits an event
        _unpause();
    }

    /// @inheritdoc ILPTokenSVS
    function checkPaused() external view returns (bool) {
        return paused();
    }

    /// @inheritdoc ILPTokenSVS
    function setApproval20(address token, uint256 amount) external onlyPool {
        bool returnApproved = IERC20(token).approve(pool, amount);
        require(returnApproved, Errors.APPROVAL_FAILED);
    }

    /// @inheritdoc ILPTokenSVS
    function checkApproval1155(address[] memory tokens) external onlyPool
    {
        for (uint256 i = 0; i < tokens.length; ++i) {
            if(!ISVS(IVault1155(tokens[i]).getSVS()).isApprovedForAll(address(this),address(pool)))
            ISVS(IVault1155(tokens[i]).getSVS()).setApprovalForAll(address(pool), true);
        }
    }

    /// @inheritdoc ILPTokenSVS
    function mint(address to, uint256 amount) external onlyPool {
        //_mint already emits a transfer event
        _mint(to, amount);
    }

    /// @inheritdoc ILPTokenSVS
    function burn(address from, uint256 amount) external onlyPool {
        //_burn already emits a transfer event
        _burn(from, amount);
    }

    /// @inheritdoc ILPTokenSVS
    function rescueTokens(address token, uint256 amount, address receiver) external onlyPool {
        //event emitted in the pool logic library
        IERC20(token).safeTransfer(receiver, amount);
    }

    /**
     * @dev Implementation of the ERC1155 token received hook.
     */
    function onERC1155Received(address, address, uint256, uint256, bytes memory) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev Implementation of the ERC1155 batch token received hook.
     */
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /// @inheritdoc ILPTokenSVS
    function redeemShares(address collection, uint256 id, uint256 amount) external onlyPool {
        IVault1155(collection).redeemUnderlying(amount, id);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IMMEBase} from "../interfaces/IMMEBase.sol";
import {Errors} from "../libraries/Errors.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {IAccessManager} from "../interfaces/IAccessManager.sol";

/**
 * @title MMEBase
 * @author Souq.Finance
 * @notice The Base contract to be inherited by MMEs
 * @notice License: https://souq-exchange.s3.amazonaws.com/LICENSE.md
 */
contract MMEBase is IMMEBase {
    using Math for uint256;
    uint256 public yieldReserve;
    address public immutable addressesRegistry;
    DataTypes.PoolSVSData public poolData;
    uint256[50] __gap;

    constructor(address _registry) {
        require(_registry != address(0), Errors.ADDRESS_IS_ZERO);
        addressesRegistry = _registry;
    }

    /**
     * @dev modifier for when the the msg sender is pool admin in the access manager
     */
    modifier onlyPoolAdmin() {
        require(
            IAccessManager(IAddressesRegistry(addressesRegistry).getAccessManager()).isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_POOL_ADMIN
        );
        _;
    }

    /**
     * @dev modifier for when the the msg sender is either pool admin or pool operations in the access manager
     */
    modifier onlyPoolAdminOrOperations() {
        require(
            IAccessManager(IAddressesRegistry(addressesRegistry).getAccessManager()).isPoolAdmin(msg.sender) ||
                IAccessManager(IAddressesRegistry(addressesRegistry).getAccessManager()).isPoolOperations(msg.sender),
            Errors.CALLER_NOT_POOL_ADMIN_OR_OPERATIONS
        );
        _;
    }

    /// @inheritdoc IMMEBase
    function setFee(DataTypes.PoolFee calldata newFee) external onlyPoolAdmin {
        poolData.fee.lpBuyFee = newFee.lpBuyFee;
        poolData.fee.lpSellFee = newFee.lpSellFee;
        poolData.fee.royaltiesBuyFee = newFee.royaltiesBuyFee;
        poolData.fee.royaltiesSellFee = newFee.royaltiesSellFee;
        poolData.fee.protocolBuyRatio = newFee.protocolBuyRatio;
        poolData.fee.protocolSellRatio = newFee.protocolSellRatio;
        poolData.fee.royaltiesAddress = newFee.royaltiesAddress;
        poolData.fee.protocolFeeAddress = newFee.protocolFeeAddress;
        emit FeeChanged(poolData.fee);
    }

    /// @inheritdoc IMMEBase
    function setPoolIterativeLimits(DataTypes.IterativeLimit calldata newLimits) external onlyPoolAdmin {
        poolData.iterativeLimit.minimumF = newLimits.minimumF;
        poolData.iterativeLimit.maxBulkStepSize = newLimits.maxBulkStepSize;
        poolData.iterativeLimit.iterations = newLimits.iterations;
        emit PoolIterativeLimitsSet(poolData.iterativeLimit);
    }

    /// @inheritdoc IMMEBase
    function setPoolLiquidityLimits(DataTypes.LiquidityLimit calldata newLimits) external onlyPoolAdmin {
        poolData.liquidityLimit.poolTvlLimit = newLimits.poolTvlLimit;
        poolData.liquidityLimit.cooldown = newLimits.cooldown;
        poolData.liquidityLimit.maxDepositPercentage = newLimits.maxDepositPercentage;
        poolData.liquidityLimit.maxWithdrawPercentage = newLimits.maxWithdrawPercentage;
        poolData.liquidityLimit.feeMultiplier = newLimits.feeMultiplier;
        poolData.liquidityLimit.lastLpPrice = newLimits.lastLpPrice;
        poolData.liquidityLimit.addLiqMode = newLimits.addLiqMode;
        poolData.liquidityLimit.removeLiqMode = newLimits.removeLiqMode;
        poolData.liquidityLimit.onlyAdminProvisioning = newLimits.onlyAdminProvisioning;
        emit PoolLiquidityLimitsSet(poolData.liquidityLimit);
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Errors} from "../libraries/Errors.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {PoolSVSLogic} from "../libraries/PoolSVSLogic.sol";
import {MaturitySVSLogic} from "../libraries/MaturitySVSLogic.sol";
import {LiquiditySVSLogic} from "../libraries/LiquiditySVSLogic.sol";
import {MMEBase} from "./MMEBase.sol";
import {IMMESVS} from "../interfaces/IMMESVS.sol";
import {ILPTokenSVS} from "../interfaces/ILPTokenSVS.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {IAccessManager} from "../interfaces/IAccessManager.sol";
import {IAccessNFT} from "../interfaces/IAccessNFT.sol";
import {IERC20Extended} from "../interfaces/IERC20Extended.sol";
import {ISVSCollectionConnector} from "../interfaces/ISVSCollectionConnector.sol";
import {IConnectorRouter} from "../interfaces/IConnectorRouter.sol";

/**
 * @title MMESVS
 * @author Souq.Finance
 * @notice The Contract of all Pools sharing MMESVS specification for single collection of shares
 * @notice The fees inputted should be in wad
 * @notice The F inputted should be in wad
 * @notice the V updated should have the same decimals of the stablecoin and be in terms of the same stablecoin
 * @notice coefficients are in wad
 * @notice License: https://souq-exchange.s3.amazonaws.com/LICENSE.md
 */

contract MMESVS is Initializable, IMMESVS, MMEBase, ReentrancyGuardUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    using PoolSVSLogic for DataTypes.AMMSubPoolSVS[];

    DataTypes.AMMSubPoolSVS[] public subPools;
    address public immutable factory;

    //Liquidity providers have a time waiting period between deposit and withdraw
    DataTypes.Queued1155Withdrawals public queuedWithdrawals;

    DataTypes.PoolSVSData public poolSVSData;
    uint256[50] _gap;

    constructor(address _factory, address addressRegistry) MMEBase(addressRegistry) {
        require(_factory != address(0), Errors.ADDRESS_IS_ZERO);
        factory = _factory;
    }

    /**
     * @dev Initializer function of the contract
     * @param _poolData the initial pool data
     * @param symbol the symbol of the lp token to be deployed
     * @param name the name of the lp token to be deployed
     */
    function initialize(DataTypes.PoolSVSData memory _poolData, string memory symbol, string memory name) external initializer {
        __Pausable_init();
        __Ownable_init();
        poolData = _poolData;
        poolData.fee.royaltiesBalance = 0;
        poolData.fee.royaltiesBalance = 0;
        poolData.poolLPToken = PoolSVSLogic.deployLPToken(
            address(this),
            addressesRegistry,
            poolData.tokens,
            symbol,
            name,
            IERC20Extended(poolData.stable).decimals()
        );
        yieldReserve = 0;
        PoolSVSLogic.addSubPool(0, 0, 0, subPools);
        poolData.firstActivePool = 1;
    }

    /**
     * @dev modifier for the functions to be called by the timelock contract only
     */
    modifier timelockOnly() {
        if (IAddressesRegistry(addressesRegistry).getAddress("TIMELOCK") != address(0)) {
            require(IAddressesRegistry(addressesRegistry).getAddress("TIMELOCK") == msg.sender, Errors.CALLER_NOT_TIMELOCK);
        }
        _;
    }

    /**
     * @dev modifier for the access token enabled functions
     * @param tokenId the id of the access token
     * @param functionName the name of the function with the modifier
     */
    modifier useAccessNFT(uint256 tokenId, string memory functionName) {
        if (poolData.useAccessToken) {
            require(IAccessNFT(poolData.accessToken).HasAccessNFT(msg.sender, tokenId, functionName), Errors.FUNCTION_REQUIRES_ACCESS_NFT);
        }
        _;
    }

    /**
     * @dev modifier for when the onlyAdminProvisioning is true to restrict liquidity addition to pool admin
     */
    modifier checkAdminProvisioning() {
        if (poolData.liquidityLimit.onlyAdminProvisioning) {
            require(
                IAccessManager(IAddressesRegistry(addressesRegistry).getAccessManager()).isPoolAdmin(msg.sender),
                Errors.ONLY_ADMIN_CAN_ADD_LIQUIDITY
            );
        }
        _;
    }

    /// @inheritdoc IMMESVS
    function pause() external onlyPoolAdmin {
        _pause();
        emit PoolPaused(msg.sender);
        ILPTokenSVS(poolData.poolLPToken).pause();
    }

    /// @inheritdoc IMMESVS
    function unpause() external timelockOnly {
        _unpause();
        emit PoolUnpaused(msg.sender);
        ILPTokenSVS(poolData.poolLPToken).unpause();
    }

    /// @inheritdoc IMMESVS
    function getTVL() external view returns (uint256) {
        (, uint256 tvl, , ) = PoolSVSLogic.calculateLiquidityDetailsIterative(addressesRegistry, poolData, subPools);
        return tvl;
    }

    /// @inheritdoc IMMESVS
    function getLPToken() external view returns (address) {
        return poolData.poolLPToken;
    }

    /// @inheritdoc IMMESVS
    function getLPPrice() external view returns (uint256) {
        (, , , uint256 lpPrice) = PoolSVSLogic.calculateLiquidityDetailsIterative(addressesRegistry, poolData, subPools);
        return lpPrice;
    }

    /// @inheritdoc IMMESVS
    function getPool(uint256 subPoolId) external view returns (DataTypes.AMMSubPoolSVSDetails memory subpool) {
        return PoolSVSLogic.getPool(subPools, subPoolId);
    }

    /// @inheritdoc IMMESVS
    function getSubPoolTotal(uint256 subPoolId) external view returns (uint256) {
        (uint256 v, , , ) = PoolSVSLogic.calculateLiquidityDetailsIterative(addressesRegistry, poolData, subPools);
        return PoolSVSLogic.calculateTotal(subPools, v, subPoolId);
    }

    /// @inheritdoc IMMESVS
    function getQuote(
        uint256[] calldata amounts,
        uint256[] calldata tokenIds,
        bool buy,
        bool useFee
    ) external view returns (DataTypes.Quotation memory quotation) {
        DataTypes.Shares1155Params memory sharesParams = DataTypes.Shares1155Params({amounts: amounts, tokenIds: tokenIds});
        quotation = LiquiditySVSLogic.getQuote(
            DataTypes.QuoteParams({buy: buy, useFee: useFee}),
            sharesParams,
            addressesRegistry,
            poolData,
            subPools
        );
    }

    /// @inheritdoc IMMESVS
    function swapStable(
        uint256[] memory requiredAmounts,
        uint256[] memory tokenIds,
        uint256 maxStable
    ) external nonReentrant useAccessNFT(1, "swapStable") whenNotPaused {
        DataTypes.Shares1155Params memory sharesParams = DataTypes.Shares1155Params({amounts: requiredAmounts, tokenIds: tokenIds});
        LiquiditySVSLogic.swapStable(msg.sender, maxStable, sharesParams, addressesRegistry, poolData, subPools);
    }

    /// @inheritdoc IMMESVS
    function swapShares(
        uint256[] memory amounts,
        uint256[] memory tokenIds,
        uint256 minStable
    ) external nonReentrant useAccessNFT(1, "swapShares") whenNotPaused {
        DataTypes.Shares1155Params memory sharesParams = DataTypes.Shares1155Params({amounts: amounts, tokenIds: tokenIds});
        LiquiditySVSLogic.swapShares(msg.sender, minStable, yieldReserve, sharesParams, addressesRegistry, poolData, subPools);
    }

    /// @inheritdoc IMMESVS
    function depositInitial(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 stableIn,
        uint256 subPoolId
    ) external nonReentrant onlyPoolAdmin {
        DataTypes.Shares1155Params memory sharesParams = DataTypes.Shares1155Params({amounts: amounts, tokenIds: tokenIds});
        LiquiditySVSLogic.depositInitial(msg.sender, subPoolId, stableIn, sharesParams, addressesRegistry, poolData, subPools);
    }

    /// @inheritdoc IMMESVS
    function addLiquidityStable(
        uint256 targetLP,
        uint256 maxStable
    ) external nonReentrant useAccessNFT(1, "addLiquidityStable") checkAdminProvisioning whenNotPaused {
        require(poolData.liquidityLimit.addLiqMode != 1, Errors.LIQUIDITY_MODE_RESTRICTED);
        LiquiditySVSLogic.addLiquidityStable(msg.sender, targetLP, maxStable, addressesRegistry, poolData, subPools);
    }

    /// @inheritdoc IMMESVS
    function removeLiquidityStable(uint256 targetLP, uint256 minStable) external nonReentrant whenNotPaused {
        require(poolData.liquidityLimit.removeLiqMode != 1, Errors.LIQUIDITY_MODE_RESTRICTED);
        LiquiditySVSLogic.removeLiquidityStable(
            msg.sender,
            yieldReserve,
            targetLP,
            minStable,
            addressesRegistry,
            poolData,
            subPools,
            queuedWithdrawals
        );
    }

    /// @inheritdoc IMMESVS
    // function processWithdrawals(uint256 limit) external whenNotPaused returns (uint256 transactions) {
    // transactions = LiquiditySVSLogic.processWithdrawals(limit, poolData, queuedWithdrawals);
    //     transactions = 0;
    // }

    /// @inheritdoc IMMESVS
    function getTokenIdAvailable(uint256 tokenId) external view returns (uint256) {
        (uint256 id, , , , ) = PoolSVSLogic.checkSubPool(tokenId, addressesRegistry, poolData, subPools);
        return subPools[id].shares[tokenId].amount;
    }

    /// @inheritdoc IMMESVS
    function getSubPools(uint256[] memory tokenIds) external view returns (uint256[] memory) {
        return PoolSVSLogic.getSubPools(tokenIds, addressesRegistry, poolData, subPools);
    }

    /// @inheritdoc IMMESVS
    function addSubPool(uint256 f, uint256 start, uint256 lockupTime) external onlyPoolAdmin {
        PoolSVSLogic.addSubPool(f, start, lockupTime, subPools);
    }

    function addSubPoolsAuto(uint256 f, uint256 start) external onlyPoolAdmin {
        PoolSVSLogic.addSubPoolsAuto(f, start, addressesRegistry, poolData, subPools);
    }

    /// @inheritdoc IMMESVS
    function changeSubPoolStatus(uint256[] calldata subPoolIds, bool newStatus) external onlyPoolAdmin {
        PoolSVSLogic.changeSubPoolStatus(subPoolIds, newStatus, subPools);
    }

    /// @inheritdoc IMMESVS
    function moveReserve(uint256 moverId, uint256 movedId, uint256 amount) external onlyPoolAdmin {
        LiquiditySVSLogic.moveReserve(moverId, movedId, amount, addressesRegistry, poolData, subPools);
    }

    // /// @inheritdoc IMMESVS
    // function RescueTokens(address token, uint256 amount, address receiver) external onlyPoolAdmin {
    //     PoolSVSLogic.RescueTokens(token, amount, receiver, poolData.stable, poolData.poolLPToken);
    // }

    /// @inheritdoc IMMESVS
    function WithdrawFees(address to, uint256 amount, DataTypes.FeeType feeType) external {
        LiquiditySVSLogic.withdrawFees(msg.sender, to, amount, feeType, poolData);
    }

    /// @inheritdoc IMMESVS
    function updateMaxMaturityRange(uint256 f, uint256 newMaxMaturityRange) external onlyPoolAdmin {
        MaturitySVSLogic.updateMaxMaturityRange(f, newMaxMaturityRange, addressesRegistry, poolData, subPools);
    }

    /// @inheritdoc IMMESVS
    function getMatureShares() external view returns (DataTypes.VaultSharesReturn[] memory) {
        return MaturitySVSLogic.getMatureShares(poolData, subPools);
    }

    /// @inheritdoc IMMESVS
    function moveMatureShares(uint256 maxTrancheCount) external onlyPoolAdminOrOperations returns (uint256 trancheCount) {
        return MaturitySVSLogic.moveMatureShares(addressesRegistry, poolData, subPools, maxTrancheCount);
    }

    /// @inheritdoc IMMESVS
    function moveMatureSharesList(
        uint256[] memory tranches,
        uint256[] memory amounts
    ) external onlyPoolAdminOrOperations returns (uint256 trancheCount) {
        return MaturitySVSLogic.moveMatureSharesList(addressesRegistry, poolData, subPools, tranches, amounts);
    }

    /// @inheritdoc IMMESVS
    function cleanMatureSubPools() external onlyPoolAdminOrOperations {
        MaturitySVSLogic.cleanMatureSubPools(poolData, subPools);
    }

    /// @inheritdoc IMMESVS
    function redeemMatureShares(uint256 maxTrancheCount) external onlyPoolAdminOrOperations returns (uint256 trancheCount) {
        return MaturitySVSLogic.redeemMatureShares(addressesRegistry, poolData, subPools, maxTrancheCount);
    }

    /// @inheritdoc IMMESVS
    function redistrubteLiquidity() external onlyPoolAdminOrOperations {
        LiquiditySVSLogic.redistrubteLiquidity(addressesRegistry, poolData, subPools);
    }

    // /// @inheritdoc IMMESVS
    // function changeLockupTimes(uint256[] memory lastLockupTimes) external onlyPoolAdmin {
    //     MaturitySVSLogic.changeLockupTimes(addressesRegistry, poolData, subPools, lastLockupTimes);
    // }

    /// @inheritdoc IMMESVS
    function getSubPoolsCount() external view returns (uint256 count) {
        count = subPools.length;
    }

    /// @inheritdoc IMMESVS
    function setPoolData(DataTypes.PoolSVSData calldata newPoolData) external onlyPoolAdmin {
        PoolSVSLogic.setPoolData(addressesRegistry, poolData, subPools, newPoolData);
    }

    /**
     * @dev Implementation of the ERC1155 token received hook.
     */
    function onERC1155Received(address, address, uint256, uint256, bytes memory) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IAddressesRegistry} from "./IAddressesRegistry.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title IAccessManager
 * @author Souq.Finance
 * @notice The interface for the Access Manager Contract
 * @notice License: https://souq-peripherals.s3.amazonaws.com/LICENSE.md
 */
interface IAccessManager is IAccessControl {
    /**
     * @notice Returns the contract address of the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider
     */
    function ADDRESSES_PROVIDER() external view returns (IAddressesRegistry);

    /**
     * @notice Returns the identifier of the Pool Operations role
     * @return The id of the Pool Operations role
     */
    function POOL_OPERATIONS_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the PoolAdmin role
     * @return The id of the PoolAdmin role
     */
    function POOL_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the EmergencyAdmin role
     * @return The id of the EmergencyAdmin role
     */
    function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the OracleAdmin role
     * @return The id of the Oracle role
     */
    function ORACLE_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the ConnectorRouterAdmin role
     * @return The id of the ConnectorRouterAdmin role
     */
    function CONNECTOR_ROUTER_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the StablecoinYieldConnectorAdmin role
     * @return The id of the StablecoinYieldConnectorAdmin role
     */
    function STABLECOIN_YIELD_CONNECTOR_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the StablecoinYieldConnectorLender role
     * @return The id of the StablecoinYieldConnectorLender role
     */
    function STABLECOIN_YIELD_CONNECTOR_LENDER_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the UpgraderAdmin role
     * @return The id of the UpgraderAdmin role
     */

    function UPGRADER_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the TimelockAdmin role
     * @return The id of the TimelockAdmin role
     */

    function TIMELOCK_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @dev set the default admin for the contract
     * @param newAdmin The new default admin address
     */
    function changeDefaultAdmin(address newAdmin) external;

    /**
     * @dev return the version of the contract
     * @return the version of the contract
     */
    function getVersion() external pure returns (uint256);

    /**
     * @notice Set the role as admin of a specific role.
     * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
     * @param role The role to be managed by the admin role
     * @param adminRole The admin role
     */

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @notice Adds a new admin as PoolAdmin
     * @param admin The address of the new admin
     */
    function addPoolAdmin(address admin) external;

    /**
     * @notice Removes an admin as PoolAdmin
     * @param admin The address of the admin to remove
     */
    function removePoolAdmin(address admin) external;

    /**
     * @notice Returns true if the address is PoolAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is PoolAdmin, false otherwise
     */
    function isPoolAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as Pool Operations
     * @param admin The address of the new admin
     */
    function addPoolOperations(address admin) external;

    /**
     * @notice Removes an admin as Pool Operations
     * @param admin The address of the admin to remove
     */
    function removePoolOperations(address admin) external;

    /**
     * @notice Returns true if the address is Pool Operations, false otherwise
     * @param admin The address to check
     * @return True if the given address is Pool Operations, false otherwise
     */
    function isPoolOperations(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as EmergencyAdmin
     * @param admin The address of the new admin
     */
    function addEmergencyAdmin(address admin) external;

    /**
     * @notice Removes an admin as EmergencyAdmin
     * @param admin The address of the admin to remove
     */
    function removeEmergencyAdmin(address admin) external;

    /**
     * @notice Returns true if the address is EmergencyAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is EmergencyAdmin, false otherwise
     */
    function isEmergencyAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as OracleAdmin
     * @param admin The address of the new admin
     */
    function addOracleAdmin(address admin) external;

    /**
     * @notice Removes an admin as OracleAdmin
     * @param admin The address of the admin to remove
     */
    function removeOracleAdmin(address admin) external;

    /**
     * @notice Returns true if the address is OracleAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is OracleAdmin, false otherwise
     */
    function isOracleAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as ConnectorRouterAdmin
     * @param admin The address of the new admin
     */
    function addConnectorAdmin(address admin) external;

    /**
     * @notice Removes an admin as ConnectorRouterAdmin
     * @param admin The address of the admin to remove
     */
    function removeConnectorAdmin(address admin) external;

    /**
     * @notice Returns true if the address is ConnectorRouterAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is ConnectorRouterAdmin, false otherwise
     */
    function isConnectorAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as StablecoinYieldConnectorAdmin
     * @param admin The address of the new admin
     */
    function addStablecoinYieldAdmin(address admin) external;

    /**
     * @notice Removes an admin as StablecoinYieldConnectorAdmin
     * @param admin The address of the admin to remove
     */
    function removeStablecoinYieldAdmin(address admin) external;

    /**
     * @notice Returns true if the address is StablecoinYieldConnectorAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is StablecoinYieldConnectorAdmin, false otherwise
     */
    function isStablecoinYieldAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as StablecoinYieldLender
     * @param lender The address of the new lender
     */
    function addStablecoinYieldLender(address lender) external;

    /**
     * @notice Removes an lender as StablecoinYieldLender
     * @param lender The address of the lender to remove
     */
    function removeStablecoinYieldLender(address lender) external;

    /**
     * @notice Returns true if the address is StablecoinYieldLender, false otherwise
     * @param lender The address to check
     * @return True if the given address is StablecoinYieldLender, false otherwise
     */
    function isStablecoinYieldLender(address lender) external view returns (bool);

    /**
     * @notice Adds a new admin as UpgraderAdmin
     * @param admin The address of the new admin
     */
    function addUpgraderAdmin(address admin) external;

    /**
     * @notice Removes an admin as UpgraderAdmin
     * @param admin The address of the admin to remove
     */
    function removeUpgraderAdmin(address admin) external;

    /**
     * @notice Returns true if the address is UpgraderAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is UpgraderAdmin, false otherwise
     */
    function isUpgraderAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as TimelockAdmin
     * @param admin The address of the new admin
     */
    function addTimelockAdmin(address admin) external;

    /**
     * @notice Removes an admin as TimelockAdmin
     * @param admin The address of the admin to remove
     */
    function removeTimelockAdmin(address admin) external;

    /**
     * @notice Returns true if the address is TimelockAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is TimelockAdmin, false otherwise
     */
    function isTimelockAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title IAccessNFT
 * @author Souq.Finance
 * @notice Defines the interface of the Access NFT contract
 * @notice License: https://souq-peripherals.s3.amazonaws.com/LICENSE.md
 */
interface IAccessNFT {
    /**
     * @dev Event emitted wjem deadline for the function name and token id combination is set
     * @param functionName The function name in bytes32
     * @param deadline The deadline is seconds
     * @param tokenId The token id
     */
    event DeadlineSet(string functionName, bytes32 functionHash, uint256 deadline, uint256 tokenId);

    /**
     * @dev event emitted when the use of deadlines in the contract is toggled
     * @param deadlinesOn The flag returned (true=turned on)
     */
    event ToggleDeadlines(bool deadlinesOn);

    /**
     * @dev Checks if a user has access to a specific function based on ownership of NFTs. If current time > deadline of the function and token id combination
     * @param user The address of the user
     * @param tokenId The token id
     * @param functionName The function name
     * @return bool The boolean (true = has nft)
     */
    function HasAccessNFT(address user, uint256 tokenId, string calldata functionName) external view returns (bool);

    /**
     * @dev Sets the deadline for a specific function and token id (NFT)
     * @param functionName The function name
     * @param deadline The new deadline
     * @param tokenId The token id
     */
    function setDeadline(string calldata functionName, uint256 deadline, uint256 tokenId) external;

    /**
     * @dev Retrieves the deadline for a specific function and NFT.
     * @param hashedFunctionName The hashed function name
     * @param tokenId The token id
     * @return deadline The deadline
     */
    function getDeadline(bytes32 hashedFunctionName, uint256 tokenId) external view returns (uint256);

    /**
     * @dev Toggles the state of deadlines for function access.
     */
    function toggleDeadlines() external;

    /**
     * @dev Sets the fee discount percentage for a specific NFT
     * @param tokenId The token id
     * @param discount The discount in wei
     */
    function setFeeDiscount(uint256 tokenId, uint256 discount) external;

    /**
     * @dev Returns the fee discount percentage for a specific NFT
     * @param tokenId The token id
     * @return uint256 The discount in wei
     */
    function getFeeDiscount(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Sets the URI for the token metadata
     * @param newuri The token id
     */
    function setURI(string memory newuri) external;

    /**
     * @dev Burns a specific amount of tokens owned by an account
     * @param account The account to burn from
     * @param id The token id
     * @param amount The amount to burn
     */
    function adminBurn(address account, uint256 id, uint256 amount) external;

    /**
     * @dev Mints token to user account
     * @param account The account to mint to
     * @param id The token id
     * @param amount The amount to mint
     * @param data The data
     */
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

    /**
     * @dev Batch mints tokens to user account
     * @param to The account to mint to
     * @param ids The token ids
     * @param amounts The amounts to mint
     * @param data The data
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title IAddressesRegistry
 * @author Souq.Finance
 * @notice Defines the interface of the addresses registry.
 * @notice License: https://souq-peripherals.s3.amazonaws.com/LICENSE.md
 */
interface IAddressesRegistry {
    /**
     * @dev Emitted when the connectors router address is updated.
     * @param oldAddress The old address
     * @param newAddress The new address
     */
    event RouterUpdated(address indexed oldAddress, address indexed newAddress);
    /**
     * @dev Emitted when the Access manager address is updated.
     * @param oldAddress The old address
     * @param newAddress The new address
     */
    event AccessManagerUpdated(address indexed oldAddress, address indexed newAddress);
    /**
     * @dev Emitted when the access admin address is updated.
     * @param oldAddress The old address
     * @param newAddress The new address
     */
    event AccessAdminUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the collection connector address is updated.
     * @param oldAddress the old address
     * @param newAddress the new address
     */
    event CollectionConnectorUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when a specific pool factory address is updated.
     * @param id The short id of the pool factory.
     * @param oldAddress The old address
     * @param newAddress The new address
     */

    event PoolFactoryUpdated(bytes32 id, address indexed oldAddress, address indexed newAddress);
    /**
     * @dev Emitted when a specific pool factory address is added.
     * @param id The short id of the pool factory.
     * @param newAddress The new address
     */
    event PoolFactoryAdded(bytes32 id, address indexed newAddress);
    /**
     * @dev Emitted when a specific vault factory address is updated.
     * @param id The short id of the vault factory.
     * @param oldAddress The old address
     * @param newAddress The new address
     */
    event VaultFactoryUpdated(bytes32 id, address indexed oldAddress, address indexed newAddress);
    /**
     * @dev Emitted when a specific vault factory address is added.
     * @param id The short id of the vault factory.
     * @param newAddress The new address
     */
    event VaultFactoryAdded(bytes32 id, address indexed newAddress);
    /**
     * @dev Emitted when a any address is updated.
     * @param id The full id of the address.
     * @param oldAddress The old address
     * @param newAddress The new address
     */
    event AddressUpdated(bytes32 id, address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when a proxy is deployed for an implementation
     * @param id The full id of the address to be saved
     * @param logic The address of the implementation
     * @param proxy The address of the proxy deployed in that id slot
     */
    event ProxyDeployed(bytes32 id, address indexed logic, address indexed proxy);

    /**
     * @dev Emitted when a proxy is deployed for an implementation
     * @param id The full id of the address to be upgraded
     * @param newLogic The address of the new implementation
     * @param proxy The address of the proxy that was upgraded
     */
    event ProxyUpgraded(bytes32 id, address indexed newLogic, address indexed proxy);

    /**
     * @notice Returns the address of the identifier.
     * @param _id The id of the contract
     * @return The Pool proxy address
     */
    function getAddress(bytes32 _id) external view returns (address);

    /**
     * @notice Sets the address of the identifier.
     * @param _id The id of the contract
     * @param _add The address to set
     */
    function setAddress(bytes32 _id, address _add) external;

    /**
     * @notice Returns the address of the connectors router defined as: CONNECTORS_ROUTER
     * @return The address
     */
    function getConnectorsRouter() external view returns (address);

    /**
     * @notice Sets the address of the Connectors router.
     * @param _add The address to set
     */
    function setConnectorsRouter(address _add) external;

    /**
     * @notice Returns the address of access manager defined as: ACCESS_MANAGER
     * @return The address
     */
    function getAccessManager() external view returns (address);

    /**
     * @notice Sets the address of the Access Manager.
     * @param _add The address to set
     */
    function setAccessManager(address _add) external;

    /**
     * @notice Returns the address of access admin defined as: ACCESS_ADMIN
     * @return The address
     */
    function getAccessAdmin() external view returns (address);

    /**
     * @notice Sets the address of the Access Admin.
     * @param _add The address to set
     */
    function setAccessAdmin(address _add) external;

    /**
     * @notice Returns the address of the specific pool factory short id
     * @param _id The pool factory id such as "SVS"
     * @return The address
     */
    function getPoolFactoryAddress(bytes32 _id) external view returns (address);

    /**
     * @notice Returns the full id of pool factory short id
     * @param _id The pool factory id such as "SVS"
     * @return The full id
     */
    function getIdFromPoolFactory(bytes32 _id) external view returns (bytes32);

    /**
     * @notice Sets the address of a specific pool factory using short id.
     * @param _id the pool factory short id
     * @param _add The address to set
     */
    function setPoolFactory(bytes32 _id, address _add) external;

    /**
     * @notice adds a new pool factory with address and short id. The short id will be converted to full id and saved.
     * @param _id the pool factory short id
     * @param _add The address to add
     */
    function addPoolFactory(bytes32 _id, address _add) external;

    /**
     * @notice Returns the address of the specific vault factory short id
     * @param _id The vault id such as "SVS"
     * @return The address
     */
    function getVaultFactoryAddress(bytes32 _id) external view returns (address);

    /**
     * @notice Returns the full id of vault factory id
     * @param _id The vault factory id such as "SVS"
     * @return The full id
     */
    function getIdFromVaultFactory(bytes32 _id) external view returns (bytes32);

    /**
     * @notice Sets the address of a specific vault factory using short id.
     * @param _id the vault factory short id
     * @param _add The address to set
     */
    function setVaultFactory(bytes32 _id, address _add) external;

    /**
     * @notice adds a new vault factory with address and short id. The short id will be converted to full id and saved.
     * @param _id the vault factory short id
     * @param _add The address to add
     */
    function addVaultFactory(bytes32 _id, address _add) external;

    /**
     * @notice Deploys a proxy for an implimentation and initializes then saves in the registry.
     * @param _id the full id to be saved.
     * @param _logic The address of the implementation
     * @param _data The initialization low data
     */
    function updateImplementation(bytes32 _id, address _logic, bytes memory _data) external;

    /**
     * @notice Updates a proxy with a new implementation logic while keeping the store intact.
     * @param _id the full id to be saved.
     * @param _logic The address of the new implementation
     */
    function updateProxy(bytes32 _id, address _logic) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title ICollectionConnector
 * @author Souq.Finance
 * @notice Defines the interface of the Collection Connector
 * @notice License: https://souq-peripherals.s3.amazonaws.com/LICENSE.md
 */

interface ICollectionConnector {
    /**
     * @dev Initialize the connector with the address of the addresses registry
     * @param _addressesRegistry The addresses registry contract
     */
    function initialize(address _addressesRegistry) external;

    /**
     * @dev External function to get the attribute by token id stored locally.
     * @param collection The collection contract address
     * @param _id The token id to get the identifier of
     * @return uint256 the attribute for the token id in the specified collection (can be the rarity or maturity/start of a financial token in other contract versions)
     */
    function getAttributeLocal(address collection, uint256 _id) external view returns (uint256);

    /**
     * @dev External function to get the attribute by id.
     * @param collection The collection contract address
     * @param _id The token id to get the identifier of
     * @return uint256 the attribute for the token id in the specified collection (can be the rarity or maturity/start of a financial token in other contract versions)
     */
    function getAttribute(address collection, uint256 _id) external view returns (uint256);

    /**
     * @dev External function to set the attribute of a token id of a collection address locally
     * @param collection The collection contract address
     * @param _id The id of the token
     * @param _attribute The attribute of that token id
     */
    function setAttribute(address collection, uint256 _id, uint256 _attribute) external;

    /**
     * @dev External function to batch set the rarities of multiple token ids of a collection address
     * @param collection The collection contract address
     * @param _ids The array of token ids
     * @param _attributes The array of rarities to set
     */
    function setAttributeBatch(address collection, uint256[] calldata _ids, uint256[] calldata _attributes) external;

    /**
     * @dev External function to check if the balance of a given id owned by an address
     * @param collection The collection contract address
     * @param _id The id of the token
     * @param _account The address of the tokens owner
     * @return uint256 The balance of a specific token id
     */
    function getBalance(address collection, uint256 _id, address _account) external view returns (uint256);

    /**
     * @dev External function to check if all tokens are approved for the sending contract (like the factory)
     * @param collection The collection contract address
     * @param _account The address of the tokens owner
     * @return bool True If approved All
     */
    function getApproved(address collection, address _account) external view returns (bool);

    /**
     * @dev External function to transfer token id of specific amount from the owner to the requesting address
     * @param collection The collection contract address
     * @param _account The address of the tokens owner
     * @param _id The token id to be transferred
     * @param _amount The amount to be transferred
     */
    function transfer(address collection, address _account, uint256 _id, uint256 _amount) external;

    /**
     * @dev External function to batch transfer tokens from the owner to the requesting address
     * @param collection The collection contract address
     * @param _account The address of the tokens owner
     * @param _ids Array of token ids
     * @param _amounts Array of amounts. Array length should match the token ids array length.
     */
    function transferBatch(address collection, address _account, uint256[] calldata _ids, uint256[] calldata _amounts) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title IConnectorRouter
 * @author Souq.Finance
 * @notice Defines the interface of the connector router
 * @notice License: https://souq-peripherals.s3.amazonaws.com/LICENSE.md
 */
interface IConnectorRouter {
    event YieldDistributorSet(address indexed vaultAddress, address indexed yieldDistributorAddress);
    event YieldDistributorDeleted(address indexed vaultAddress);

    event StakingContractSet(address indexed tokenAddress, address indexed stakingContractAddress);
    event StakingContractDeleted(address indexed stakingContractAddress);

    event SwapContractSet(address indexed tokenAddress, address indexed swapContractAddress);
    event SwapContractDeleted(address indexed swapContractAddress);

    event OracleConnectorSet(address indexed tokenAddress, address indexed oracleConnectorAddress);
    event OracleConnectorDeleted(address indexed oracleConnectorAddress);

    event CollectionConnectorSet(address indexed collection, address indexed collectionConnectorAddress);
    event CollectionConnectorDeleted(address indexed collectionConnectorAddress);

    event StablecoinYieldConnectorSet(address indexed tokenAddress, address indexed stablecoinYieldConnectorAddress);
    event StablecoinYieldConnectorDeleted(address indexed stablecoinYieldConnectorAddress);

    /**
     * @dev Sets the initial owner and timelock address of the contract.
     * @param timelock address
     */
    function initialize(address timelock) external;

    /**
     * @dev Returns the address of the yield distributor contract for a given vault.
     * @param vaultAddress address
     * @return address of the yield distributor contract
     */
    function getYieldDistributor(address vaultAddress) external view returns (address);

    function setYieldDistributor(address vaultAddress, address yieldDistributorAddress) external;

    function deleteYieldDistributor(address vaultAddress) external;

    function getStakingContract(address tokenAddress) external view returns (address);

    function setStakingContract(address tokenAddress, address stakingContractAddress) external;

    function deleteStakingContract(address tokenAddress) external;

    function getSwapContract(address tokenAddress) external view returns (address);

    function setSwapContract(address tokenIn, address tokenOut, address swapContractAddress) external;

    function deleteSwapContract(address tokenAddress) external;

    function getOracleConnectorContract(address tokenAddress) external view returns (address);

    function setOracleConnectorContract(address tokenAddress, address oracleConnectorAddress) external;

    function deleteOracleConnectorContract(address tokenAddress) external;

    function getCollectionConnectorContract(address collection) external view returns (address);

    function setCollectionConnectorContract(address collection, address collectionConnectorAddress) external;

    function deleteCollectionConnectorContract(address collection) external;

    function getStablecoinYieldConnectorContract(address tokenAddress) external view returns (address);

    function setStablecoinYieldConnectorContract(address tokenAddress, address stablecoinYieldConnectorAddress) external;

    function deleteStablecoinYieldConnectorContract(address tokenAddress) external;
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts (token/ERC20/IERC20.sol)

pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Extended {
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
     * @dev Returns the decimals of the token
     */
    function decimals() external view returns(uint8);

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title IExchangeSwapWithOutQuote
 * @author Souq.Finance
 * @notice Interface for ExchangeSwap contracts
 * @notice License: https://souq-peripherals.s3.amazonaws.com/LICENSE.md
 */

interface IExchangeSwapWithOutQuote {
    function swap(address _tokenIn, address _tokenOut, uint256 _amountOut, uint256 _amountInMin) external returns (uint256 amountOut);

    function getQuoteOut(address _tokenIn, address _tokenOut, uint256 _amountOut) external returns (uint256 amountOutMin);

    function getQuoteIn(address _tokenIn, address _tokenOut, uint256 _amountIn) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ILPTokenSVS
 * @author Souq.Finance
 * @notice Defines the interface of the LP token of SVS MMEs
 * @notice License: https://souq-exchange.s3.amazonaws.com/LICENSE.md
 */

interface ILPTokenSVS {

    /**
     * @dev Return the decimals of the token
     * @return uint8 decimals
     */
    function decimals() external view returns (uint8);
    /**
     * @dev Mints LP tokens to the provided address. Can only be called by the pool.
     * @param to the address to mint the tokens to
     * @param amount the amount to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burns LP tokens from the provided address. Can only be called by the pool.
     * @param from the address to burn from
     * @param amount the amount to burn
     */
    function burn(address from, uint256 amount) external;

    /**
     * @dev Unpauses all token transfers. Can only be called by the pool.
     */
    function unpause() external;

    /**
     * @dev Pauses all token transfers. Can only be called by the pool.
     */
    function pause() external;

    /**
     * @dev Check if the LP Token is paused
     * @return bool true=paused
     */
    function checkPaused() external view returns (bool);

    /**
     * @dev Returns the balance of LP tokens for the provided address.
     * @param account The account to check balance of
     * @return uint256 The amount of LP Tokens owned
     */
    function getBalanceOf(address account) external view returns (uint256);

    /**
     * @dev Approves a specific amount of a token for the pool.
     * @param token The token address to approve
     * @param amount The amount of tokens to approve
     */
    function setApproval20(address token, uint256 amount) external;
    
    /**
     * @dev Checks and approves all the ids of the SVS tokens for the pool as operator.
     * @param tokens The tokens array
     */
    function checkApproval1155(address[] memory tokens) external;

    /**
     * @dev Function to rescue and send ERC20 tokens (different than the tokens used by the pool) to a receiver called by the admin
     * @param token The address of the token contract
     * @param amount The amount of tokens
     * @param receiver The address of the receiver
     */
    function rescueTokens(address token, uint256 amount, address receiver) external;

    /**
     * @dev Function to get the the total LP tokens
     * @return uint256 The total number of LP tokens in circulation
     */
    function getTotal() external view returns (uint256);

    /**
     * @dev Redeems mature shares from the VAULT
     * @param collection The address of the collection
     * @param id The Vault tranche id
     * @param amount The amount of shares to redeem
     */
    function redeemShares(address collection, uint256 id, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title IMMEBase
 * @author Souq.Finance
 * @notice Defines the interface of the MME Base.
 * @notice License: https://souq-exchange.s3.amazonaws.com/LICENSE.md
 */
interface IMMEBase {
    /**
     * @dev Emitted when the pool fee changes
     * @param _newFee The new fee
     */
    event FeeChanged(DataTypes.PoolFee _newFee);


    /**
     * @dev Emitted when the Pool Iterative limits are changed
     * @param _limits The new pool data limit
     */
    event PoolIterativeLimitsSet(DataTypes.IterativeLimit _limits);

    /**
     * @dev Emitted when the Pool Liquidity limits are changed
     * @param _limits The new pool data limit
     */
    event PoolLiquidityLimitsSet(DataTypes.LiquidityLimit _limits);

    /**
     * @dev Function to set the pool fee
     * @param _newFee The new fee struct
     */
    function setFee(DataTypes.PoolFee calldata _newFee) external;

    /**
     * @dev Function to set the Pool Iterative limits for the bonding curve
     * @param _newLimits The new limits struct
     */
    function setPoolIterativeLimits(DataTypes.IterativeLimit calldata _newLimits) external;

    /**
     * @dev Function to set the Pool liquidity limits for deposits and withdrawals of liquidity
     * @param _newLimits The new limits struct
     */
    function setPoolLiquidityLimits(DataTypes.LiquidityLimit calldata _newLimits) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title IMMESVS
 * @author Souq.Finance
 * @notice Defines the interface of the MME for SVS pools with single collection.
 * @notice License: https://souq-exchange.s3.amazonaws.com/LICENSE.md
 */

interface IMMESVS {
    /**
     * @dev Emitted when pool is paused
     * @param admin The admin address
     */
    event PoolPaused(address admin);
    /**
     * @dev Emitted when pool is unpaused
     * @param admin The admin address
     */
    event PoolUnpaused(address admin);

    /**
     * @dev initialize the pool with pool data and the symbol/name of the LP Token
     * @param _poolData The pool data structure
     * @param symbol The symbol of the lp token
     * @param name The name of the lp token
     */
    function initialize(DataTypes.PoolSVSData memory _poolData, string memory symbol, string memory name) external;

    /**
     * @dev Function to pause
     */
    function pause() external;

    /**
     * @dev Function to unpause
     */
    function unpause() external;

    /**
     * @dev Function to get the quote for swapping shares in buy or sell direction
     * @param amounts The amounts of shares to buy or sell
     * @param tokenIds The shares token ids
     * @param buy The directional boolean. If buy direction then true
     * @param useFee the boolean determining whether to use Fee in the calculation or not in case we want to calculate the value of the shares for liquidity
     */
    function getQuote(
        uint256[] memory amounts,
        uint256[] memory tokenIds,
        bool buy,
        bool useFee
    ) external view returns (DataTypes.Quotation memory quotation);

    /**
     * @dev Function to swap stablecoins to shares
     * @param amounts The amounts of token ids outputted
     * @param tokenIds The token ids outputted
     * @param maxStable The maximum amount of stablecoin to be spent
     */
    function swapStable(uint256[] memory amounts, uint256[] memory tokenIds, uint256 maxStable) external;

    /**
     * @dev Function to swap shares to stablecoins
     * @param amounts The amounts of token ids outputted
     * @param tokenIds The token ids outputted
     * @param minStable The minimum stablecoin to receive
     */
    function swapShares(uint256[] memory amounts, uint256[] memory tokenIds, uint256 minStable) external;

    /**
     * @dev Function to get the TVL of the pool in stablecoin
     * @return uint256 The TVL
     */
    function getTVL() external view returns (uint256);

    /**
     * @dev Function to get the TVL of a specific sub pool
     * @param id The id of the sub pool
     * @return DataTypes.AMMSubPoolSVSDetails object
     */
    function getPool(uint256 id) external view returns (DataTypes.AMMSubPoolSVSDetails memory);

    /**
     * @dev Function to get the total value of a specific subpool
     * @param subPoolId The id of the sub pool
     * @return uint256 the subpool total value
     */
    function getSubPoolTotal(uint256 subPoolId) external view returns (uint256);

    /**
     * @dev Function to add liquidity using Stable coins
     * @param targetLP The amount of target LPs outputted
     * @param _maxStable The amount of maximum stablecoins to be spent
     **/
    function addLiquidityStable(uint256 targetLP, uint256 _maxStable) external;

    /**
     * @dev Function to remove liquidity by stable coins
     * @param targetLP The amount of LPs to be burned
     * @param minStable The minimum stable tokens to receive
     */
    function removeLiquidityStable(uint256 targetLP, uint256 minStable) external;

    // /**
    //  * @dev Function to process all queued transactions upto limit
    //  * @param limit The number of transactions to process
    //  * @return uint256 The number of transactions processed
    //  */
    // function processWithdrawals(uint256 limit) external returns (uint256);

    /**
     * @dev Function to get the LP token address
     * @return address The address
     */
    function getLPToken() external view returns (address);

    /**
     * @dev Function to get the LP token price
     * @return uint256 The price
     */
    function getLPPrice() external view returns (uint256);

    /**
     * @dev Function to get amount of a specific token id available in the pool
     * @param tokenId The token id
     * @return uint256 The amount
     */
    function getTokenIdAvailable(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Function that returns the subpool ids of the given token ids
     * @param tokenIds The address of the pool
     * @return subPools array of the subpool ids
     */
    function getSubPools(uint256[] memory tokenIds) external view returns (uint256[] memory);

    /**
     * @dev Function that deposits the initial liquidity to specific subpool
     * @param tokenIds The token ids array of the shares to deposit
     * @param amounts The amounts array of the shares to deposit
     * @param stableIn The stablecoins amount to deposit
     * @param subPoolId The sub pool id
     */
    function depositInitial(uint256[] memory tokenIds, uint256[] memory amounts, uint256 stableIn, uint256 subPoolId) external;

    /**
     * @dev Function to add a new sub pool
     * @param f The initial F value of the sub pool
     * @param maturity The initial maturity time of the sub pool
     * @param lockupTime The initial lockup Time of the sub pool
     */
    function addSubPool(uint256 f, uint256 maturity, uint256 lockupTime) external;

    /**
     * @dev Function to move enable or disable specific subpools by ids
     * @param subPoolIds The sub pools ids array
     * @param _newStatus The new status, enabled=true or disabled=false
     */
    function changeSubPoolStatus(uint256[] calldata subPoolIds, bool _newStatus) external;

    /**
     * @dev Function to move reserves between subpools
     * @param moverId The sub pool that will move the funds from
     * @param movedId The id of the sub pool that will move the funds to
     * @param amount The amount to move
     */
    function moveReserve(uint256 moverId, uint256 movedId, uint256 amount) external;

    /**
     * @dev Function to rescue and send ERC20 tokens (different than the tokens used by the pool) to a receiver called by the admin
     * @param token The address of the token contract
     * @param amount The amount of tokens
     * @param receiver The address of the receiver
     */
    // function RescueTokens(address token, uint256 amount, address receiver) external;

    /**
     * @dev Function to withdraw fees by a caller that is either the royalties or protocol address
     * @param to The address to send the funds to
     * @param amount The amount to withdraw
     * @param feeType The type of the fees to withdraw
     */
    function WithdrawFees(address to, uint256 amount, DataTypes.FeeType feeType) external;

    /**
     * @dev Function that updates the max maturity range between subpools and re orders the subpools and/or creates more
     * @param f The f of the new pools to be created
     * @param newMaxMaturityRange The new max maturity Range
     */
    function updateMaxMaturityRange(uint256 f, uint256 newMaxMaturityRange) external;

    /**
     * @dev Function to get all the matured shares
     * @return array of DataTypes.VaultSharesReturn which contains the id and amount
     */
    function getMatureShares() external view returns (DataTypes.VaultSharesReturn[] memory);

    /**
     * @dev Function to move all mature shares to the maturity subpool maxed by maxTrancheCount
     * @param maxTrancheCount The max count of token ids to move
     * @return trancheCount amount of token ids moved (can be different than the max)
     */
    function moveMatureShares(uint256 maxTrancheCount) external returns (uint256 trancheCount);

    /**
     * @dev Function to move mature shares by selected token ids and amounts
     * @param tranches The array of token ids to move
     * @param amounts The array of amounts to move
     * @return trancheCount amount of token ids moved (can be different than the tranches array length)
     */
    function moveMatureSharesList(uint256[] memory tranches, uint256[] memory amounts) external returns (uint256 trancheCount);

    /**
     * @dev Function to clean all mature subpools and change the starting index
     */
    function cleanMatureSubPools() external;

    /**
     * @dev Function to redeem all the mature shares from the maturity subpool maxed by maxTrancheCount
     * @param maxTrancheCount The max count of token ids to redeem
     * @return trancheCount amount of token ids redeemed (can be different than the max)
     */
    function redeemMatureShares(uint256 maxTrancheCount) external returns (uint256 trancheCount);


    /**
     * @dev Function to distribute the reserve in subpool 0 (maturity) to all active subpools by weight
     */
    function redistrubteLiquidity() external;

    /**
     * @dev Function to set the Pool Data
     * @param _newPoolData the new pooldata struct
     */
    function setPoolData(DataTypes.PoolSVSData calldata _newPoolData) external;

    // /**
    //  * @dev Function to change the lockup times of the subpools to fit the vault
    //  * @param lastLockupTimes The last lockup times for comparison
    //  */
    // function changeLockupTimes(uint256[] memory lastLockupTimes) external;

    /**
     * @dev Function to return the count of subpools created
     * @return count The count
     */
    function getSubPoolsCount() external view returns (uint256 count);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title IPriceOracleConnector
 * @author Souq.Finance
 * @notice Defines the interface of the Price Oracle Connector
 * @notice License: https://souq-peripherals.s3.amazonaws.com/LICENSE.md
 */
interface IPriceOracleConnector {
    /**
     * @dev Emitted when oracle contract is set
     * @param asset The asset address
     * @param oracleContract The oracle contract address
     */
    event OracleContractSet(address indexed asset, address indexed oracleContract);
    /**
     * @dev Emitted when the oracle admin changes
     * @param newOracleAdmin The new oracle admin address
     */
    event NewOracleAdmin(address indexed newOracleAdmin);

    /**
     * @dev Function to get the oracle address of an asset
     * @param asset The asset address
     * @return address the oracle contract
     */
    function getTokenOracleContract(address asset) external view returns (address);

    /**
     * @dev Function to set the oracle address of an asset
     * @param asset The asset address
     * @param oracleContract the oracle contract
     * @param base the bsase string such as USD or ETH
     */
    function setTokenOracleContract(address asset, address oracleContract, string calldata base) external;

    /**
     * @dev Function to get the latest price of an asset
     * @param asset The asset address
     * @return uint256 the latest price
     */
    function getTokenPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title ISVS
 * @author Souq.Finance
 * @notice Interface for SVS contract
 * @notice License: https://souq-etf.s3.amazonaws.com/LICENSE.md
 */

interface ISVS {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    function mint(address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

    function burn(address _account, uint256 _id, uint256 _amount) external;

    function currentTranche() external view returns (uint256);

    function totalSupplyPerTranche(uint256 _tranche) external view returns (uint256);

    function setTokenTrancheTimestamps(uint256 _tokenId, uint256 _timestamps) external;

    function tokenTranche(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {ICollectionConnector} from "./ICollectionConnector.sol";

/**
 * @title ISVSCollectionConnector
 * @author Souq.Finance
 * @notice Defines the interface of the SVS collection connectors inheriting the ICollectionConnector
 * @notice License: https://souq-peripherals.s3.amazonaws.com/LICENSE.md
 */

interface ISVSCollectionConnector is ICollectionConnector {
    /**
     * @dev Returns the VIT and composition of the VAULT specified
     * @param collection The address of the collection
     */
    function getVITs(address collection) external view returns (address[] memory VITs, uint256[] memory amounts);

    /**
     * @dev Function that gets the lockup times array from the vault data
     * @param collection The address of the collection
     * @return lockupTimes The lockup times array
     */
    function getLockupTimes(address collection) external view returns (uint256[] memory lockupTimes);

    /**
     * @dev Function that gets the lockup time of a specific token id (tranche)
     * @param collection The address of the collection
     * @param tokenId The Vault tranche id
     * @return uint256 The lockup time
     */
    function getLockupTime(address collection, uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {VaultDataTypes} from "../libraries/VaultDataTypes.sol";

/**
 * @title IVault1155
 * @author Souq.Finance
 * @notice Interface for Vault1155 contract
 * @notice License: https://souq-etf.s3.amazonaws.com/LICENSE.md
 */

interface IVault1155 {

    function initialize(address _factory, address _feeReceiver) external;

    /**
     * @dev Pauses the contract, preventing certain functions from executing.
     */

    function pause() external;

    /**
     * @dev Unpauses the contract, allowing functions to execute.
     */

    function unpause() external;

    /**
     * @dev Calculates the total quote for a specified number of shares and a fee.
     * @param _numShares The number of shares.
     * @param fee The fee amount.
     * @return An array of total quotes.
     */

    function getTotalQuote(uint256 _numShares, uint256 fee) external returns (uint256[] memory);

    /**
     * @dev Calculates the total quote with a specified VIT address and number of shares.
     * @param _VITAddress The VIT address.
     * @param _numShares The number of shares.
     * @return An array of total quotes.
     */

    function getTotalQuoteWithVIT(address _VITAddress, uint256 _numShares) external returns (uint256[] memory);

    /**
     * @dev Mints Vault tokens for the specified parameters.
     * @param _numShares The number of shares to mint.
     * @param _stableAmount The amount of stable tokens to use for minting.
     * @param _amountPerSwap An array of swap amounts.
     * @param _lockup The lockup period.
     */

    function mintVaultToken(
        uint256 _numShares,
        uint256 _stableAmount,
        uint256[] calldata _amountPerSwap,
        VaultDataTypes.LockupPeriod _lockup
    ) external;

    /**
     * @dev Mints Vault tokens for the specified parameters and a specific VIT address and amount.
     * @param _numShares The number of shares to mint.
     * @param _stableAmount The amount of stable tokens to use for minting.
     * @param _amountPerSwap An array of swap amounts.
     * @param _lockup The lockup period.
     * @param _mintVITAddress The VIT address for minting.
     * @param _mintVITAmount The amount of VIT to mint.
     */

    function mintVaultTokenWithVIT(
        uint256 _numShares,
        uint256 _stableAmount,
        uint256[] calldata _amountPerSwap,
        VaultDataTypes.LockupPeriod _lockup,
        address _mintVITAddress,
        uint256 _mintVITAmount
    ) external;

    /**
     * @dev Sets the reweighter address.
     * @param _reweighter The new reweighter address.
     */

    function setReweighter(address _reweighter) external;

    /**
     * @dev Changes the composition of VITs and their corresponding weights.
     * @param _newVITs An array of new VIT addresses.
     * @param _newAmounts An array of new VIT amounts.
     */

    function changeVITComposition(address[] memory _newVITs, uint256[] memory _newAmounts) external;

    /**
     * @dev Initiates a reweight operation for the specified VITs and amounts.
     * @param _VITs An array of VIT addresses to reweight.
     * @param _amounts An array of corresponding amounts for reweighting.
     */

    function initiateReweight(address[] memory _VITs, uint256[] memory _amounts) external;

    /**
     * @dev Redeems underlying assets for the specified number of shares and tranche.
     * @param _numShares The number of shares to redeem.
     * @param _tranche The tranche to redeem from.
     */

    function redeemUnderlying(uint256 _numShares, uint256 _tranche) external;

    /**
     * @dev Redeems underlying assets for multiple share quantities and tranches.
     * @param _numShares An array of share quantities to redeem.
     * @param _tranche An array of tranches to redeem from.
     */

    function redeemUnderlyingGroup(uint256[] memory _numShares, uint256[] memory _tranche) external;

    /**
     * @dev Retrieves the lockup start time for a specified tranche.
     * @param _tranche The tranche for which to retrieve the lockup start time.
     * @return The lockup start time in Unix timestamp.
     */

    function getLockupStart(uint256 _tranche) external view returns (uint256);

    /**
     * @dev Retrieves the lockup end time for a specified tranche.
     * @param _tranche The tranche for which to retrieve the lockup end time.
     * @return The lockup end time in Unix timestamp.
     */

    function getLockupEnd(uint256 _tranche) external view returns (uint256);

    /**
     * @dev Retrieves the lockup time of a specified tranche.
     * @param _tranche The tranche for which to retrieve the lockup time.
     */

    function getLockupTime(uint256 _tranche) external view returns (uint256);

    /**
     * @dev Retrieves the composition of VITs and their corresponding amounts.
     */

    function getVITComposition() external view returns (address[] memory VITs, uint256[] memory amounts);

    /**
     * @dev Retrieves the total underlying assets across all VITs.
     */

    function getTotalUnderlying() external view returns (uint256[] memory totalUnderlying);

    /**
     * @dev Retrieves the address of the SVS token contract.
     */

    function getSVS() external view returns (address);


    function vaultData() external view returns (VaultDataTypes.VaultData memory);

    /**
     * @dev Retrieves the total underlying assets for a specified tranche.
     * @param tranche The tranche for which to retrieve the total underlying assets.
     */

    function getTotalUnderlyingByTranche(uint256 tranche) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title library for Data structures
 * @author Souq.Finance
 * @notice Defines the structures used by the contracts of the Souq protocol
 * @notice License: https://souq-exchange.s3.amazonaws.com/LICENSE.md
 */
library DataTypes {
    struct PoolSVSData {
        bool useAccessToken;
        address accessToken;
        address poolLPToken;
        address stable;
        address[] tokens;
        address stableYieldAddress;
        Coefficients coefficients;
        PoolFee fee;
        LiquidityLimit liquidityLimit;
        IterativeLimit iterativeLimit;
        uint256 firstActivePool;
        uint256 maxMaturityRange;
    }

    struct AMMSubPoolSVSDetails {
        uint256 reserve;
        uint256 totalShares;
        uint256 start;
        uint256 lockupTime;
        uint256 F;
        bool status;
    }
    struct SubPoolCheckerVars {
        uint256 subPoolIndex;
        bool foundSubPool;
        uint256 lockupStart;
        uint256 lockupTime;
        bool matured;
        uint256 lpPrice;
        uint256 v;
        uint256 total;
        uint256 tvl;
    }
    struct Coefficients {
        uint256 coefficientA;
        uint256 coefficientB;
        uint256 coefficientC;
    }
    struct AMMSubPoolSVS {
        uint256 reserve;
        uint256 totalShares;
        bool status;
        uint256 F;
        uint256 lockupTime;
        uint256 start;
        uint256[] tokenIds;
        //tokenid -> amount + lockup
        //if lockup is 0, means the share was moved to another subpool or redeemed
        mapping(uint256 => AMMShareSVS) shares;
    }
    struct AMMShareSVS {
        uint256 amount;
        uint256 start;
        uint256 lockupTime;
    }
    struct VaultSharesReturn {
        uint256 tranche;
        uint256 amount;
    }

    struct AMMShare1155 {
        uint256 tokenId;
        uint256 amount;
    }

    struct Shares1155Params {
        uint256[] amounts;
        uint256[] tokenIds;
    }

    struct ParamGroup {
        uint256 amount;
        uint256 tokenId;
        uint256 subPoolId;
    }

    struct SubPoolGroup {
        uint256 id;
        uint256 counter;
        uint256 total;
        AMMShare1155[] shares;
        SharesCalculationReturn sharesCal;
    }
    struct SharePrice {
        uint256 id;
        uint256 value;
        FeeReturn fees;
    }
    struct MoveSharesVars {
        uint256 i;
        uint256 poolId;
    }
    struct Quotation {
        uint256 total;
        FeeReturn fees;
        SharePrice[] shares;
    }
    struct QuoteParams {
        bool buy;
        bool useFee;
    }
    struct LocalQuoteVars {
        uint256 i;
        uint256 y;
        uint256 total;
        uint256 poolId;
        uint256 counter;
        uint256 counterShares;
        FeeReturn fees;
        SubPoolGroup currentSubPool;
        AMMShare1155 currentShare;
        SubPoolGroup[] subPoolGroups;
    }
    struct LocalGroupVars {
        uint256 i;
        uint256 index;
        uint256 subPoolId;
        bool matured;
        SharesCalculationReturn cal;
        ParamGroup[] paramGroups;
    }
    struct Withdraw1155Data {
        address to;
        uint256 unlockTimestamp;
        uint256 amount;
        AMMShare1155[] shares;
    }

    struct Queued1155Withdrawals {
        mapping(uint => Withdraw1155Data) withdrawals;
        //Head is for reading and next is for saving
        uint256 headId;
        uint256 nextId;
    }

    struct AMMSubPool1155 {
        uint256 reserve;
        uint256 totalShares;
        bool status;
        uint256 V;
        uint256 F;
        //tokenid -> amount
        mapping(uint256 => uint256) shares;
    }

    struct AMMSubPool1155Details {
        uint256 reserve;
        uint256 totalShares;
        uint256 V;
        uint256 F;
        bool status;
    }

    struct FactoryFeeConfig {
        uint256 lpBuyFee;
        uint256 lpSellFee;
        uint256 minLpFee;
        uint256 maxLpBuyFee;
        uint256 maxLpSellFee;
        uint256 protocolSellRatio;
        uint256 protocolBuyRatio;
        uint256 minProtocolRatio;
        uint256 maxProtocolRatio;
        uint256 royaltiesBuyFee;
        uint256 royaltiesSellFee;
        uint256 maxRoyaltiesFee;
    }
    struct PoolFee {
        uint256 lpBuyFee;
        uint256 lpSellFee;
        uint256 royaltiesBuyFee;
        uint256 royaltiesSellFee;
        uint256 protocolBuyRatio;
        uint256 protocolSellRatio;
        uint256 royaltiesBalance;
        uint256 protocolBalance;
        address royaltiesAddress;
        address protocolFeeAddress;
    }

    //cooldown between deposit and withdraw in seconds
    //percentage and multiplier are in wad and wadPercentage
    struct LiquidityLimit {
        uint256 poolTvlLimit;
        uint256 cooldown;
        uint256 maxDepositPercentage;
        uint256 maxWithdrawPercentage;
        uint256 feeMultiplier;
        uint256 lastLpPrice;
        uint8 addLiqMode;
        uint8 removeLiqMode;
        bool onlyAdminProvisioning;
    }
    struct IterativeLimit {
        uint256 minimumF;
        uint16 maxBulkStepSize;
        uint16 iterations;
    }

    struct PoolData {
        bool useAccessToken;
        address accessToken;
        address poolLPToken;
        address stable;
        address[] tokens;
        address stableYieldAddress;
        uint256 coefficientA;
        uint256 coefficientB;
        uint256 coefficientC;
        PoolFee fee;
        LiquidityLimit liquidityLimit;
        IterativeLimit iterativeLimit;
    }

    struct FeeReturn {
        uint256 totalFee;
        uint256 swapFee;
        uint256 lpFee;
        uint256 royalties;
        uint256 protocolFee;
    }
    struct SharesCalculationVars {
        uint16 i;
        uint256 V;
        uint256 PV;
        uint256 PV_0;
        uint256 swapPV;
        uint256 shares;
        uint256 stable;
        uint256 value;
        uint256 den;
        uint256 newCash;
        uint256 newShares;
        uint256 steps;
        uint256 stepIndex;
        uint256 stepAmount;
        FeeReturn fees;
    }

    struct SharesCalculationReturn {
        uint256 PV;
        uint256 swapPV;
        uint256 amount;
        uint256 value;
        uint256 F;
        uint256 lastLpPrice;
        FeeReturn fees;
    }

    struct LiquidityDetailsVars {
        uint8 i;
        uint256 total;
        uint256 stablePrice;
        address[] VITs;
        uint256[] amounts;
    }

    struct LiqLocalVars {
        uint256 TVL;
        uint256 TVLActive;
        uint256 v;
        uint256 LPPrice;
        uint256 LPAmount;
        uint256 stable;
        uint256 stableTotal;
        uint256 stableRemaining;
        uint256 weighted;
        uint256 poolId;
        uint256 maxLPPerShares;
        uint256 remainingLP;
        uint256 i;
        uint256 y;
        uint256 counter;
        AMMShare1155 currentShare;
        SubPoolGroup currentSubPool;
        SubPoolGroup[] subPoolGroups;
    }
    struct SwapLocalVars {
        uint256 stable;
        uint256 stableOut;
        uint256 remaining;
        uint256 poolId;
        uint256 i;
        uint256 y;
        uint256 counter;
        AMMShare1155 currentShare;
        SubPoolGroup currentSubPool;
        SubPoolGroup[] subPoolGroups;
        FeeReturn fees;
    }
    enum FeeType {
        royalties,
        protocol
    }
    enum OperationType {
        buyShares,
        sellShares
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title library for Errors mapping
 * @author Souq.Finance
 * @notice Defines the output of error messages reverted by the contracts of the Souq protocol
 * @notice License: https://souq-exchange.s3.amazonaws.com/LICENSE.md
 */
library Errors {
    string public constant ADDRESS_IS_ZERO = "ADDRESS_IS_ZERO";
    string public constant VALUE_CANNOT_BE_ZERO = "VALUE_CANNOT_BE_ZERO";
    string public constant NOT_ENOUGH_USER_BALANCE = "NOT_ENOUGH_USER_BALANCE";
    string public constant NOT_ENOUGH_APPROVED = "NOT_ENOUGH_APPROVED";
    string public constant INVALID_AMOUNT = "INVALID_AMOUNT";
    string public constant AMM_PAUSED = "AMM_PAUSED";
    string public constant VAULT_PAUSED = "VAULT_PAUSED";
    string public constant FLASHLOAN_DISABLED = "FLASHLOAN_DISABLED";
    string public constant ADDRESSES_REGISTRY_NOT_SET = "ADDRESSES_REGISTRY_NOT_SET";
    string public constant UPGRADEABILITY_DISABLED = "UPGRADEABILITY_DISABLED";
    string public constant CALLER_NOT_UPGRADER = "CALLER_NOT_UPGRADER";
    string public constant CALLER_NOT_POOL_ADMIN = "CALLER_NOT_POOL_ADMIN";
    string public constant CALLER_NOT_ACCESS_ADMIN = "CALLER_NOT_ACCESS_ADMIN";
    string public constant CALLER_NOT_POOL_ADMIN_OR_OPERATIONS = "CALLER_NOT_POOL_ADMIN_OR_OPERATIONS";
    string public constant CALLER_NOT_ORACLE_ADMIN = "CALLER_NOT_ORACLE_ADMIN";
    string public constant CALLER_NOT_TIMELOCK = "CALLER_NOT_TIMELOCK";
    string public constant CALLER_NOT_TIMELOCK_ADMIN = "CALLER_NOT_TIMELOCK_ADMIN";
    string public constant CALLER_NOT_CONNECTOR_ADMIN = "CALLER_NOT_CONNECTOR_ADMIN";
    string public constant ADDRESS_IS_PROXY = "ADDRESS_IS_PROXY";
    string public constant ARRAY_NOT_SAME_LENGTH = "ARRAY_NOT_SAME_LENGTH";
    string public constant NO_SUB_POOL_AVAILABLE = "NO_SUB_POOL_AVAILABLE";
    string public constant LIQUIDITY_MODE_RESTRICTED = "LIQUIDITY_MODE_RESTRICTED";
    string public constant TVL_LIMIT_REACHED = "TVL_LIMIT_REACHED";
    string public constant CALLER_MUST_BE_POOL = "CALLER_MUST_BE_POOL";
    string public constant CANNOT_RESCUE_POOL_TOKEN = "CANNOT_RESCUE_POOL_TOKEN";
    string public constant CALLER_MUST_BE_STABLEYIELD_ADMIN = "CALLER_MUST_BE_STABLEYIELD_ADMIN";
    string public constant CALLER_MUST_BE_STABLEYIELD_LENDER = "CALLER_MUST_BE_STABLEYIELD_LENDER";
    string public constant FUNCTION_REQUIRES_ACCESS_NFT = "FUNCTION_REQUIRES_ACCESS_NFT";
    string public constant FEE_OUT_OF_BOUNDS = "FEE_OUT_OF_BOUNDS";
    string public constant ONLY_ADMIN_CAN_ADD_LIQUIDITY = "ONLY_ADMIN_CAN_ADD_LIQUIDITY";
    string public constant NOT_ENOUGH_POOL_RESERVE = "NOT_ENOUGH_POOL_RESERVE";
    string public constant NOT_ENOUGH_SUBPOOL_RESERVE = "NOT_ENOUGH_SUBPOOL_RESERVE";
    string public constant NOT_ENOUGH_SUBPOOL_SHARES = "NOT_ENOUGH_SUBPOOL_SHARES";
    string public constant SUBPOOL_DISABLED = "SUBPOOL_DISABLED";
    string public constant ADDRESS_NOT_CONNECTOR_ADMIN = "ADDRESS_NOT_CONNECTOR_ADMIN";
    string public constant WITHDRAW_LIMIT_REACHED = "WITHDRAW_LIMIT_REACHED";
    string public constant DEPOSIT_LIMIT_REACHED = "DEPOSIT_LIMIT_REACHED";
    string public constant SHARES_VALUE_EXCEEDS_TARGET = "SHARES_VALUE_EXCEEDS_TARGET";
    string public constant SHARES_VALUE_BELOW_TARGET = "SHARES_VALUE_BELOW_TARGET";
    string public constant LP_VALUE_BELOW_TARGET = "LP_VALUE_BELOW_TARGET";
    string public constant SHARES_TARGET_EXCEEDS_RESERVE = "SHARES_TARGET_EXCEEDS_RESERVE";
    string public constant SWAPPING_SHARES_TEMPORARY_DISABLED_DUE_TO_LOW_CONDITIONS =
        "SWAPPING_SHARES_TEMPORARY_DISABLED_DUE_TO_LOW_CONDITIONS";
    string public constant ADDING_SHARES_TEMPORARY_DISABLED_DUE_TO_LOW_CONDITIONS =
        "ADDING_SHARES_TEMPORARY_DISABLED_DUE_TO_LOW_CONDITIONS";
    string public constant UPGRADE_DISABLED = "UPGRADE_DISABLED";
    string public constant USER_CANNOT_BE_CONTRACT = "USER_CANNOT_BE_CONTRACT";
    string public constant DEADLINE_NOT_FOUND = "DEADLINE_NOT_FOUND";
    string public constant FLASHLOAN_PROTECTION_ENABLED = "FLASHLOAN_PROTECTION_ENABLED";
    string public constant INVALID_POOL_ADDRESS = "INVALID_POOL_ADDRESS";
    string public constant INVALID_SUBPOOL_ID = "INVALID_SUBPOOL_ID";
    string public constant INVALID_YIELD_DISTRIBUTOR_ADDRESS = "INVALID_YIELD_DISTRIBUTOR_ADDRESS";
    string public constant YIELD_DISTRIBUTOR_NOT_FOUND = "YIELD_DISTRIBUTOR_NOT_FOUND";
    string public constant INVALID_TOKEN_ID = "INVALID_TOKEN_ID";
    string public constant INVALID_VAULT_ADDRESS = "INVALID_VAULT_ADDRESS";
    string public constant VAULT_NOT_FOUND = "VAULT_NOT_FOUND";
    string public constant INVALID_TOKEN_ADDRESS = "INVALID_TOKEN_ADDRESS";
    string public constant INVALID_STAKING_CONTRACT = "INVALID_STAKING_CONTRACT";
    string public constant STAKING_CONTRACT_NOT_FOUND = "STAKING_CONTRACT_NOT_FOUND";
    string public constant INVALID_SWAP_CONTRACT = "INVALID_SWAP_CONTRACT";
    string public constant SWAP_CONTRACT_NOT_FOUND = "SWAP_CONTRACT_NOT_FOUND";
    string public constant INVALID_ORACLE_CONNECTOR = "INVALID_ORACLE_CONNECTOR";
    string public constant ORACLE_CONNECTOR_NOT_FOUND = "ORACLE_CONNECTOR_NOT_FOUND";
    string public constant INVALID_COLLECTION_CONTRACT = "INVALID_COLLECTION_CONTRACT";
    string public constant COLLECTION_CONTRACT_NOT_FOUND = "COLLECTION_CONTRACT_NOT_FOUND";
    string public constant INVALID_STABLECOIN_YIELD_CONNECTOR = "INVALID_STABLECOIN_YIELD_CONNECTOR";
    string public constant STABLECOIN_YIELD_CONNECTOR_NOT_FOUND = "STABLECOIN_YIELD_CONNECTOR_NOT_FOUND";
    string public constant TIMELOCK_USES_ACCESS_CONTROL = "TIMELOCK_USES_ACCESS_CONTROL";
    string public constant TIMELOCK_ETA_MUST_SATISFY_DELAY = "TIMELOCK_ETA_MUST_SATISFY_DELAY";
    string public constant TIMELOCK_TRANSACTION_NOT_READY = "TIMELOCK_TRANSACTION_NOT_READY";
    string public constant TIMELOCK_TRANSACTION_ALREADY_EXECUTED = "TIMELOCK_TRANSACTION_ALREADY_EXECUTED";
    string public constant TIMELOCK_TRANSACTION_ALREADY_QUEUED = "TIMELOCK_TRANSACTION_ALREADY_QUEUED";
    string public constant APPROVAL_FAILED = "APPROVAL_FAILED";
    string public constant DISCOUNT_EXCEEDS_100 = "DISCOUNT_EXCEEDS_100";
    string public constant SUBPOOL_NOT_FOUND="SUBPOOL_NOT_FOUND";
    string public constant VAULT_SHARE_MATURED="VAULT_SHARE_MATURED";
    string public constant SHARES_VALUE_CANNOT_BE_ZERO="SHARES_VALUE_CANNOT_BE_ZERO";
    string public constant TRANSACTION_REJECTED_DUE_TO_CONDITIONS="TRANSACTION_REJECTED_DUE_TO_CONDITIONS";
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {PoolSVSLogic} from "./PoolSVSLogic.sol";
import {MathHelpers} from "../libraries/MathHelpers.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Errors} from "../libraries/Errors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ILPTokenSVS} from "../interfaces/ILPTokenSVS.sol";
// import "hardhat/console.sol";

/**
 * @title library for Liquidity logic of SVS pools with single collection
 * @author Souq.Finance
 * @notice Defines the logic functions for the AMM and MME that operate SVS shares
 * @notice License: https://souq-exchange.s3.amazonaws.com/LICENSE.md
 */

library LiquiditySVSLogic {
    using SafeERC20 for IERC20;
    using Math for uint256;
    using PoolSVSLogic for DataTypes.AMMSubPoolSVS[];

    /**
     * @dev Emitted when the user initiates deposit of stablecoins and shares into a subpool
     * @param user The user address
     * @param subPoolId The subPool id
     * @param stableIn The amount of stablecoin inputted
     * @param params The token ids[] and amounts[] structure
     * @param totalShares The new total shares count
     * @param F The new F
     */
    event DepositInitiated(
        address user,
        uint256 subPoolId,
        uint256 stableIn,
        DataTypes.Shares1155Params params,
        uint256 totalShares,
        uint256 F
    );

    /**
     * @dev Emitted when adding liquidity by a liqduity provider using stablecoins
     * @param stableIn The amount of stablecoin inputted
     * @param lpAmount The amount of LP token outputted
     * @param from The address of the msg sender
     * @notice it's here to avoid the stack too deep issue for now
     */
    event AddedLiqStable(uint256 stableIn, uint256 lpAmount, address from);

    /**
     * @dev Emitted when removing liquidity by a liqduity provider
     * @param stableOut The amount of stablecoin outputted
     * @param lpAmount The amount of LP token inputted
     * @param from The address of the msg sender
     * @param queued If transaction is queued = true
     */
    event RemovedLiqStable(uint256 stableOut, uint256 lpAmount, address from, bool queued);

    /**
     * @dev Emitted when swap of stable coins occures
     * @param stableIn The amount of stablecoin supplied
     * @param fees The fees collected
     * @param user The user address
     * @param subPoolGroups The subpool groups including calculations and shares array
     */
    event SwappedStable(uint256 stableIn, DataTypes.FeeReturn fees, address user, DataTypes.SubPoolGroup[] subPoolGroups);

    /**
     * @dev Emitted when swap of shares occures
     * @param stableOut The amount of stablecoin outputted
     * @param fees The fees collected
     * @param user The user address
     * @param subPoolGroups The subpool groups including calculations and shares array
     */
    event SwappedShares(uint256 stableOut, DataTypes.FeeReturn fees, address user, DataTypes.SubPoolGroup[] subPoolGroups);

    /**
     * @dev Emitted when withdrawals are processed after the cooldown period
     * @param user The user that processed the withdrawals
     * @param transactionsCount The number of transactions processed
     */
    event WithdrawalsProcessed(address user, uint256 transactionsCount);

    /**
     * @dev Emitted when reserve is moved between subpools
     * @param admin The admin that executed the function
     * @param moverId the id of the subpool to move funds from
     * @param movedId the id of the subpool to move funds to
     * @param amount the amount of funds to move
     */
    event MovedReserve(address admin, uint256 moverId, uint256 movedId, uint256 amount);

    /**
     * @dev Emitted when the accumulated fee balances are withdrawn by the royalties and protocol wallet addresses
     * @param user The sender of the transaction
     * @param to the address to send the funds to
     * @param amount the amount being withdrawn
     * @param feeType: string - the type of fee being withdrawan (royalties/protocol)
     */
    event WithdrawnFees(address user, address to, uint256 amount, string feeType);

    /**
     * @dev Function to distribute liquidity to all subpools according to their weight
     * @notice updates the last lp price via updatePriceIterative
     * @notice the last subpool gets the remainder, if any
     * @param amount The account to deduct the stables from
     * @param tvl The TVL of the pool
     * @param addressesRegistry the addresses registry contract
     * @param poolData The liquidity pool data structure
     * @param subPools The subpools array
     */
    function distributeLiquidityToAll(
        uint256 amount,
        uint256 tvl,
        uint256 v,
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) public {
        require(subPools.length > 0, Errors.NO_SUB_POOL_AVAILABLE);
        uint256 remaining = amount;
        uint256 weighted = 0;
        //Iterate through the subpools and add liquidity in a weighted manner and the remainder goes to the last subpool
        for (uint256 i = 0; i < subPools.length; ++i) {
            if (subPools[i].status) {
                if (i == subPools.length - 1) {
                    subPools[i].reserve += remaining;
                } else {
                    if (tvl == 0) {
                        subPools[i].reserve += amount / subPools.length;
                        remaining -= amount / subPools.length;
                    } else {
                        weighted = (amount * PoolSVSLogic.calculateTotal(subPools, v, i)) / tvl;
                        // console.log("weighted: ", weighted);
                        remaining -= weighted;
                        subPools[i].reserve += weighted;
                    }
                }
                PoolSVSLogic.updatePriceIterative(addressesRegistry, poolData, subPools, i);
            }
        }
    }

    /**
     * @dev Function to distribute the reserve in subpool 0 (maturity) to all active subpools
     * @notice updates the last lp price via updatePriceIterative
     * @notice the last subpool gets the remainder, if any
     * @param addressesRegistry the addresses registry contract
     * @param poolData The liquidity pool data structure
     * @param subPools The subpools array
     */
    function redistrubteLiquidity(
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) external {
        if (subPools[0].reserve > 0) {
            (uint256 v, , uint256 tvlActive, ) = PoolSVSLogic.calculateLiquidityDetailsIterative(addressesRegistry, poolData, subPools);
            // console.log("tvlActive: ", tvlActive);
            if (tvlActive > 0) {
                distributeLiquidityToAll(subPools[0].reserve, tvlActive, v, addressesRegistry, poolData, subPools);
                subPools[0].reserve = 0;
            }
        }
    }

    /**
     * @dev Function to move reserves between subpools
     * @param moverId The sub pool that will move the funds from
     * @param movedId The id of the sub pool that will move the funds to
     * @param amount The amount to move
     * @param addressesRegistry The addresses Registry contract address
     * @param poolData The pool data
     * @param subPools The subpools array
     */
    function moveReserve(
        uint256 moverId,
        uint256 movedId,
        uint256 amount,
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) external {
        require(subPools[moverId].reserve >= amount, Errors.NOT_ENOUGH_SUBPOOL_RESERVE);
        require(subPools.length > moverId && subPools.length > movedId, Errors.INVALID_SUBPOOL_ID);
        subPools[moverId].reserve -= amount;
        PoolSVSLogic.updatePriceIterative(addressesRegistry, poolData, subPools, moverId);
        subPools[movedId].reserve += amount;
        PoolSVSLogic.updatePriceIterative(addressesRegistry, poolData, subPools, movedId);
        emit MovedReserve(msg.sender, moverId, movedId, amount);
    }

    /**
     * @dev Function to deposit initial liquidity to a subpool
     * @notice This will work if there is an already created subpool
     * @param user The user to get the LPs
     * @param subPoolId The subpool id
     * @param stableIn The stablecoins amount to deposit
     * @param params the token ids and amounts to deposit
     * @param addressesRegistry the addresses registry contract
     * @param poolData The liquidity pool data structure
     * @param subPools The subpools array
     */
    function depositInitial(
        address user,
        uint256 subPoolId,
        uint256 stableIn,
        DataTypes.Shares1155Params memory params,
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) external {
        DataTypes.SubPoolCheckerVars memory checkerVars;
        require(params.tokenIds.length == params.amounts.length, Errors.ARRAY_NOT_SAME_LENGTH);
        (checkerVars.v, checkerVars.total, , checkerVars.lpPrice) = PoolSVSLogic.calculateLiquidityDetailsIterative(
            addressesRegistry,
            poolData,
            subPools
        );
        for (uint256 i = 0; i < params.tokenIds.length; ++i) {
            (
                checkerVars.subPoolIndex,
                checkerVars.foundSubPool,
                checkerVars.lockupStart,
                checkerVars.lockupTime,
                checkerVars.matured
            ) = PoolSVSLogic.checkSubPool(params.tokenIds[i], addressesRegistry, poolData, subPools);
            require(checkerVars.subPoolIndex == subPoolId && checkerVars.foundSubPool, "NOT_SAME_SUBPOOL_DISTRIBUTION");
            subPools[subPoolId].shares[params.tokenIds[i]].amount += params.amounts[i];
            subPools[subPoolId].totalShares += params.amounts[i];
            PoolSVSLogic.findAndSaveTokenId(params.tokenIds[i], subPoolId, checkerVars.lockupStart, checkerVars.lockupTime, subPools);
            checkerVars.total += params.amounts[i];
        }
        subPools[subPoolId].reserve += stableIn;
        PoolSVSLogic.updatePriceIterative(addressesRegistry, poolData, subPools, subPoolId);
        emit DepositInitiated(user, subPoolId, stableIn, params, subPools[subPoolId].totalShares, subPools[subPoolId].F);
        if (params.tokenIds.length > 0 && checkerVars.total > 0) {
            IERC1155(PoolSVSLogic.getCollectionToken(poolData)).safeBatchTransferFrom(
                user,
                poolData.poolLPToken,
                params.tokenIds,
                params.amounts,
                ""
            );
        }
        (, checkerVars.tvl, , ) = PoolSVSLogic.calculateLiquidityDetailsIterative(addressesRegistry, poolData, subPools);
        ILPTokenSVS(poolData.poolLPToken).mint(user, MathHelpers.convertToWad(checkerVars.tvl - checkerVars.total) / checkerVars.lpPrice);
        IERC20(poolData.stable).safeTransferFrom(user, poolData.poolLPToken, stableIn);
    }

    /**
     * @dev Function to remove liquidity by stable coins
     * @param user The account to deduct the stables from
     * @param targetLP The amount of LPs required
     * @param maxStable the maximum stablecoins to transfer
     * @param addressesRegistry the addresses registry contract
     * @param poolData The liquidity pool data structure
     * @param subPools The subpools array
     */
    function addLiquidityStable(
        address user,
        uint256 targetLP,
        uint256 maxStable,
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) external returns (uint256, uint256) {
        require(user != address(0), Errors.ADDRESS_IS_ZERO);
        require(IERC20(poolData.stable).allowance(user, address(this)) >= maxStable, Errors.NOT_ENOUGH_APPROVED);
        require(IERC20(poolData.stable).balanceOf(user) >= maxStable, Errors.NOT_ENOUGH_USER_BALANCE);
        DataTypes.LiqLocalVars memory vars;
        (vars.v, vars.TVL, vars.TVLActive, vars.LPPrice) = PoolSVSLogic.calculateLiquidityDetailsIterative(
            addressesRegistry,
            poolData,
            subPools
        );
        require(poolData.liquidityLimit.poolTvlLimit >= vars.TVL + maxStable, Errors.TVL_LIMIT_REACHED);
        //if TVL > 0 and deposit > TVL * limitPercentage, then revert where deposit is (requiredLP + totalLPOwned) * price
        //for v1.1
        // require(
        //     vars.TVL == 0 ||
        //         ((MathHelpers.convertFromWad((targetLP + ILPTokenSVS(poolData.poolLPToken).getBalanceOf(user)) * vars.LPPrice)) <=
        //             MathHelpers.convertFromWadPercentage(vars.TVL * poolData.liquidityLimit.maxDepositPercentage)),
        //     Errors.DEPOSIT_LIMIT_REACHED
        // );
        if ((MathHelpers.convertFromWad(targetLP * vars.LPPrice)) > maxStable) {
            vars.LPAmount = MathHelpers.convertToWad(maxStable) / vars.LPPrice;
            vars.stable = maxStable;
        } else {
            vars.LPAmount = targetLP;
            vars.stable = MathHelpers.convertFromWad(targetLP * vars.LPPrice);
        }
        distributeLiquidityToAll(vars.stable, vars.TVLActive, vars.v, addressesRegistry, poolData, subPools);

        emit AddedLiqStable(vars.stable, vars.LPAmount, user);
        IERC20(poolData.stable).safeTransferFrom(user, poolData.poolLPToken, vars.stable);
        ILPTokenSVS(poolData.poolLPToken).mint(user, vars.LPAmount);
        return (vars.stable, vars.LPAmount);
    }

    /**
     * @dev Function to remove liquidity by stable coins
     * @param user The account to remove LP from
     * @param yieldReserve The current reserve deposited in yield generators
     * @param targetLP The amount of LPs to be burned
     * @param minStable The minimum stable tokens to receive
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param poolData The liquidity pool data structure
     * @param subPools The subpools array
     * @param queuedWithdrawals The queued withdrawals
     */
    function removeLiquidityStable(
        address user,
        uint256 yieldReserve,
        uint256 targetLP,
        uint256 minStable,
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools,
        DataTypes.Queued1155Withdrawals storage queuedWithdrawals
    ) external returns (uint256, uint256) {
        require(user != address(0), Errors.ADDRESS_IS_ZERO);
        require(ILPTokenSVS(poolData.poolLPToken).getBalanceOf(user) >= targetLP, Errors.NOT_ENOUGH_USER_BALANCE);
        require(subPools.length > 0, Errors.NO_SUB_POOL_AVAILABLE);
        DataTypes.LiqLocalVars memory vars;
        (vars.v, vars.TVL, vars.TVLActive, vars.LPPrice) = PoolSVSLogic.calculateLiquidityDetailsIterative(
            addressesRegistry,
            poolData,
            subPools
        );
        //Check how much stablecoins remaining in the pool excluding yield investment
        vars.stableRemaining = IERC20(poolData.stable).balanceOf(poolData.poolLPToken) - yieldReserve;

        //Calculate maximum LP Tokens to remove
        vars.remainingLP = targetLP.min(MathHelpers.convertToWad(vars.stableRemaining) / vars.LPPrice);
        vars.LPAmount = MathHelpers.convertToWad(subPools[0].reserve) / vars.LPPrice;
        if (vars.LPAmount >= vars.remainingLP) {
            vars.remainingLP = 0;
            vars.stable = MathHelpers.convertFromWad(vars.remainingLP * vars.LPPrice);
            subPools[0].reserve -= vars.stable;
            vars.stableTotal += vars.stable;
        } else {
            vars.remainingLP -= vars.LPAmount;
            vars.stableTotal += subPools[0].reserve;
            subPools[0].reserve = 0;
        }
        if (vars.remainingLP > 0) {
            //Repeat due to change in reserves
            (vars.v, vars.TVL, vars.TVLActive, vars.LPPrice) = PoolSVSLogic.calculateLiquidityDetailsIterative(
                addressesRegistry,
                poolData,
                subPools
            );
            //Start at subpool 1
            for (vars.i = 1; vars.i < subPools.length; ++vars.i) {
                if (subPools[vars.i].status) {
                    vars.weighted = vars.remainingLP.min(
                        (targetLP * PoolSVSLogic.calculateTotal(subPools, vars.v, vars.i)) / vars.TVLActive
                    );
                    vars.stable = MathHelpers.convertFromWad(vars.weighted * vars.LPPrice);
                    vars.stable = subPools[vars.i].reserve.min(vars.stable);
                    subPools[vars.i].reserve -= vars.stable;
                    PoolSVSLogic.updatePriceIterative(addressesRegistry, poolData, subPools, vars.i);
                    vars.stableTotal += vars.stable;
                    vars.remainingLP -= vars.weighted;
                }
            }
        }
        //re-use this variable to get the final LP amount
        vars.LPAmount = targetLP - vars.remainingLP - yieldReserve;
        require(vars.stableTotal >= minStable, Errors.LP_VALUE_BELOW_TARGET);
        emit RemovedLiqStable(vars.stableTotal, vars.LPAmount, user, poolData.liquidityLimit.cooldown > 0 ? true : false);
        //If there is a cooldown, then store the stable in an array in the user data to be released later
        if (poolData.liquidityLimit.cooldown == 0) {
            ILPTokenSVS(poolData.poolLPToken).setApproval20(poolData.stable, vars.stableTotal);
            IERC20(poolData.stable).safeTransferFrom(poolData.poolLPToken, user, vars.stableTotal);
        } else {
            DataTypes.Withdraw1155Data storage current = queuedWithdrawals.withdrawals[queuedWithdrawals.nextId];
            current.to = user;
            //Using block.timestamp is safer than block number
            //See: https://ethereum.stackexchange.com/questions/11060/what-is-block-timestamp/11072#11072
            current.unlockTimestamp = block.timestamp + poolData.liquidityLimit.cooldown;
            current.amount = vars.stableTotal;
            ++queuedWithdrawals.nextId;
        }
        ILPTokenSVS(poolData.poolLPToken).burn(user, vars.LPAmount);
        return (vars.stableTotal, vars.LPAmount);
    }

    // /**
    //  * @dev Function to process queued withdraw transactions upto limit and return number of transactions processed
    //  * @notice make it update F if needed for future
    //  * @param limit The number of transactions to process in queue
    //  * @param poolData The liquidity pool data structure
    //  * @param queuedWithdrawals The queued withdrawals
    //  * @return transactions number of transactions processed. 0 = no transactions in queue
    //  */
    // function processWithdrawals(
    //     uint256 limit,
    //     DataTypes.PoolSVSData storage poolData,
    //     DataTypes.Queued1155Withdrawals storage queuedWithdrawals
    // ) external returns (uint256 transactions) {
    //     for (uint256 i; i < limit; ++i) {
    //         DataTypes.Withdraw1155Data storage current = queuedWithdrawals.withdrawals[queuedWithdrawals.headId];
    //         //Using block.timestamp is safer than block number
    //         //See: https://ethereum.stackexchange.com/questions/11060/what-is-block-timestamp/11072#11072
    //         if (current.unlockTimestamp < block.timestamp) break;
    //         if (current.amount > 0) {
    //             ILPTokenSVS(poolData.poolLPToken).setApproval20(poolData.stable, current.amount);
    //             IERC20(poolData.stable).safeTransferFrom(poolData.poolLPToken, current.to, current.amount);
    //         }
    //         for (uint256 j = 0; j < current.shares.length; ++j) {
    //             IERC1155(PoolSVSLogic.getCollectionToken(poolData)).safeTransferFrom(
    //                 poolData.poolLPToken,
    //                 current.to,
    //                 current.shares[j].tokenId,
    //                 current.shares[j].amount,
    //                 ""
    //             );
    //         }
    //         ++transactions;
    //         ++queuedWithdrawals.headId;
    //     }
    //     if (queuedWithdrawals.nextId == queuedWithdrawals.headId) {
    //         queuedWithdrawals.nextId = 0;
    //         queuedWithdrawals.headId = 0;
    //     }
    //     emit WithdrawalsProcessed(msg.sender, transactions);
    // }

    /**
     * @dev Function that returns an array of structures that represent that subpools found that has an array of shares in those subpools and the counter represents the length of the outer and inner arrays
     * @param  params The shares arrays (token ids, amounts) to group
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param poolData The liquidity pool data
     * @param subPools the subpools array of the liquidity pool
     * @return subPoolGroups array of DataTypes.SubPoolGroup output
     * @return counter The counter of array elements used
     */
    function groupBySubpoolDynamic(
        DataTypes.Shares1155Params memory params,
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) public view returns (DataTypes.SubPoolGroup[] memory subPoolGroups, uint256 counter) {
        subPoolGroups = new DataTypes.SubPoolGroup[](subPools.length);
        counter = 0;
        DataTypes.LocalGroupVars memory vars;
        //Get the token ids
        if (params.tokenIds.length == 1) {
            counter = 1;
            subPoolGroups = new DataTypes.SubPoolGroup[](1);
            DataTypes.SubPoolCheckerVars memory checkerVars;
            (checkerVars.subPoolIndex, , , , checkerVars.matured) = PoolSVSLogic.checkSubPool(
                params.tokenIds[0],
                addressesRegistry,
                poolData,
                subPools
            );
            require(!checkerVars.matured, Errors.VAULT_SHARE_MATURED);
            subPoolGroups[0] = DataTypes.SubPoolGroup(
                checkerVars.subPoolIndex,
                1,
                params.amounts[0],
                new DataTypes.AMMShare1155[](1),
                vars.cal
            );
            subPoolGroups[0].shares[0] = DataTypes.AMMShare1155(params.tokenIds[0], params.amounts[0]);
        } else {
            //First we create an array of same length of the params and fill it with the token ids, subpool ids and amounts
            vars.paramGroups = new DataTypes.ParamGroup[](params.tokenIds.length);
            for (vars.i; vars.i < params.tokenIds.length; ++vars.i) {
                DataTypes.SubPoolCheckerVars memory checkerVars;
                (checkerVars.subPoolIndex, , , , checkerVars.matured) = PoolSVSLogic.checkSubPool(
                    params.tokenIds[vars.i],
                    addressesRegistry,
                    poolData,
                    subPools
                );
                require(!checkerVars.matured, Errors.VAULT_SHARE_MATURED);
                vars.paramGroups[vars.i].subPoolId = checkerVars.subPoolIndex;
                vars.paramGroups[vars.i].amount = params.amounts[vars.i];
                vars.paramGroups[vars.i].tokenId = params.tokenIds[vars.i];
            }
            //Then we sort the new array using the insertion method
            for (vars.i = 1; vars.i < vars.paramGroups.length; ++vars.i) {
                for (uint j = 0; j < vars.i; ++j)
                    if (vars.paramGroups[vars.i].subPoolId < vars.paramGroups[j].subPoolId) {
                        DataTypes.ParamGroup memory x = vars.paramGroups[vars.i];
                        vars.paramGroups[vars.i] = vars.paramGroups[j];
                        vars.paramGroups[j] = x;
                    }
            }
            //The we iterate last time through the array and construct the subpool group
            for (vars.i = 0; vars.i < vars.paramGroups.length; ++vars.i) {
                if (vars.i == 0 || vars.paramGroups[vars.i].subPoolId != vars.paramGroups[vars.i - 1].subPoolId) {
                    subPoolGroups[counter] = DataTypes.SubPoolGroup(
                        vars.paramGroups[vars.i].subPoolId,
                        0,
                        0,
                        new DataTypes.AMMShare1155[](vars.paramGroups.length),
                        vars.cal
                    );
                    ++counter;
                }
                vars.index = counter - 1;
                subPoolGroups[vars.index].shares[subPoolGroups[vars.index].counter] = DataTypes.AMMShare1155(
                    vars.paramGroups[vars.i].tokenId,
                    vars.paramGroups[vars.i].amount
                );
                subPoolGroups[vars.index].total += vars.paramGroups[vars.i].amount;
                ++subPoolGroups[vars.index].counter;
            }
        }
    }

    /** @dev Get full quotation
     * @param quoteParams the quote params containing the buy/sell flag and the use fee flag
     * @param params The shares arrays (token ids, amounts)
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param poolData The liquidity pool data
     * @param subPools the subpools array of the liquidity pool
     */
    function getQuote(
        DataTypes.QuoteParams calldata quoteParams,
        DataTypes.Shares1155Params calldata params,
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) external view returns (DataTypes.Quotation memory quotation) {
        require(params.tokenIds.length == params.amounts.length, Errors.ARRAY_NOT_SAME_LENGTH);
        DataTypes.LocalQuoteVars memory vars;
        quotation.shares = new DataTypes.SharePrice[](params.tokenIds.length);
        //Get the grouped token ids by subpool
        (vars.subPoolGroups, vars.counter) = groupBySubpoolDynamic(params, addressesRegistry, poolData, subPools);
        for (vars.i; vars.i < vars.counter; ++vars.i) {
            vars.currentSubPool = vars.subPoolGroups[vars.i];
            vars.poolId = vars.currentSubPool.id;
            require(subPools[vars.poolId].status, Errors.SUBPOOL_DISABLED);
            //Calculate the value of the shares from its subpool
            vars.currentSubPool.sharesCal = PoolSVSLogic.CalculateShares(
                quoteParams.buy ? DataTypes.OperationType.buyShares : DataTypes.OperationType.sellShares,
                vars.poolId,
                vars.currentSubPool.total,
                quoteParams.useFee,
                addressesRegistry,
                poolData,
                subPools
            );
            for (vars.y = 0; vars.y < vars.currentSubPool.counter; ++vars.y) {
                vars.currentShare = vars.currentSubPool.shares[vars.y];
                require(
                    subPools[vars.poolId].shares[vars.currentShare.tokenId].amount >= vars.currentShare.amount || !quoteParams.buy,
                    Errors.NOT_ENOUGH_SUBPOOL_SHARES
                );
                quotation.shares[vars.counterShares].value = vars.currentShare.amount * vars.currentSubPool.sharesCal.swapPV;
                quotation.shares[vars.counterShares].id = vars.currentShare.tokenId;
                quotation.shares[vars.counterShares].fees = PoolSVSLogic.multiplyFees(
                    vars.subPoolGroups[vars.i].sharesCal.fees,
                    vars.currentShare.amount,
                    vars.currentSubPool.total
                );
                ++vars.counterShares;
            }
            quotation.fees = PoolSVSLogic.addFees(quotation.fees, vars.subPoolGroups[vars.i].sharesCal.fees);
            require(
                subPools[vars.poolId].reserve >= vars.subPoolGroups[vars.i].sharesCal.value || quoteParams.buy,
                Errors.NOT_ENOUGH_SUBPOOL_RESERVE
            );
            quotation.total += vars.subPoolGroups[vars.i].sharesCal.value;
        }
    }

    /** @dev Experimental Function to the swap shares to stablecoins using grouping by subpools
     * @notice subPoolGroupsPointer should be cleared by making it "1" after each iteration of the grouping
     * @param user The user address to transfer the shares from
     * @param  minStable The minimum stablecoins to receive
     * @param  yieldReserve The current reserve in yield contracts
     * @param  params The shares arrays to deduct (token ids, amounts)
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param poolData The pool data including fee configuration
     * @param subPools the subpools array of the liquidity pool
     */
    function swapShares(
        address user,
        uint256 minStable,
        uint256 yieldReserve,
        DataTypes.Shares1155Params memory params,
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) external {
        require(params.tokenIds.length == params.amounts.length, Errors.ARRAY_NOT_SAME_LENGTH);

        DataTypes.SwapLocalVars memory vars;
        DataTypes.SubPoolCheckerVars memory checkerVars;
        (vars.subPoolGroups, vars.counter) = groupBySubpoolDynamic(params, addressesRegistry, poolData, subPools);
        //Check how much stablecoins remaining in the pool excluding yield investment
        require(IERC20(poolData.stable).balanceOf(poolData.poolLPToken) - yieldReserve >= minStable, Errors.NOT_ENOUGH_POOL_RESERVE);
        //Get the grouped token ids by subpool
        for (vars.i; vars.i < vars.counter; ++vars.i) {
            vars.currentSubPool = vars.subPoolGroups[vars.i];
            vars.poolId = vars.currentSubPool.id;
            require(
                subPools[vars.poolId].F >= poolData.iterativeLimit.minimumF,
                Errors.SWAPPING_SHARES_TEMPORARY_DISABLED_DUE_TO_LOW_CONDITIONS
            );
            require(subPools[vars.poolId].status, Errors.SUBPOOL_DISABLED);
            //Calculate the value of the shares inside this group
            vars.currentSubPool.sharesCal = PoolSVSLogic.CalculateShares(
                DataTypes.OperationType.sellShares,
                vars.poolId,
                vars.currentSubPool.total,
                true,
                addressesRegistry,
                poolData,
                subPools
            );
            vars.stable =
                vars.currentSubPool.sharesCal.value -
                vars.currentSubPool.sharesCal.fees.royalties -
                vars.currentSubPool.sharesCal.fees.protocolFee;
            //Skip this subpool if there isn't enough
            //The pricing depends on all the shares together, otherwise we need to break them and re-iterate (future feature)
            require(vars.currentSubPool.sharesCal.value <= subPools[vars.poolId].reserve, Errors.NOT_ENOUGH_SUBPOOL_RESERVE);
            require(vars.currentSubPool.sharesCal.value > 0, Errors.SHARES_VALUE_CANNOT_BE_ZERO);
            vars.stableOut += vars.stable;
            //add the total fees for emitting the event
            vars.fees = PoolSVSLogic.addFees(vars.fees, vars.currentSubPool.sharesCal.fees);
            //Update the reserve of stable and shares and F
            subPools[vars.poolId].reserve -= (vars.currentSubPool.sharesCal.value);
            subPools[vars.poolId].totalShares += vars.currentSubPool.total;
            subPools[vars.poolId].F = vars.currentSubPool.sharesCal.F;

            //Recalculate for buying to modify dynamic fees
            vars.currentSubPool.sharesCal = PoolSVSLogic.CalculateShares(
                DataTypes.OperationType.buyShares,
                vars.poolId,
                vars.currentSubPool.total,
                true,
                addressesRegistry,
                poolData,
                subPools
            );
            require(
                vars.stable <
                    vars.currentSubPool.sharesCal.value +
                        vars.currentSubPool.sharesCal.fees.royalties +
                        vars.currentSubPool.sharesCal.fees.protocolFee,
                Errors.TRANSACTION_REJECTED_DUE_TO_CONDITIONS
            );

            //Iterate through the shares inside the Group
            for (vars.y = 0; vars.y < vars.currentSubPool.counter; ++vars.y) {
                vars.currentShare = vars.currentSubPool.shares[vars.y];
                (, , checkerVars.lockupStart, checkerVars.lockupTime, ) = PoolSVSLogic.checkSubPool(
                    vars.currentShare.tokenId,
                    addressesRegistry,
                    poolData,
                    subPools
                );

                PoolSVSLogic.findAndSaveTokenId(
                    vars.currentShare.tokenId,
                    vars.poolId,
                    checkerVars.lockupStart,
                    checkerVars.lockupTime,
                    subPools
                );
                subPools[vars.poolId].shares[vars.currentShare.tokenId].amount += vars.currentShare.amount;
                //Transfer the tokens
                //We cant transfer batch outside the loop since the array of token ids and amounts have a counter after grouping
                //To generate proper token ids and amounts arrays for transfer batch, the groupBySubpoolDynamic will be redesigned and cost more gas
                //Even if grouped and the transfer is outside the current for loop, there is still another for loop due to economy of scale approach
                IERC1155(PoolSVSLogic.getCollectionToken(poolData)).safeTransferFrom(
                    user,
                    poolData.poolLPToken,
                    vars.currentShare.tokenId,
                    vars.currentShare.amount,
                    ""
                );
            }
            PoolSVSLogic.updatePriceIterative(addressesRegistry, poolData, subPools, vars.poolId);
        }
        require(vars.stableOut >= minStable, Errors.SHARES_VALUE_BELOW_TARGET);
        if (vars.stableOut > 0) {
            emit SwappedShares(vars.stableOut, vars.fees, user, vars.subPoolGroups);
            //Add to the balances of the protocol wallet and royalties address
            poolData.fee.protocolBalance += vars.fees.protocolFee;
            poolData.fee.royaltiesBalance += vars.fees.royalties;
            //Transfer the total stable to the user
            ILPTokenSVS(poolData.poolLPToken).setApproval20(poolData.stable, vars.stableOut);
            IERC20(poolData.stable).safeTransferFrom(poolData.poolLPToken, user, vars.stableOut);
        }
    }

    /** @dev Experimental Function to the swap stablecoins to shares using grouping by subpools
     * @param user The user address to deduct stablecoins
     * @param maxStable the maximum stablecoins to deduct
     * @param  params The shares arrays (token ids, amounts)
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param poolData The pool data including fee configuration
     * @param subPools the subpools array of the liquidity pool
     */
    function swapStable(
        address user,
        uint256 maxStable,
        DataTypes.Shares1155Params memory params,
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) external {
        require(params.tokenIds.length == params.amounts.length, Errors.ARRAY_NOT_SAME_LENGTH);
        require(IERC20(poolData.stable).allowance(user, address(this)) >= maxStable, Errors.NOT_ENOUGH_APPROVED);
        require(IERC20(poolData.stable).balanceOf(user) >= maxStable, Errors.NOT_ENOUGH_USER_BALANCE);
        DataTypes.SwapLocalVars memory vars;
        vars.remaining = maxStable;
        //Get the grouped token ids by subpool
        (vars.subPoolGroups, vars.counter) = groupBySubpoolDynamic(params, addressesRegistry, poolData, subPools);
        //iterate the subpool groups
        for (vars.i; vars.i < vars.counter; ++vars.i) {
            vars.currentSubPool = vars.subPoolGroups[vars.i];
            vars.poolId = vars.currentSubPool.id;
            require(subPools[vars.poolId].status, Errors.SUBPOOL_DISABLED);
            //Calculate the value of the shares inside this group
            //This requires that the total shares in the subpool >= amount requested or it reverts
            vars.currentSubPool.sharesCal = PoolSVSLogic.CalculateShares(
                DataTypes.OperationType.buyShares,
                vars.poolId,
                vars.currentSubPool.total,
                true,
                addressesRegistry,
                poolData,
                subPools
            );
            //If the value of the shares is higher than the remaining stablecoins to consume, continue the for.
            // Otherwise, we would need to recalculate using the remaining stable
            // It is better to assume that the user approved more than the shares value
            //if (vars.currentSubPool.sharesCal.value + vars.currentSubPool.sharesCal.fees.totalFee > vars.remaining) continue;
            require(
                vars.currentSubPool.sharesCal.value +
                    vars.currentSubPool.sharesCal.fees.royalties +
                    vars.currentSubPool.sharesCal.fees.protocolFee <=
                    vars.remaining,
                Errors.SHARES_VALUE_EXCEEDS_TARGET
            );
            require(vars.currentSubPool.sharesCal.value > 0, Errors.SHARES_VALUE_CANNOT_BE_ZERO);
            vars.remaining -= (vars.currentSubPool.sharesCal.value +
                vars.currentSubPool.sharesCal.fees.royalties +
                vars.currentSubPool.sharesCal.fees.protocolFee);
            //increment the total fees for emitting the event
            vars.fees = PoolSVSLogic.addFees(vars.fees, vars.currentSubPool.sharesCal.fees);
            //Update the reserve of stable and shares and F
            subPools[vars.poolId].reserve += vars.currentSubPool.sharesCal.value;
            subPools[vars.poolId].totalShares -= vars.currentSubPool.total;
            subPools[vars.poolId].F = vars.currentSubPool.sharesCal.F;

            //Recalculate for selling to modify dynamic fees
            vars.currentSubPool.sharesCal = PoolSVSLogic.CalculateShares(
                DataTypes.OperationType.sellShares,
                vars.poolId,
                vars.currentSubPool.total,
                true,
                addressesRegistry,
                poolData,
                subPools
            );
            require(
                vars.currentSubPool.sharesCal.value -
                    vars.currentSubPool.sharesCal.fees.royalties -
                    vars.currentSubPool.sharesCal.fees.protocolFee <
                    vars.stable,
                Errors.TRANSACTION_REJECTED_DUE_TO_CONDITIONS
            );

            //Iterate through all the shares to update their new amounts in the subpool
            for (vars.y = 0; vars.y < vars.currentSubPool.counter; ++vars.y) {
                vars.currentShare = vars.currentSubPool.shares[vars.y];
                require(
                    subPools[vars.poolId].shares[vars.currentShare.tokenId].amount >= vars.currentShare.amount,
                    Errors.NOT_ENOUGH_SUBPOOL_SHARES
                );
                subPools[vars.poolId].shares[vars.currentShare.tokenId].amount -= vars.currentShare.amount;
                if (subPools[vars.poolId].shares[vars.currentShare.tokenId].amount == 0) {
                    subPools[vars.poolId].shares[vars.currentShare.tokenId].start = 0;
                }
                //Transfer the tokens
                //We cant transfer batch outside the loop since the array of token ids and amounts have a counter after grouping
                //To generate proper token ids and amounts arrays for transfer batch, the groupBySubpoolDynamic will be redesigned and cost more gas
                //Even if grouped and the transfer is outside the current for loop, there is still another for loop due to economy of scale approach
                ILPTokenSVS(poolData.poolLPToken).checkApproval1155(poolData.tokens);
                IERC1155(PoolSVSLogic.getCollectionToken(poolData)).safeTransferFrom(
                    poolData.poolLPToken,
                    user,
                    vars.currentShare.tokenId,
                    vars.currentShare.amount,
                    ""
                );
            }
            PoolSVSLogic.updatePriceIterative(addressesRegistry, poolData, subPools, vars.poolId);
        }
        //Add to the balances of the protocol wallet and royalties address
        poolData.fee.protocolBalance += vars.fees.protocolFee;
        poolData.fee.royaltiesBalance += vars.fees.royalties;
        emit SwappedStable(maxStable - vars.remaining, vars.fees, user, vars.subPoolGroups);
        //Transfer the total stable from the user
        IERC20(poolData.stable).safeTransferFrom(user, poolData.poolLPToken, maxStable - vars.remaining);
    }

    /**
     * @dev Function to withdraw fees by a caller that is either the royalties or protocol address
     * @param user The caller
     * @param to The address to send the funds to
     * @param amount The amount to withdraw
     * @param feeType The type of the fees to withdraw
     * @param poolData The pool data
     */
    function withdrawFees(
        address user,
        address to,
        uint256 amount,
        DataTypes.FeeType feeType,
        DataTypes.PoolSVSData storage poolData
    ) external {
        //If withdrawing royalties and the msg.sender matches the royalties address
        if (feeType == DataTypes.FeeType.royalties && user == poolData.fee.royaltiesAddress && amount <= poolData.fee.royaltiesBalance) {
            poolData.fee.royaltiesBalance -= amount;
            emit WithdrawnFees(user, to, amount, "royalties");
            ILPTokenSVS(poolData.poolLPToken).setApproval20(poolData.stable, amount);
            IERC20(poolData.stable).safeTransferFrom(poolData.poolLPToken, to, amount);
        }
        //If withdrawing protocol fees and the msg.sender matches the protocol address
        if (feeType == DataTypes.FeeType.protocol && user == poolData.fee.protocolFeeAddress && amount <= poolData.fee.protocolBalance) {
            poolData.fee.protocolBalance -= amount;
            emit WithdrawnFees(user, to, amount, "protocol");
            ILPTokenSVS(poolData.poolLPToken).setApproval20(poolData.stable, amount);
            IERC20(poolData.stable).safeTransferFrom(poolData.poolLPToken, to, amount);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title library for the math helper functions
 * @author Souq.Finance
 * @notice Defines the math helper functions common throughout the protocol
 * @notice License: https://souq-exchange.s3.amazonaws.com/LICENSE.md
 */
library MathHelpers {
    using SafeMath for uint256;

    function convertToWad(uint256 x) internal pure returns (uint256 z) {
        z = x.mul(10 ** 18);
    }

    function convertFromWad(uint256 x) internal pure returns (uint256 z) {
        z = x.div(10 ** 18);
    }

    function convertFromWadToDecimal(uint256 x, uint256 decimals) internal pure returns (uint256 z)
    {
        z = x.div(10 ** (18 - decimals));
    }

    function convertFromBiggerToSmaller(uint256 x, uint256 from, uint256 to) internal pure returns (uint256 z)
    {
        z = x.div(10 ** (from - to));
    }

    function convertToWadPercentage(uint256 x) internal pure returns (uint256 z) {
        z = x.mul(10 ** 20);
    }

    function convertFromWadPercentage(uint256 x) internal pure returns (uint256 z) {
        z = x.div(10 ** 20);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Errors} from "../libraries/Errors.sol";
import {PoolSVSLogic} from "./PoolSVSLogic.sol";
import {ILPTokenSVS} from "../interfaces/ILPTokenSVS.sol";
import {IConnectorRouter} from "../interfaces/IConnectorRouter.sol";
import {IExchangeSwapWithOutQuote} from "../interfaces/IExchangeSwapWithOutQuote.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {IERC20Extended} from "../interfaces/IERC20Extended.sol";
import {ISVS} from "../interfaces/ISVS.sol";
import {IVault1155} from "../interfaces/IVault1155.sol";
// import "hardhat/console.sol";

/**
 * @title library for maturity logic functions for the SVS Pools with single collection
 * @author Souq.Finance
 * @notice License: https://souq-exchange.s3.amazonaws.com/LICENSE.md
 */

library MaturitySVSLogic {
    using Math for uint256;
    uint256 public constant MAX_ACTIVE_VAULT_SHARES = 10000;
    /**
     * @dev Emitted when the max maturity range between subpools is updated and re ordered the subpools
     * @param admin The admin that executed the function
     * @param newMaxMaturityRange The new max maturity Range
     */
    event UpdatedMaxMaturityRange(address admin, uint256 newMaxMaturityRange);
    /**
     * @dev Emitted when all mature shares are moved to the maturity subpool maxed by maxTrancheCount
     * @param admin The admin that executed the function
     * @param trancheCount amount of token ids moved (can be different than the max)
     */
    event MovedMatureShares(address admin, uint256 trancheCount);
    /**
     * @dev Emitted when mature shares are moved to the maturity subpool specified by arrays of token ids and amounts
     * @param admin The admin that executed the function
     * @param trancheCount amount of token ids moved (can be different than the max)
     */
    event MovedMatureSharesList(address admin, uint256 trancheCount);
    /**
     * @dev Emitted when the mature subpools are emptied and possible change made to the starting index
     * @param admin The admin that executed the function
     * @param cleaned amount of subpools cleaned
     */
    event CleanedMatureSubPools(address admin, uint256 cleaned);
    /**
     * @dev Emitted when all mature shares are redeemed from the maturity subpool maxed by maxTrancheCount
     * @param admin The admin that executed the function
     * @param trancheCount amount of token ids redeemed (can be different than the max)
     */
    event RedeemedMatureShares(address admin, uint256 trancheCount);

    /**
     * @dev Function that updates the max maturity range between subpools and re orders the subpools
     * @param f The f of the created subpools if any
     * @param newMaxMaturityRange The new max maturity Range
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param poolData The pool data
     * @param subPools the subpools array
     */
    function updateMaxMaturityRange(
        uint256 f,
        uint256 newMaxMaturityRange,
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) external {
        require(newMaxMaturityRange > 0, Errors.VALUE_CANNOT_BE_ZERO);
        uint256[] memory lockupTimes = PoolSVSLogic.getCollectionConnector(addressesRegistry, poolData).getLockupTimes(poolData.tokens[0]);
        uint256 currentStart = subPools[poolData.firstActivePool].start;
        //First run to modify all the starts in the new sequence
        for (uint256 i = poolData.firstActivePool + 1; i < subPools.length; i++) {
            DataTypes.AMMSubPoolSVS storage currentSubPool = subPools[i];
            //It iterates till it finds the group of subpools that have a different start
            if (currentSubPool.start != currentStart) {
                for (uint256 j; j < lockupTimes.length; ++j) {
                    if (i + j < subPools.length) {
                        subPools[i + j].start = currentStart + newMaxMaturityRange;
                    }
                }
                currentStart += newMaxMaturityRange;
            }
        }
        poolData.maxMaturityRange = newMaxMaturityRange;
        //Second run is to re-arrange the token ids in their proper subpool
        for (uint256 i = poolData.firstActivePool; i < subPools.length; i++) {
            DataTypes.AMMSubPoolSVS storage currentSubPool = subPools[i];
            for (uint256 j; j < subPools[i].tokenIds.length; ++j) {
                DataTypes.AMMShareSVS storage currentShare = currentSubPool.shares[subPools[i].tokenIds[j]];
                if (currentShare.start > currentSubPool.start + newMaxMaturityRange || currentShare.start < currentSubPool.start) {
                    bool found;
                    uint256 newSubPoolId;
                    (newSubPoolId, found, , , ) = PoolSVSLogic.checkSubPool(subPools[i].tokenIds[j], addressesRegistry, poolData, subPools);
                    if (!found) {
                        PoolSVSLogic.addSubPoolsAuto(f, currentShare.start, addressesRegistry, poolData, subPools);
                    }
                    (newSubPoolId, found, , , ) = PoolSVSLogic.checkSubPool(subPools[i].tokenIds[j], addressesRegistry, poolData, subPools);
                    subPools[newSubPoolId].totalShares += currentShare.amount;
                    currentSubPool.totalShares -= currentShare.amount;
                    subPools[newSubPoolId].shares[subPools[i].tokenIds[j]].amount = currentShare.amount;
                    subPools[newSubPoolId].shares[subPools[i].tokenIds[j]].start = currentShare.start;
                    PoolSVSLogic.findAndSaveTokenId(
                        subPools[i].tokenIds[j],
                        newSubPoolId,
                        currentShare.start,
                        currentShare.lockupTime,
                        subPools
                    );
                    currentShare.start = 0;
                    currentShare.amount = 0;
                }
            }
            PoolSVSLogic.updatePriceIterative(addressesRegistry, poolData, subPools, i);
        }
        emit UpdatedMaxMaturityRange(msg.sender, newMaxMaturityRange);
    }

    /**
     * @dev Function to get all the matured shares
     * @param poolData The pool data
     * @param subPools The subpools array
     * @return sharesReturn array of DataTypes.VaultSharesReturn which contains the token id and amount
     */
    function getMatureShares(
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) external view returns (DataTypes.VaultSharesReturn[] memory sharesReturn) {
        DataTypes.VaultSharesReturn[] memory vars = new DataTypes.VaultSharesReturn[](MAX_ACTIVE_VAULT_SHARES);
        uint256 counter;
        for (uint256 i = poolData.firstActivePool; i < subPools.length; ++i) {
            for (uint256 j; j < subPools[i].tokenIds.length; ++j) {
                if (
                    subPools[i].shares[subPools[i].tokenIds[j]].start + subPools[i].shares[subPools[i].tokenIds[j]].lockupTime <=
                    block.timestamp
                ) {
                    vars[counter] = DataTypes.VaultSharesReturn(
                        subPools[i].tokenIds[j],
                        subPools[i].shares[subPools[i].tokenIds[j]].amount
                    );
                    ++counter;
                }
            }
        }
        sharesReturn = new DataTypes.VaultSharesReturn[](counter);
        for (uint256 i; i < counter; ++i) {
            sharesReturn[i] = vars[i];
        }
    }

    /**
     * @dev Function to move all mature shares to the maturity subpool maxed by maxTrancheCount
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param poolData The pool data
     * @param subPools The subpools array
     * @param maxTrancheCount The max count of token ids to move
     * @return trancheCount amount of token ids moved (can be different than the max)
     */
    function moveMatureShares(
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools,
        uint256 maxTrancheCount
    ) external returns (uint256 trancheCount) {
        for (uint256 i = poolData.firstActivePool; i < subPools.length; ++i) {
            for (uint256 j; j < subPools[i].tokenIds.length; ++j) {
                if (
                    subPools[i].shares[subPools[i].tokenIds[j]].start + subPools[i].shares[subPools[i].tokenIds[j]].lockupTime <=
                    block.timestamp
                ) {
                    PoolSVSLogic.findAndSaveTokenId(
                        subPools[i].tokenIds[j],
                        0,
                        subPools[i].shares[subPools[i].tokenIds[j]].start,
                        subPools[i].shares[subPools[i].tokenIds[j]].lockupTime,
                        subPools
                    );
                    subPools[0].shares[subPools[i].tokenIds[j]].amount += subPools[i].shares[subPools[i].tokenIds[j]].amount;
                    subPools[0].totalShares += subPools[i].shares[subPools[i].tokenIds[j]].amount;
                    subPools[i].totalShares -= subPools[i].shares[subPools[i].tokenIds[j]].amount;
                    subPools[i].shares[subPools[i].tokenIds[j]].amount = 0;
                    ++trancheCount;
                    if (trancheCount == maxTrancheCount) break;
                }
            }
            PoolSVSLogic.updatePriceIterative(addressesRegistry, poolData, subPools, i);
        }
        emit MovedMatureShares(msg.sender, trancheCount);
    }

    /**
     * @dev Function to move mature shares by selected token ids and amounts
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param poolData The pool data
     * @param subPools The subpools array
     * @param tranches The array of token ids to move
     * @param amounts The array of amounts to move
     * @return trancheCount amount of token ids moved (can be different than the tranches array length)
     */
    function moveMatureSharesList(
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools,
        uint256[] memory tranches,
        uint256[] memory amounts
    ) external returns (uint256 trancheCount) {
        //If subpool is empty, delete its array and make status = false
        require(tranches.length == amounts.length, Errors.ARRAY_NOT_SAME_LENGTH);
        uint256 subPoolIndex;
        for (uint256 i; i < tranches.length; ++i) {
            (subPoolIndex, , , , ) = PoolSVSLogic.checkSubPool(tranches[i], addressesRegistry, poolData, subPools);
            if (
                subPoolIndex != 0 &&
                subPools[subPoolIndex].shares[tranches[i]].start + subPools[subPoolIndex].shares[tranches[i]].lockupTime <= block.timestamp
            ) {
                require(subPools[subPoolIndex].shares[tranches[i]].amount >= amounts[i], Errors.NOT_ENOUGH_SUBPOOL_SHARES);
                subPools[subPoolIndex].shares[tranches[i]].amount -= amounts[i];
                subPools[0].shares[tranches[i]].amount += amounts[i];
                subPools[subPoolIndex].totalShares -= amounts[i];
                subPools[0].totalShares += amounts[i];
                PoolSVSLogic.findAndSaveTokenId(
                    tranches[i],
                    0,
                    subPools[subPoolIndex].shares[tranches[i]].start,
                    subPools[subPoolIndex].shares[tranches[i]].lockupTime,
                    subPools
                );
                ++trancheCount;
                PoolSVSLogic.updatePriceIterative(addressesRegistry, poolData, subPools, subPoolIndex);
            }
        }
        emit MovedMatureSharesList(msg.sender, trancheCount);
    }

    /**
     * @dev Function to clean all mature subpools and change the starting index
     * @param poolData The pool data
     * @param subPools The subpools array
     */
    function cleanMatureSubPools(DataTypes.PoolSVSData storage poolData, DataTypes.AMMSubPoolSVS[] storage subPools) external {
        uint256 newFirstActive = poolData.firstActivePool;
        uint256 cleaned;
        for (uint256 i = poolData.firstActivePool; i < subPools.length; ++i) {
            bool allMature = true;
            for (uint256 j; j < subPools[i].tokenIds.length; ++j) {
                if (
                    subPools[i].shares[subPools[i].tokenIds[j]].start + subPools[i].shares[subPools[i].tokenIds[j]].lockupTime >
                    block.timestamp
                ) {
                    allMature = false;
                }
            }
            if (allMature && (subPools[i].start + poolData.maxMaturityRange) <= block.timestamp) {
                subPools[i].status = false;
                subPools[i].start = 0;
                delete subPools[i].tokenIds;
                ++cleaned;
                //increment the new first active if the lowest is cleaned
                if (i == (newFirstActive + 1)) {
                    ++newFirstActive;
                }
            }
        }
        poolData.firstActivePool = newFirstActive;
        emit CleanedMatureSubPools(msg.sender, cleaned);
    }

    ///TODO: integrate with the batch if possible
    /**
     * @dev Function to redeem all the mature shares from the maturity subpool maxed by maxTrancheCount
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param poolData The pool data
     * @param subPools The subpools array
     * @param maxTrancheCount The max count of token ids to redeem
     * @return trancheCount amount of token ids redeemed (can be different than the max)
     */
    function redeemMatureShares(
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools,
        uint256 maxTrancheCount
    ) external returns (uint256 trancheCount) {
        uint256 tokenId;
        //If subpool is empty, delete its array
        for (uint256 i; i < subPools[0].tokenIds.length; ++i) {
            tokenId = subPools[0].tokenIds[i];
            //Moving the redemption functionality from lp token to the mme itself
            ILPTokenSVS(poolData.poolLPToken).checkApproval1155(poolData.tokens);
            ISVS(IVault1155(poolData.tokens[0]).getSVS()).safeTransferFrom(
                poolData.poolLPToken,
                address(this),
                tokenId,
                subPools[0].shares[tokenId].amount,
                "0x"
            );
            IVault1155(poolData.tokens[0]).redeemUnderlying(subPools[0].shares[tokenId].amount, tokenId);
            subPools[0].shares[tokenId].amount = 0;
            ++trancheCount;
            if (trancheCount == maxTrancheCount) break;
        }
        emit RedeemedMatureShares(msg.sender, trancheCount);
        uint256 initial = IERC20Extended(poolData.stable).balanceOf(address(this));
        // console.log("initial: ", initial);
        swapVITs(addressesRegistry, poolData);
        uint256 redeemed = IERC20Extended(poolData.stable).balanceOf(address(this)) - initial;
        // console.log("redeemed: ", redeemed);
        subPools[0].reserve += redeemed;
        // console.log("subPools[0].reserve: ", subPools[0].reserve);
        //If all the token ids were redeemed, empty the array.
        //Otherwise move the the values by index lower and then pop the array to remove the last elements moved
        if (subPools[0].tokenIds.length <= trancheCount) {
            delete subPools[0].tokenIds;
        } else {
            for (uint i = trancheCount; i < subPools[0].tokenIds.length; i++) {
                subPools[0].tokenIds[i - trancheCount] = subPools[0].tokenIds[i];
            }
            // Remove the trancheCount elements using a separate loop
            for (uint i = 0; i < trancheCount; i++) {
                subPools[0].tokenIds.pop();
            }
        }
        IERC20Extended(poolData.stable).transfer(poolData.poolLPToken, redeemed);
    }

    /**
     * @dev Function to swap all available VITs to stablecoin
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param poolData The pool data
     */
    function swapVITs(address addressesRegistry, DataTypes.PoolSVSData storage poolData) public {
        address[] memory VITs;
        (VITs, ) = PoolSVSLogic.getCollectionConnector(addressesRegistry, poolData).getVITs(poolData.tokens[0]);
        for (uint i; i < VITs.length; ++i) {
            // Moving the redemption functionality from lp token to the mme itself for gas efficiency
            // ILPTokenSVS(poolData.poolLPToken).setApproval20(VITs[i], IERC20Extended(VITs[i]).balanceOf(address(poolData.poolLPToken)));
            // IERC20Extended(VITs[i]).transferFrom(
            //     poolData.poolLPToken,
            //     address(this),
            //     IERC20Extended(VITs[i]).balanceOf(address(poolData.poolLPToken))
            // );
            // console.log("vit balance: ",IERC20Extended(VITs[i]).balanceOf(address(this)));
            if (IERC20Extended(VITs[i]).balanceOf(address(this)) > 0) {
                exchangeSwap(addressesRegistry, poolData.stable, IERC20Extended(VITs[i]).balanceOf(address(this)), VITs[i]);
            }
        }
    }

    /**
     * @dev Function to swap a certain token using its exchange and 2% max slippage on the quote
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param stable The stablecoin address
     * @param amountPerSwap The amount to swap
     * @param VIT The swappable token address
     */
    function exchangeSwap(address addressesRegistry, address stable, uint256 amountPerSwap, address VIT) public {
        address exchangeSwapContract = IConnectorRouter(IAddressesRegistry(addressesRegistry).getConnectorsRouter()).getSwapContract(VIT);
        IERC20Extended(VIT).approve(exchangeSwapContract, amountPerSwap);
        IExchangeSwapWithOutQuote(exchangeSwapContract).swap(
            VIT,
            stable,
            amountPerSwap,
            (IExchangeSwapWithOutQuote(exchangeSwapContract).getQuoteIn(VIT, stable, amountPerSwap) * 98) / 100
        );
    }

    /**
     * @dev Function to change the lockup times of the subpools to fit the vault
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param poolData The pool data
     * @param subPools The subpools array
     * @param lastLockupTimes The last lockup times for comparison
     */
    function changeLockupTimes(
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools,
        uint256[] memory lastLockupTimes
    ) external {
        uint256[] memory lockupTimes = PoolSVSLogic.getCollectionConnector(addressesRegistry, poolData).getLockupTimes(poolData.tokens[0]);
        for (uint256 i = poolData.firstActivePool; i < subPools.length; ++i) {
            uint256 newLockupTime;
            uint256 lastLockupTime;
            for (uint256 j; j < lastLockupTimes.length; ++j) {
                if (subPools[i].lockupTime == lastLockupTimes[j]) {
                    lastLockupTime = lastLockupTimes[j];
                    newLockupTime = lockupTimes[j];
                    break;
                }
            }
            subPools[i].lockupTime = newLockupTime;
            for (uint256 j; j < subPools[i].tokenIds.length; ++j) {
                subPools[i].shares[subPools[i].tokenIds[j]].lockupTime = newLockupTime;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypes} from "./DataTypes.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Errors} from "./Errors.sol";
import {ILPTokenSVS} from "../interfaces/ILPTokenSVS.sol";
import {LPTokenSVS} from "../ammSVS/LPTokenSVS.sol";
import {MathHelpers} from "./MathHelpers.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {IConnectorRouter} from "../interfaces/IConnectorRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISVSCollectionConnector} from "../interfaces/ISVSCollectionConnector.sol";
import {IPriceOracleConnector} from "../interfaces/IPriceOracleConnector.sol";
import {IVault1155} from "../interfaces/IVault1155.sol";
import {ISVS} from "../interfaces/ISVS.sol";

/**
 * @title library for pool logic functions for the SVS Pools with single collection
 * @author Souq.Finance
 * @notice License: https://souq-exchange.s3.amazonaws.com/LICENSE.md
 */

library PoolSVSLogic {
    using SafeERC20 for IERC20;
    using Math for uint256;
    /**
     * @dev Emitted when tokens different than the tokens used by the pool are rescued for receivers by the admin
     * @param admin The admin that executed the function
     * @param token The address of the token contract
     * @param amount The amount of tokens
     * @param receiver The address of the receiver
     */
    event Rescued(address admin, address token, uint256 amount, address receiver);

    /**
     * @dev Emitted when a new LP Token is deployed
     * @param LPAdress The address of the LP Token
     * @param poolAddress The address of the liquidity pool that deployed it
     * @param tokens the addresses of the ERC1155 tokens that the liquidity pool utilizes
     * @param symbol the symbol of the LP Token
     * @param name the name of the LP Token
     * @param decimals the decimals of the LP Token
     */
    event LPTokenDeployed(address LPAdress, address poolAddress, address[] tokens, string symbol, string name, uint8 decimals);
    /**
     * @dev Emitted when a new sub pool is added by the admin
     * @param admin The admin that executed the function
     * @param f the initial F of the new pool
     * @param start the initial start time of the new pool
     * @param lockupTime the lockup time of the new pool (ex. 1 month or 3 months or 6)
     * @param id the id of the new sub pool
     */
    event AddedSubPool(address admin, uint256 f, uint256 start, uint256 lockupTime, uint256 id);

    /**
     * @dev Emitted when the Pool Data struct is changed
     * @param _data The new pool data
     */
    event PoolDataSet(DataTypes.PoolSVSData _data);

    /**
     * @dev Emmitted when the status of specific subpools is modified
     * @param admin The admin that executed the function
     * @param subPoolIds The sub pool ids array
     * @param newStatus The new status, enabled=true or disabled=false
     */
    event ChangedSubpoolStatus(address admin, uint256[] subPoolIds, bool newStatus);

    /**
     * @dev Function to get the TVL of a specific sub pool
     * @param subPools The subpools array
     * @param subPoolId The id of the sub pool
     * @return subpool DataTypes.AMMSubPoolSVSDetails object
     */
    function getPool(
        DataTypes.AMMSubPoolSVS[] storage subPools,
        uint256 subPoolId
    ) external view returns (DataTypes.AMMSubPoolSVSDetails memory subpool) {
        subpool.reserve = subPools[subPoolId].reserve;
        subpool.totalShares = subPools[subPoolId].totalShares;
        subpool.start = subPools[subPoolId].start;
        subpool.lockupTime = subPools[subPoolId].lockupTime;
        subpool.F = subPools[subPoolId].F;
        subpool.status = subPools[subPoolId].status;
    }

    /**
     * @dev Function to calculate the total value of a sub pool
     * @param subPools the sub pools array
     * @param v The calculated v in the bonding curve
     * @param subPoolId the sub pool id
     * @return uint256 The total value of a subpool
     */
    function calculateTotal(DataTypes.AMMSubPoolSVS[] storage subPools, uint256 v, uint256 subPoolId) public view returns (uint256) {
        return subPools[subPoolId].reserve + MathHelpers.convertFromWad(subPools[subPoolId].totalShares * v * subPools[subPoolId].F);
    }

    // /**
    //  * @dev Function to get the total TVL of the liquidity pool from its subpools
    //  * @param subPools The subpools array
    //  * @param poolData the pool data
    //  * @param addressesRegistry the addresses registry contract
    //  * @return total The TVL
    //  */
    // function getTVL(
    //     DataTypes.AMMSubPoolSVS[] storage subPools,
    //     DataTypes.PoolSVSData storage poolData,
    //     address addressesRegistry
    // ) public view returns (uint256 total) {
    //     uint256 v = getV(addressesRegistry, poolData, subPools);
    //     for (uint256 i; i < subPools.length; ++i) {
    //         total += calculateTotal(subPools, v, i);
    //     }
    // }

    // /**
    //  * @dev Function to get the total active TVL of the liquidity pool from its active subpools
    //  * @param subPools The subpools array
    //  * @param poolData the pool data
    //  * @param addressesRegistry the addresses registry contract
    //  * @return total The TVL
    //  */
    // function getTVLActive(
    //     DataTypes.AMMSubPoolSVS[] storage subPools,
    //     DataTypes.PoolSVSData storage poolData,
    //     address addressesRegistry
    // ) public view returns (uint256 total) {
    //     uint256 v = getV(addressesRegistry, poolData, subPools);
    //     for (uint256 i; i < subPools.length; ++i) {
    //         if (subPools[i].status) {
    //             total += calculateTotal(subPools, v, i);
    //         }
    //     }
    // }

    // /**
    //  * @dev Function to get the LP Token price by dividing the TVL over the total minted tokens
    //  * @param addressesRegistry the addresses registry contract
    //  * @param poolData the pool data
    //  * @param subPools The subpools array
    //  * @return uint256 The LP Price
    //  */
    // function getLPPrice(
    //     DataTypes.AMMSubPoolSVS[] storage subPools,
    //     address addressesRegistry,
    //     DataTypes.PoolSVSData storage poolData
    // ) public view returns (uint256) {
    //     uint256 total = ILPTokenSVS(poolData.poolLPToken).getTotal();
    //     uint256 tvl = getTVL(subPools, poolData, addressesRegistry);
    //     if (total == 0 || tvl == 0) {
    //         return MathHelpers.convertToWad(1);
    //     }
    //     return MathHelpers.convertToWad(tvl) / total;
    // }

    // /**
    //  * @dev Function to get the TVL and LP Token price together which saves gas if we need both variables
    //  * @param addressesRegistry the addresses registry contract
    //  * @param poolData the pool data
    //  * @param subPools The subpools array
    //  * @return (uint256,uint256) The TVL and LP Price
    //  */
    // function getTVLAndLPPrice(
    //     DataTypes.AMMSubPoolSVS[] storage subPools,
    //     address addressesRegistry,
    //     DataTypes.PoolSVSData storage poolData
    // ) external view returns (uint256, uint256) {
    //     uint256 total = ILPTokenSVS(poolData.poolLPToken).getTotal();
    //     uint256 tvl = getTVL(subPools, poolData, addressesRegistry);
    //     if (total == 0 || tvl == 0) {
    //         return (tvl, MathHelpers.convertToWad(1));
    //     }
    //     return (tvl, (MathHelpers.convertToWad(tvl) / total));
    // }

    // /**
    //  * @dev Function that returns the sum of the VIT values including their amounts per 1 share
    //  * @notice this causes a circular dependency if the lp token is one of the VITs
    //  * @param addressesRegistry the addresses registry used to link the connectors
    //  * @param poolData The pool data
    //  * @return v the total sum denoted as V
    //  */
    // function getV(
    //     address addressesRegistry,
    //     DataTypes.PoolSVSData storage poolData,
    //     DataTypes.AMMSubPoolSVS[] storage subPools
    // ) public view returns (uint256 v) {
    //     (address[] memory VITs, uint256[] memory amounts) = getCollectionConnector(addressesRegistry, poolData).getVITs(poolData.tokens[0]);
    //     uint256 stablePrice = uint(getPriceConnector(addressesRegistry, poolData.stable).getTokenPrice(poolData.stable));
    //     for (uint i; i < VITs.length; ++i) {
    //         //TODO: test negative?
    //         //The amounts are in wei in the vault1155
    //         if (VITs[i] == poolData.poolLPToken) {
    //             v += MathHelpers.convertFromBiggerToSmaller(
    //                 amounts[i] * getLPPrice(subPools, addressesRegistry, poolData) * stablePrice,
    //                 42,
    //                 6
    //             );
    //         } else {
    //             v += MathHelpers.convertFromBiggerToSmaller(
    //                 amounts[i] * uint(getPriceConnector(addressesRegistry, VITs[i]).getTokenPrice(VITs[i])) * stablePrice,
    //                 30,
    //                 6
    //             );
    //         }
    //     }
    // }

    function calculateV(
        uint256 lpPrice,
        address[] memory VITs,
        uint256[] memory amounts,
        uint256 stablePrice,
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData
    ) public view returns (uint256 v) {
        for (uint i; i < VITs.length; ++i) {
            //The amounts are in wei in the vault1155
            //lpPrice is in wei
            //stablePrice are 6 decimals
            //Token prices are 6 decimals
            if (VITs[i] == poolData.poolLPToken) {
                v += MathHelpers.convertFromBiggerToSmaller(amounts[i] * lpPrice * stablePrice, 42, 6);
            } else {
                v += MathHelpers.convertFromBiggerToSmaller(
                    amounts[i] * uint(getPriceConnector(addressesRegistry, VITs[i]).getTokenPrice(VITs[i])) * stablePrice,
                    30,
                    6
                );
            }
        }
    }

    function calculateTVL(uint256 v, DataTypes.AMMSubPoolSVS[] storage subPools) public view returns (uint256 tvl, uint256 tvlActive) {
        uint256 total;
        for (uint256 i; i < subPools.length; ++i) {
            total = calculateTotal(subPools, v, i);
            tvl += total;
            if (subPools[i].status == true) {
                tvlActive += total;
            }
        }
    }

    function calculateLiquidityDetailsIterative(
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) public view returns (uint256 v, uint256 tvl, uint256 tvlActive, uint256 lpPrice) {
        DataTypes.LiquidityDetailsVars memory vars;
        (vars.VITs, vars.amounts) = getCollectionConnector(addressesRegistry, poolData).getVITs(poolData.tokens[0]);
        vars.stablePrice = uint(getPriceConnector(addressesRegistry, poolData.stable).getTokenPrice(poolData.stable));
        vars.total = ILPTokenSVS(poolData.poolLPToken).getTotal();
        lpPrice = poolData.liquidityLimit.lastLpPrice;
        for (vars.i; vars.i < 1; ++vars.i) {
            v = calculateV(lpPrice, vars.VITs, vars.amounts, vars.stablePrice, addressesRegistry, poolData);
            (tvl, tvlActive) = calculateTVL(v, subPools);
            lpPrice = (vars.total == 0 || tvl == 0) ? MathHelpers.convertToWad(1) : MathHelpers.convertToWad(tvl) / vars.total;
        }
    }

    /**
     * @dev Function to get the actual fee value structure depending on swap direction
     * @param operation The direction of the swap
     * @param value value of the amount to compute the fees for
     * @param fee The fee configuration of the liquidity pool
     * @return feeReturn The return fee structure that has the ratios
     */
    function calculateFees(
        DataTypes.OperationType operation,
        uint256 value,
        DataTypes.PoolFee storage fee
    ) public view returns (DataTypes.FeeReturn memory feeReturn) {
        uint256 actualValue;
        if (operation == DataTypes.OperationType.buyShares) {
            actualValue = MathHelpers.convertFromWadPercentage(value * (MathHelpers.convertToWadPercentage(1) - fee.lpBuyFee));
            feeReturn.royalties = MathHelpers.convertFromWadPercentage(fee.royaltiesBuyFee * actualValue);
            feeReturn.lpFee = MathHelpers.convertFromWadPercentage(fee.lpBuyFee * value);
            feeReturn.protocolFee = MathHelpers.convertFromWadPercentage(fee.protocolBuyRatio * actualValue);
        } else if (operation == DataTypes.OperationType.sellShares) {
            actualValue = MathHelpers.convertToWadPercentage(value) / (MathHelpers.convertToWadPercentage(1) - fee.lpSellFee);
            feeReturn.royalties = MathHelpers.convertFromWadPercentage(fee.royaltiesSellFee * actualValue);
            feeReturn.lpFee = MathHelpers.convertFromWadPercentage(fee.lpSellFee * value);
            feeReturn.protocolFee = MathHelpers.convertFromWadPercentage(fee.protocolSellRatio * actualValue);
        }
        feeReturn.swapFee = feeReturn.lpFee + feeReturn.protocolFee;
        feeReturn.totalFee = feeReturn.royalties + feeReturn.swapFee;
    }

    /**
     * @dev Function to add two feeReturn structures and output 1
     * @param x the first feeReturn struct
     * @param y the second feeReturn struct
     * @return z The return data structure
     */
    function addFees(DataTypes.FeeReturn memory x, DataTypes.FeeReturn memory y) external pure returns (DataTypes.FeeReturn memory z) {
        //Add all the fees together
        z.totalFee = x.totalFee + y.totalFee;
        z.royalties = x.royalties + y.royalties;
        z.protocolFee = x.protocolFee + y.protocolFee;
        z.lpFee = x.lpFee + y.lpFee;
        z.swapFee = x.swapFee + y.swapFee;
    }

    /**
     * @dev Function to multiply a fee structure by a number and divide by a den
     * @param fee the original feeReturn struct
     * @param num the numerator
     * @param den The denominator
     * @return feeReturn The new fee structure
     */
    function multiplyFees(
        DataTypes.FeeReturn memory fee,
        uint256 num,
        uint256 den
    ) external pure returns (DataTypes.FeeReturn memory feeReturn) {
        feeReturn.totalFee = (fee.totalFee * num) / den;
        feeReturn.royalties = (fee.royalties * num) / den;
        feeReturn.protocolFee = (fee.protocolFee * num) / den;
        feeReturn.lpFee = (fee.lpFee * num) / den;
        feeReturn.swapFee = (fee.swapFee * num) / den;
    }

    /**
     * @dev Function to calculate the price of a share in a sub pool\
     * @param operation the operation direction
     * @param subPoolId the sub pool id
     * @param addressesRegistry the addresses registry contract
     * @param poolData the pool data
     * @param subPools The sub pools array
     * @return sharesReturn The return data structure
     */
    function CalculateShares(
        DataTypes.OperationType operation,
        uint256 subPoolId,
        uint256 shares,
        bool useFee,
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) external view returns (DataTypes.SharesCalculationReturn memory sharesReturn) {
        require(
            subPools[subPoolId].totalShares >= shares || operation != DataTypes.OperationType.buyShares,
            Errors.NOT_ENOUGH_SUBPOOL_SHARES
        );
        //Iterative approach
        DataTypes.SharesCalculationVars memory vars;
        //Initial values
        (vars.V, , , sharesReturn.lastLpPrice) = calculateLiquidityDetailsIterative(addressesRegistry, poolData, subPools);
        vars.PV_0 = MathHelpers.convertFromWad(vars.V * subPools[subPoolId].F);
        sharesReturn.PV = vars.PV_0;
        //Calculate steps
        vars.steps = shares / poolData.iterativeLimit.maxBulkStepSize;
        //At first the stable = reserve
        vars.stable = subPools[subPoolId].reserve;
        vars.shares = subPools[subPoolId].totalShares;
        //Iterating step sizes for enhanced results. If amount = 50, and stepsize is 15, then we iterate 4 times 15,15,15,5
        for (vars.stepIndex; vars.stepIndex < vars.steps + 1; ++vars.stepIndex) {
            vars.stepAmount = vars.stepIndex == vars.steps
                ? (shares - ((vars.stepIndex) * poolData.iterativeLimit.maxBulkStepSize))
                : poolData.iterativeLimit.maxBulkStepSize;
            if (vars.stepAmount == 0) break;
            //The value of the shares are priced first at last PV
            vars.value = vars.stepAmount * vars.PV_0;
            if (useFee) vars.fees = calculateFees(operation, vars.value, poolData.fee);
            //Iterate the calculations while keeping PV_0 and stable the same and using the new PV to calculate the average and reiterate
            for (vars.i = 0; vars.i < poolData.iterativeLimit.iterations; ++vars.i) {
                if (operation == DataTypes.OperationType.buyShares) {
                    //if buying shares, the pool receives stable plus the swap fee and gives out shares
                    vars.newCash = vars.stable + vars.value + (useFee ? vars.fees.lpFee : 0);
                    vars.den =
                        vars.newCash +
                        ((poolData.coefficients.coefficientB * (vars.shares - vars.stepAmount) * sharesReturn.PV) /
                            poolData.coefficients.coefficientC);
                } else if (operation == DataTypes.OperationType.sellShares) {
                    require(vars.stable >= vars.value, Errors.NOT_ENOUGH_SUBPOOL_RESERVE);
                    //if selling shares, the pool receives shares and gives out stable - total fees from the reserve
                    vars.newCash = vars.stable - vars.value + (useFee ? vars.fees.lpFee : 0);
                    vars.den =
                        vars.newCash +
                        ((poolData.coefficients.coefficientB * (vars.shares + vars.stepAmount) * sharesReturn.PV) /
                            poolData.coefficients.coefficientC);
                }
                //Calculate new PV and F
                sharesReturn.F = vars.den == 0 ? 0 : (poolData.coefficients.coefficientA * vars.newCash) / vars.den;
                sharesReturn.PV = MathHelpers.convertFromWad(vars.V * sharesReturn.F);
                //Swap PV is the price used for the swapping in the newCash
                vars.swapPV = vars.stepAmount > 1 ? ((sharesReturn.PV + vars.PV_0) / 2) : vars.PV_0;
                vars.value = vars.stepAmount * vars.swapPV;
                if (useFee) vars.fees = calculateFees(operation, vars.value, poolData.fee);
            }
            //We add/subtract the shares to be used in the next stepsize iteration
            vars.shares = operation == DataTypes.OperationType.buyShares ? vars.shares - vars.stepAmount : vars.shares + vars.stepAmount;
            //At the end of iterations, the stable is now the last cash value
            vars.stable = vars.newCash;
            //The starting PV is now the last PV value
            vars.PV_0 = sharesReturn.PV;
            //Add the amounts to the return
            sharesReturn.amount += vars.stepAmount;
        }
        //Calculate the actual value to return
        sharesReturn.value = operation == DataTypes.OperationType.buyShares
            ? vars.stable - subPools[subPoolId].reserve
            : subPools[subPoolId].reserve - vars.stable;
        //Calculate the final fees
        if (useFee) sharesReturn.fees = calculateFees(operation, sharesReturn.value, poolData.fee);
        //Average the swap PV in the return
        sharesReturn.swapPV = sharesReturn.value / sharesReturn.amount;
    }

    /**
     * @dev Function to update the price iteratively in a subpool
     * @notice This updates the last lp price
     * @param subPools The sub pools array
     * @param addressesRegistry the addresses registry contract
     * @param poolData The pool data struct
     * @param subPoolId the sub pool id
     */
    function updatePriceIterative(
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools,
        uint256 subPoolId
    ) public {
        //coef is converted to wad and we also need F to be converted to wad
        uint256 num = ((poolData.coefficients.coefficientA * subPools[subPoolId].reserve));
        (uint256 v, , , uint256 lastLpPrice) = calculateLiquidityDetailsIterative(addressesRegistry, poolData, subPools);
        uint256 temp = poolData.coefficients.coefficientB * subPools[subPoolId].totalShares * v;
        uint256 den = (subPools[subPoolId].reserve +
            (MathHelpers.convertFromWad(temp * subPools[subPoolId].F) / poolData.coefficients.coefficientC));
        subPools[subPoolId].F = den == 0 ? 0 : num / den;
        //Iteration 0 is done, iterate through the rest
        if (poolData.iterativeLimit.iterations > 1) {
            for (uint256 i; i < poolData.iterativeLimit.iterations - 1; ++i) {
                den = (subPools[subPoolId].reserve +
                    (MathHelpers.convertFromWad(subPools[subPoolId].F * temp) / poolData.coefficients.coefficientC));
                subPools[subPoolId].F = den == 0 ? 0 : num / den;
            }
        }
        poolData.liquidityLimit.lastLpPrice = lastLpPrice;
    }


    /**
     * @dev Function to update the coefficients and prices of all active subpools
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param poolData The pool data including fee configuration
     * @param subPools the subpools array of the liquidity pool
     * @param coefficientA the coefficient A of the bonding curve
     * @param coefficientB the coefficient B of the bonding curve
     * @param coefficientC the coefficient C of the bonding curve
     */
    function updateCoefficients(
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools,
        uint256 coefficientA,
        uint256 coefficientB,
        uint256 coefficientC
    ) public {
        poolData.coefficients.coefficientA = coefficientA;
        poolData.coefficients.coefficientB = coefficientB;
        poolData.coefficients.coefficientC = coefficientC;
        for (uint256 i = poolData.firstActivePool; i < subPools.length; ++i) {
            updatePriceIterative(addressesRegistry, poolData, subPools, i);
        }
    }


    /**
     * @dev Function to set the Pool Data and update coefficients
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param poolData The pool data including fee configuration
     * @param subPools the subpools array of the liquidity pool
     * @param newPoolData the new pooldata struct
     */
    function setPoolData(
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools,
        DataTypes.PoolSVSData calldata newPoolData
    ) external {
        poolData.useAccessToken = newPoolData.useAccessToken;
        poolData.accessToken = newPoolData.accessToken;
        poolData.stableYieldAddress = newPoolData.stableYieldAddress;
        poolData.firstActivePool = newPoolData.firstActivePool; //For testing
        updateCoefficients(
            addressesRegistry,
            poolData,
            subPools,
            newPoolData.coefficients.coefficientA,
            newPoolData.coefficients.coefficientB,
            newPoolData.coefficients.coefficientC
        );
        emit PoolDataSet(poolData);
    }
    /**
     * @dev Function to add a new sub pool
     * @param f The initial F value of the sub pool
     * @param start The start time of the subpool
     * @param lockupTime The lockup time of the subpool (ex. 1 month)
     * @param subPools The subpools array
     */
    function addSubPool(uint256 f, uint256 start, uint256 lockupTime, DataTypes.AMMSubPoolSVS[] storage subPools) public {
        DataTypes.AMMSubPoolSVS storage newPool = subPools.push();
        newPool.reserve = 0;
        newPool.totalShares = 0;
        newPool.F = f;
        newPool.lockupTime = lockupTime;
        newPool.start = start;
        newPool.status = false;
        emit AddedSubPool(msg.sender, f, start, lockupTime, subPools.length - 1);
    }

    /**
     * @dev Function to add a new sub pool(s) phase automatically according to the collection lockuptimes and maturity range
     * @param f The initial F value of the sub pool
     * @param start the start of subpool maturity
     * @param addressesRegistry The addresses Registry contract address
     * @param poolData The pool data
     * @param subPools The subpools array
     */
    function addSubPoolsAuto(
        uint256 f,
        uint256 start,
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) public {
        uint256 lastStart = subPools.length > 1
            ? (subPools[subPools.length - 1].start + poolData.maxMaturityRange)
            : block.timestamp - (block.timestamp % 1 days);
        uint256[] memory lockupTimes = getCollectionConnector(addressesRegistry, poolData).getLockupTimes(poolData.tokens[0]);
        while (lastStart <= start) {
            for (uint256 i; i < lockupTimes.length; ++i) {
                DataTypes.AMMSubPoolSVS storage newPool = subPools.push();
                newPool.reserve = 0;
                newPool.totalShares = 0;
                newPool.F = f;
                newPool.lockupTime = lockupTimes[i];
                newPool.start = lastStart;
                newPool.status = false;
                emit AddedSubPool(msg.sender, f, lastStart, lockupTimes[i], subPools.length - 1);
            }
            lastStart += poolData.maxMaturityRange;
        }
    }

    /**
     * @dev Function to find and save a new token id in the tokenids of a subpool
     * @param tokenId the token id
     * @param subPoolId The subpool id
     * @param subPools The subpools array
     */
    function findAndSaveTokenId(
        uint256 tokenId,
        uint256 subPoolId,
        uint256 start,
        uint256 lockupTime,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) external returns (uint256 foundTokenId) {
        bool tokenIdFound;
        for (uint256 j = 0; j < subPools[subPoolId].tokenIds.length; ++j) {
            if (subPools[subPoolId].tokenIds[j] == tokenId) {
                tokenIdFound = true;
                foundTokenId = tokenId;
                break;
            }
        }
        if (!tokenIdFound) {
            subPools[subPoolId].tokenIds.push(tokenId);
            foundTokenId = subPools[subPoolId].tokenIds.length - 1;
        }
        if (subPools[subPoolId].shares[tokenId].start == 0 && (start + lockupTime) > block.timestamp) {
            subPools[subPoolId].shares[tokenId].start = start;
            subPools[subPoolId].shares[tokenId].lockupTime = lockupTime;
        }
    }

    /**
     * @dev Function to move enable or disable subpools by ids
     * @param subPoolIds The sub pool ids array
     * @param newStatus The new status, enabled=true or disabled=false
     * @param subPools The subpools array
     */
    function changeSubPoolStatus(uint256[] memory subPoolIds, bool newStatus, DataTypes.AMMSubPoolSVS[] storage subPools) external {
        for (uint256 i; i < subPoolIds.length; ++i) {
            subPools[subPoolIds[i]].status = newStatus;
        }
        emit ChangedSubpoolStatus(msg.sender, subPoolIds, newStatus);
    }

    /**
     * @dev Function that deploys the LP Token of the pool
     * @param poolAddress The address of the pool
     * @param registry The registry address
     * @param tokens The collection tokens to be used by the pool
     * @param symbol The symbol of the LP Token
     * @param name The name of the LP Token
     * @param decimals The decimals of the LP Token
     * @return address of the LP Token
     */
    function deployLPToken(
        address poolAddress,
        address registry,
        address[] memory tokens,
        string memory symbol,
        string memory name,
        uint8 decimals
    ) external returns (address) {
        ILPTokenSVS poolLPToken = new LPTokenSVS(poolAddress, registry, tokens, symbol, name, decimals);
        emit LPTokenDeployed(address(poolLPToken), poolAddress, tokens, symbol, name, decimals);
        return address(poolLPToken);
    }

    /**
     * @dev Function to rescue and send ERC20 tokens (different than the tokens used by the pool) to a receiver called by the admin
     * @param token The address of the token contract
     * @param amount The amount of tokens
     * @param receiver The address of the receiver
     * @param stableToken The address of the stablecoin to rescue
     * @param poolLPToken The address of the pool LP Token
     */
    function RescueTokens(address token, uint256 amount, address receiver, address stableToken, address poolLPToken) external {
        require(token != stableToken, Errors.CANNOT_RESCUE_POOL_TOKEN);
        emit Rescued(msg.sender, token, amount, receiver);
        ILPTokenSVS(poolLPToken).rescueTokens(token, amount, receiver);
    }

    /**
     * @dev Function that returns the subpool of a token id (tranche) or 0 if it matured and moved
     * @notice reverts if no subpool found
     * @param tokenId The token id
     * @param addressesRegistry The addresses Registry contract address
     * @param poolData The pool data
     * @param subPools The subpools array
     * @return subPoolIndex the subpool id
     * @return foundSubpool the found flag if there is a subpool for it
     * @return lockupStart the start of maturity of the token id
     */
    function checkSubPool(
        uint256 tokenId,
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) public view returns (uint256 subPoolIndex, bool foundSubpool, uint256 lockupStart, uint256 lockupTime, bool matured) {
        (lockupStart, lockupTime) = getTokenDetails(addressesRegistry, poolData, tokenId);
        for (uint256 i; i < subPools.length; ++i) {
            if (
                lockupTime == subPools[i].lockupTime &&
                lockupStart >= (subPools[i].start) &&
                lockupStart < subPools[i].start + poolData.maxMaturityRange
            ) {
                foundSubpool = true;
                subPoolIndex = i;
                break;
            }
        }
        matured = lockupStart + lockupTime <= block.timestamp ? true : false;
    }

    /**
     * @dev Function that returns the start of a token id maturity period (tranche)
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param poolData The pool data
     * @param tokenId The token id (tranche id)
     * @return start the start of that token id maturity
     * @return lockupTime the lockupTime of that token id
     */
    function getTokenDetails(
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        uint256 tokenId
    ) public view returns (uint256 start, uint256 lockupTime) {
        ISVSCollectionConnector connector = getCollectionConnector(addressesRegistry, poolData);
        start = connector.getAttribute(poolData.tokens[0], tokenId);
        lockupTime = connector.getLockupTime(poolData.tokens[0], tokenId);
    }

    /**
     * @dev Function that returns the interface of the collection connector (vault connector)
     * @param addressesRegistry the addresses registry used to link the connectors
     * @return ISVSCollectionConnector the svs collection connector interface
     */
    function getCollectionConnector(
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData
    ) public view returns (ISVSCollectionConnector) {
        return
            ISVSCollectionConnector(
                IConnectorRouter(IAddressesRegistry(addressesRegistry).getConnectorsRouter()).getCollectionConnectorContract(
                    poolData.tokens[0]
                )
            );
    }

    /**
     * @dev Function that returns the interface of the price oracle connector
     * @param addressesRegistry the addresses registry used to link the connectors
     * @return IPriceOracleConnector the price oracle connector interface
     */
    function getPriceConnector(address addressesRegistry, address asset) public view returns (IPriceOracleConnector) {
        return
            IPriceOracleConnector(
                IConnectorRouter(IAddressesRegistry(addressesRegistry).getConnectorsRouter()).getOracleConnectorContract(asset)
            );
    }

    /**
     * @dev Function that returns the subpool ids of the given token ids
     * @param tokenIds The address of the pool
     * @param addressesRegistry the addresses registry used to link the connectors
     * @param poolData The pool data
     * @param subPools The subpools array
     * @return subs array of the subpool ids of the token ids
     */
    function getSubPools(
        uint256[] memory tokenIds,
        address addressesRegistry,
        DataTypes.PoolSVSData storage poolData,
        DataTypes.AMMSubPoolSVS[] storage subPools
    ) external view returns (uint256[] memory subs) {
        subs = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            (subs[i], , , , ) = checkSubPool(tokenIds[i], addressesRegistry, poolData, subPools);
        }
    }

    /**
     * @dev Function that gets the token of a collection if it is different (like Vault vs SVS)
     * @param poolData The pool data
     * @return address of the token
     */
    function getCollectionToken(DataTypes.PoolSVSData storage poolData) external view returns (address) {
        return IVault1155(poolData.tokens[0]).getSVS();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title library for Vault Data structures
 * @author Souq.Finance
 * @notice Defines the vault data structures used by the contracts of the Souq protocol
 * @notice License: https://souq-etf.s3.amazonaws.com/LICENSE.md
 */

library VaultDataTypes {
    enum LockupPeriod {
        THREE_MONTHS,
        SIX_MONTHS,
        TWELVE_MONTHS
    }

    struct VaultData {
        address SVS;
        address stable;
        uint256 initShareValue;
        uint256 currentTranche;
        address[] VITs;
        uint256[] VITAmounts;
        uint256[] lockupTimes;
        uint256 stableDeposited;
        uint256 stableHardcap;
        bool batchMintEnabled;
        bool batchRedeemEnabled;
        VaultFee fee;
    }

    struct VaultFee {
        uint256 depositFee; // 1 represents 0.01%
        uint256 redemptionFee;
        //uint256 rewardFee; //not used in v1.0
    }

    struct VaultShare {
        uint256 tranche;
        address[] tokens;
        uint256[] tokenAmounts;
        uint256 lastRebalanced;
    }

    struct MintParams {
        uint256 numShares;
        uint256 stableAmount;
        uint256[] amountPerSwap;
        VaultDataTypes.LockupPeriod lockup;
        address stable;
        address[] VITs;
        uint256[] VITAmounts;
        uint256 currentTranche;
        address swapRouter;
        address svs;
        uint256 depositFee;
        address vaultAddress;
    }

    struct PendingMint {
        uint256 amountUSDC;
        VaultDataTypes.LockupPeriod lockup;
    }

    struct UserMintRequest {
        uint256 amountUSDC;
        uint256 tranche;
    }
}