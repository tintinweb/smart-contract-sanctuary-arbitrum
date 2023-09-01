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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IAddressesRegistry} from "./IAddressesRegistry.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title IAccessManager
 * @author Souq.Finance
 * @notice The interface for the Access Manager Contract
 * @notice License: https://souq-peripheral-v1.s3.amazonaws.com/LICENSE.md
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IAddressesRegistry
 * @author Souq.Finance
 * @notice Defines the interface of the addresses registry.
 * @notice License: https://souq-peripheral-v1.s3.amazonaws.com/LICENSE.md
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title IConnectorRouter
 * @author Souq.Finance
 * @notice Defines the interface of the connector router
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
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

    event CollectionConnectorSet(address indexed liquidityPool, address indexed collectionConnectorAddress, uint indexed tokenID);
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

    function getCollectionConnectorContract(address liquidityPool) external view returns (address);

    function setCollectionConnectorContract(address liquidityPool, address collectionConnectorAddress, uint tokenID) external;

    function deleteCollectionConnectorContract(address liquidityPool) external;

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

interface IExchangeSwapWithInQuote {
    function swap(address _tokenIn, address _tokenOut, uint256 _amountOut, uint256 _amountInMaximum) external returns (uint256 amountOut);
    function getQuoteIn(address _tokenIn, address _tokenOut, uint256 _amountOut) external returns (uint256 amountInMin);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

interface IExchangeSwapWithOutQuote {
    function swap(address _tokenIn, address _tokenOut, uint256 _amountOut, uint256 _amountInMin) external returns (uint256 amountOut);
    function getQuoteOut(address _tokenIn, address _tokenOut, uint256 _amountOut) external returns (uint256 amountOutMin);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

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
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function mint(address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
    function burn(address _account, uint256 _id, uint256 _amount) external;
    function currentTranche() external view returns (uint256);
    function totalSupplyPerTranche(uint256 _tranche) external view returns (uint256);
    function addToTotalSupply(uint256 _tranche, uint256 _totalSupply) external;
    function setTokenTrancheTimestamp(uint256 _tokenId, uint256 _timestamp) external;
    function tokenTranche(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import { VaultDataTypes } from "../libraries/VaultDataTypes.sol";

interface IVault1155 {
    function initialize(address _factory, address _feeReceiver, address _addressesRegistry) external;
    function getCurrentTranche() external view returns (uint256);
    function getTotalQuote(uint256 _numShares, uint256 fee) external returns (uint256[] memory);
    function getTotalQuoteWithVIT(address _VITAddress, uint256 _numShares) external returns (uint256[] memory);
    function mintVaultToken(uint256 _numShares, uint256 _stableAmount, uint256[] calldata _amountPerSwap, VaultDataTypes.LockupPeriod _lockup) external;
    function mintVaultTokenWithVIT(uint256 _numShares, uint256 _stableAmount, uint256[] calldata _amountPerSwap, VaultDataTypes.LockupPeriod _lockup, address _mintVITAddress, uint256 _mintVITAmount) external;
    function setExchangeSwapContract(address _tokenIn, address _tokenOut, address _exchangeSwapAddress) external;
    function changeVITComposition(address[] memory newVITs, uint256[] memory _newAmounts) external;
    function initiateReweight(address[] memory newVITs, uint256[] memory _newAmounts) external;
    function redeemUnderlying(uint256 _numShares, uint256 _tranche) external;
    function getLockupEnd(uint256 _tranche) external view returns (uint256);
    function getTotalUnderlying() external view returns (uint256[] memory);
    function totalUSDCDeposited() external view returns (uint256);
    function getTotalUnderlyingByTranche(uint256 tranche) external view returns (uint256[] memory);
    function vaultData() external view returns (VaultDataTypes.VaultData memory);

    event SvsMinted(address indexed user, uint256 indexed tokenTranche, uint256 indexed numTokens);
    event SvsRedeemed(address indexed user, uint256 indexed tokenTranche, uint256 indexed numTokens);
    event PoolPaused(address admin);
    event PoolUnpaused(address admin);
    function getVITComposition() external view returns(address[] memory VITs, uint256[] memory amounts);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {VaultDataTypes} from "../libraries/VaultDataTypes.sol";

/**
 * @title IVaultBase
 * @author Souq.Finance
 * @notice Interface for VaultBase contract
 */
interface IVaultBase {
    event FeeChanged(VaultDataTypes.VaultFee newFee);
    event VaultDataSet(VaultDataTypes.VaultData newVaultData);

    function setSwapRouter(address _router) external;

    function getHardcap() external view returns (uint256);

    function getUnderlyingTokenAmounts() external view returns (uint256[] memory);

    function getUnderlyingTokens() external view returns (address[] memory);

    function setFee(VaultDataTypes.VaultFee calldata _newFee) external;

    function setVaultData(VaultDataTypes.VaultData calldata _newVaultData) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title library for Data structures
 * @author Souq.Finance
 * @notice Defines the structures used by the contracts of the Souq protocol
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
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
        bool autoSorting;
        uint256 maxMaturityRange;
    }

    struct AMMSubPoolSVSDetails {
        uint256 reserve;
        uint256 totalShares;
        uint256 start;
        uint256 F;
        bool status;
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
        uint256 start;
        //tokenid -> amount
        mapping(uint256 => uint256) shares;
    }
    struct ERC1155Collection {
        address tokenAddress;
        uint256 tokenID;
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
        uint256 minFeeMultiplier;
        uint256 maxFeeMultiplier;
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
        FeeReturn fees;
    }

    struct LiqLocalVars {
        uint256 TVL;
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
    struct VaultSharesReturn {
        uint256 tranche;
        uint256 amount;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {VaultBase} from "../vault/VaultBase.sol";
import {IConnectorRouter} from "../interfaces/IConnectorRouter.sol";
import {IExchangeSwapWithInQuote} from "../interfaces/IExchangeSwapWithInQuote.sol";
import {IExchangeSwapWithOutQuote} from "../interfaces/IExchangeSwapWithOutQuote.sol";
import {IERC20Extended} from "../interfaces/IERC20Extended.sol";
import {ISVS} from "../interfaces/ISVS.sol";
import {VaultDataTypes} from "./VaultDataTypes.sol";

library Vault1155logic {

    event SvsMinted(address indexed user, uint256 indexed tokenTranche, uint256 indexed numTokens, uint256 stableAmount);
    event SvsRedeemed(address indexed user, uint256 indexed tokenTranche, uint256 indexed numTokens);
    event InitiateReweight(address[] VITs, uint256[] newWeights);

    function getTotalQuote(
        IConnectorRouter connectorRouter,
        address stable,
        address[] memory VITs,
        uint256[] memory VITAmounts,
        uint256 _numShares,
        uint256 depositFee
    ) public returns (uint256[] memory) {
        
        uint256[] memory quotes = new uint256[](VITs.length);
        uint256 quote;
        uint8 decimals = IERC20Extended(stable).decimals();
        uint256 scaleFactor = 10**decimals;

        for (uint8 i = 0; i < VITs.length; i++) {
            address swapContract = connectorRouter.getSwapContract(VITs[i]);
            quote = IExchangeSwapWithOutQuote(swapContract).getQuoteOut(
                stable,
                VITs[i],
                VITAmounts[i] * _numShares
            );
            quotes[i] = quote * (scaleFactor + depositFee) / scaleFactor;
        }
        return quotes;
    }

    function getTotalQuoteWithVIT(
        IConnectorRouter connectorRouter,
        address stable, 
        address[] calldata VITs, 
        uint256[] calldata VITAmounts, 
        address VITAddress, 
        uint256 _numShares
    ) external returns (uint256[] memory) {
        uint256[] memory quotes = new uint256[](VITs.length-1);
        uint256 quote;
        for (uint8 i = 0; i < VITs.length; i++) {
            if (VITs[i] == VITAddress) {
                continue;
            }
            address swapContract = connectorRouter.getSwapContract(VITs[i]);   
            quote = IExchangeSwapWithOutQuote(swapContract).getQuoteOut(
                stable,
                VITs[i],
                VITAmounts[i] * _numShares
            );
            quotes[i] = quote;
        }
        return quotes;
    }

    function getTotalUnderlying(address[] memory VITs) external view returns (uint256[] memory totalUnderlying) {
        totalUnderlying = new uint256[](VITs.length);
        for (uint8 i = 0; i < VITs.length; i++) {
            totalUnderlying[i] = IERC20Extended(VITs[i]).balanceOf(address(this));
        }
    }

    function getTotalUnderlyingByTranche(
        address[] memory VITs,
        uint256[] memory VITAmounts,
        address svsToken, 
        uint256 tranche
    ) external view returns (uint256[] memory) {
        uint256[] memory totalUnderlying = new uint256[](VITs.length);  
        for (uint8 i = 0; i < VITs.length; i++) {
            uint256 totalSupply = ISVS(svsToken).totalSupplyPerTranche(tranche);
            totalUnderlying[i] = totalSupply * VITAmounts[i];
        }
        return totalUnderlying;
    }

    function mintVaultToken(address admin, VaultDataTypes.MintParams memory params) external {
        
        uint256 fee = 0;
        uint256 stableBalance = IERC20Extended(params.stable).balanceOf(params.vaultAddress);

        IERC20Extended(params.stable).transferFrom(msg.sender, params.vaultAddress, params.stableAmount);
        
        for (uint8 i = 0; i < params.VITs.length; i++) {
            fee += (params.amountPerSwap[i] * params.depositFee) / 10000;
            exchangeSwap(params, i);
        }

        ISVS(params.svs).mint(msg.sender, params.currentTranche + uint8(params.lockup), params.numShares, "");
        uint256 newStableBalance = IERC20Extended(params.stable).balanceOf(params.vaultAddress);
        require(newStableBalance >= stableBalance + fee, "Not enough stableAmount to pay depositFee"); //<--- this breaks it ???? wtf?
        IERC20Extended(params.stable).transfer(msg.sender, newStableBalance - stableBalance - fee);
        IERC20Extended(params.stable).transfer(admin, fee);
        emit SvsMinted(msg.sender, params.currentTranche, params.numShares, params.stableAmount);

    }

    function mintVaultTokenWithVIT(address admin, VaultDataTypes.MintParams memory params, address mintVITAddress, uint256 mintVITAmount) external {
        uint256 fee = (params.depositFee * params.stableAmount) / 10000;
        
        uint256 stableBalance = IERC20Extended(params.stable).balanceOf(address(this));
        IERC20Extended(params.stable).transferFrom(msg.sender, address(this), params.stableAmount);
        IERC20Extended(mintVITAddress).transferFrom(msg.sender, address(this), mintVITAmount);
        for (uint8 i = 0; i < params.VITs.length; i++) {
            exchangeSwap(params, i);
        }     
        ISVS(params.svs).mint(msg.sender, params.currentTranche + uint8(params.lockup), params.numShares, "");   
        uint256 newStableBalance = IERC20Extended(params.stable).balanceOf(address(this));

        require(newStableBalance - stableBalance >= fee, "Not enough stableAmount to pay depositFee");
        IERC20Extended(params.stable).transfer(msg.sender, newStableBalance - stableBalance - fee);
        IERC20Extended(params.stable).transfer(admin, fee);
        
        emit SvsMinted(msg.sender, params.currentTranche, params.numShares, params.stableAmount);
    }

    function exchangeSwap(VaultDataTypes.MintParams memory params, uint8 i) internal {
        address exchangeSwapContract = IConnectorRouter(params.swapRouter).getSwapContract(params.VITs[i]);
        uint256 computedAmount = params.VITAmounts[i] * params.numShares;            
        IExchangeSwapWithOutQuote(exchangeSwapContract).swap(params.stable, params.VITs[i], params.amountPerSwap[i], computedAmount);
    }

    function redeemUnderlying(
        address admin,
        address sender,
        address svsToken,
        uint256 _numShares,
        uint256 _tranche,
        uint256 lockupEnd,
        address[] memory VITs,
        uint256[] memory VITAmounts,
        uint256 redemptionFee,
        uint256 currentTranche 
    ) external {
        require(block.timestamp > lockupEnd, "Vesting not ended");
        ISVS(svsToken).burn(sender, _tranche, _numShares);

        for(uint8 i = 0; i < VITs.length; i++) {
            uint256 totalAmount = VITAmounts[i] * _numShares;
            uint256 fee = (totalAmount * redemptionFee) / 10000; // Calculate fee in basis points (0.1% when data.fee.redemptionFee is 10)
            uint256 userAmount = totalAmount - fee;
            IERC20Extended(VITs[i]).transfer(sender, userAmount);
            IERC20Extended(VITs[i]).transfer(admin, fee);
        }

        emit SvsRedeemed(sender, currentTranche, _numShares);
    }    

    function initiateReweight(
        address sender, 
        address reweighter, 
        address[] memory _VITs, 
        uint256[] memory _amounts
    ) external {
        require(sender == reweighter, "Only reweighter");

        for(uint8 i = 0; i < _VITs.length; i++) {
            IERC20Extended(_VITs[i]).transferFrom(sender, address(this), _amounts[i]);
        }

        emit InitiateReweight(_VITs, _amounts);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

library VaultErrors {
    string public constant CALLER_NOT_VAULT_ADMIN = "CALLER_IS_NOT_VAULT_ADMIN";
    string public constant CALLER_NOT_VAULT_ADMIN_OR_OPERATIONS = "CALLER_IS_NOT_VAULT_ADMIN_OR_OPERATIONS";
    string public constant ADDRESS_IS_ZERO = "ADDRESS_IS_ZERO";
    string public constant CALLER_NOT_ACCESS_ADMIN = "CALLER_NOT_ACCESS_ADMIN";
    string public constant INVALID_VIT_WEIGHTS = "INVALID_VIT_WEIGHTS";
    string public constant BATCH_REDEEM_DISABLED = "BATCH_REDEEM_DISABLED";
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {VaultBase} from "./VaultBase.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {IConnectorRouter} from "../interfaces/IConnectorRouter.sol";
import {IVault1155} from "../interfaces/IVault1155.sol";
import {Vault1155logic} from "../libraries/Vault1155logic.sol";
import {VaultDataTypes} from "../libraries/VaultDataTypes.sol";
import {ISVS} from "../interfaces/ISVS.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Vault1155 is Initializable, VaultBase, ReentrancyGuardUpgradeable, PausableUpgradeable {

    address internal factory;
    address internal reweighter;
    address internal feeReceiver;    
    //address public svs; 
    uint256 public tranchePeriod;
    uint256 public lastTrancheTime;

    event VITCompositionChanged(address[] VITs, uint256[] newWeights);
    event PoolPaused(address admin);
    event PoolUnpaused(address admin);

    constructor(address _registry) VaultBase (_registry) {

    }

    function initialize(address _factory, address _feeReceiver, address _addressesRegistry) external initializer {
        feeReceiver = _feeReceiver;
        factory = _factory;
        addressesRegistry = _addressesRegistry;
        tranchePeriod = 1 days;
        lastTrancheTime = block.timestamp;        
        __Pausable_init();
    }

    function pause() external onlyVaultAdmin {
        _pause();
        emit PoolPaused(msg.sender);
    }

    function unpause() external onlyVaultAdmin {
        _unpause();
        emit PoolUnpaused(msg.sender);
    }

    function getTotalQuote(uint256 _numShares, uint256 fee) public returns (uint256[] memory) {
        return Vault1155logic.getTotalQuote(IConnectorRouter(swapRouter), vaultData.stable, vaultData.VITs, vaultData.VITAmounts, _numShares, fee);
    }

    function getTotalQuoteWithVIT(address _VITAddress, uint256 _numShares) external returns (uint256[] memory) {
        return Vault1155logic.getTotalQuoteWithVIT(IConnectorRouter(swapRouter), vaultData.stable, vaultData.VITs, vaultData.VITAmounts, _VITAddress, _numShares);
    }

    function mintVaultToken(
        uint256 _numShares, 
        uint256 _stableAmount, 
        uint256[] calldata _amountPerSwap, 
        VaultDataTypes.LockupPeriod _lockup) external nonReentrant whenNotPaused {
        
        calculateTranche();
        
        VaultDataTypes.MintParams memory params = VaultDataTypes.MintParams({
            numShares: _numShares,
            stableAmount: _stableAmount,
            amountPerSwap: _amountPerSwap,
            lockup: _lockup,
            stable: vaultData.stable,
            VITs: vaultData.VITs,
            VITAmounts: vaultData.VITAmounts,
            currentTranche: vaultData.currentTranche,
            swapRouter: swapRouter,
            svs: vaultData.SVS,
            depositFee: vaultData.fee.depositFee,
            vaultAddress: address(this)
        });

        Vault1155logic.mintVaultToken(feeReceiver, params); // <--------- this is throwing

        ISVS(vaultData.SVS).addToTotalSupply(vaultData.currentTranche, _numShares);
    }

    function mintVaultTokenWithVIT(
        uint256 _numShares, 
        uint256 _stableAmount, 
        uint256[] calldata _amountPerSwap, 
        VaultDataTypes.LockupPeriod _lockup, 
        address _mintVITAddress, 
        uint256 _mintVITAmount) external nonReentrant whenNotPaused {
        calculateTranche();
        VaultDataTypes.MintParams memory params = VaultDataTypes.MintParams({
            numShares: _numShares,
            stableAmount: _stableAmount,
            amountPerSwap: _amountPerSwap,
            lockup: _lockup,
            stable: vaultData.stable,
            VITs: vaultData.VITs,
            VITAmounts: vaultData.VITAmounts,
            currentTranche: vaultData.currentTranche,
            swapRouter: swapRouter,
            svs: vaultData.SVS,
            depositFee: vaultData.fee.depositFee,
            vaultAddress: address(this)
        });
        
        Vault1155logic.mintVaultTokenWithVIT(feeReceiver, params, _mintVITAddress, _mintVITAmount);
        ISVS(vaultData.SVS).addToTotalSupply(vaultData.currentTranche, _numShares);
    }

    function calculateTranche() internal {
        uint256 blocktime = block.timestamp;
        uint256 currentMidnight = blocktime - (blocktime % 1 days);
        if(blocktime > lastTrancheTime + tranchePeriod){
            vaultData.currentTranche += vaultData.lockupTimes.length; 
            lastTrancheTime = currentMidnight;
            ISVS(vaultData.SVS).setTokenTrancheTimestamp(vaultData.currentTranche, blocktime);
        }
    }
    
    function approveSwapContract(address _exchangeSwapAddress) external onlyVaultAdmin{
        IERC20(vaultData.stable).approve(_exchangeSwapAddress, 2**256 -1);
    }

    function setReweighter(address _reweighter) external onlyVaultAdmin {
        reweighter = _reweighter;
    }

    function changeVITComposition(address[] memory _newVITs, uint256[] memory _newAmounts) external whenNotPaused{
        require(msg.sender == reweighter, "Only reweighter");
        vaultData.VITs = _newVITs;
        vaultData.VITAmounts = _newAmounts;
        emit VITCompositionChanged(_newVITs, _newAmounts);
    }

    function initiateReweight(address[] memory _VITs, uint256[] memory _amounts) external whenNotPaused {
        Vault1155logic.initiateReweight(
                msg.sender, 
                reweighter, 
                _VITs, 
                _amounts
            ); 
    }

    function redeemUnderlying(uint256 _numShares, uint256 _tranche) nonReentrant whenNotPaused external {
        uint256 lockupEnd = getLockupEnd(_tranche);
        Vault1155logic.redeemUnderlying(
                feeReceiver, 
                msg.sender,
                vaultData.SVS,
                _numShares,
                _tranche,
                lockupEnd,
                vaultData.VITs,
                vaultData.VITAmounts,
                vaultData.fee.redemptionFee,
                vaultData.currentTranche
        );
    }

    function getLockupEnd(uint256 _tranche) public view returns (uint256) {
        return ISVS(vaultData.SVS).tokenTranche(_tranche) + vaultData.lockupTimes[_tranche % vaultData.lockupTimes.length]; 
    }

    function getTotalUnderlying() external view returns (uint256[] memory totalUnderlying) {
        totalUnderlying = Vault1155logic.getTotalUnderlying(vaultData.VITs);
    }

    function getTotalUnderlyingByTranche(uint256 tranche) external view returns (uint256[] memory) {
        return Vault1155logic.getTotalUnderlyingByTranche(
            vaultData.VITs,
            vaultData.VITAmounts,
            vaultData.SVS, 
            tranche
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IVaultBase} from "../interfaces/IVaultBase.sol";
import {VaultErrors} from "../libraries/VaultErrors.sol";
import {VaultDataTypes} from "../libraries/VaultDataTypes.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {IAccessManager} from "../interfaces/IAccessManager.sol";

/**
 * @title VaultBase
 * @author Souq.Finance
 * @notice The Base contract to be inherited by Vaults
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
 */
contract VaultBase is IVaultBase {
    using Math for uint256;

    address public addressesRegistry;
    address public swapRouter;
    VaultDataTypes.VaultData public vaultData;

    /**
     * @dev modifier for when the the msg sender is vault admin in the access manager
     */
    modifier onlyVaultAdmin() {
        require(
            IAccessManager(IAddressesRegistry(addressesRegistry).getAccessManager()).isPoolAdmin(msg.sender),
            VaultErrors.CALLER_NOT_VAULT_ADMIN
        );
        _;
    }

    /**
     * @dev modifier for when the the msg sender is either vault admin or vault operations in the access manager
     */
    modifier onlyVaultAdminOrOperations() {
        require(
            IAccessManager(IAddressesRegistry(addressesRegistry).getAccessManager()).isPoolAdmin(msg.sender) ||
                IAccessManager(IAddressesRegistry(addressesRegistry).getAccessManager()).isPoolOperations(msg.sender),
            VaultErrors.CALLER_NOT_VAULT_ADMIN_OR_OPERATIONS
        );
        _;
    }

    constructor(address _registry) {
        addressesRegistry = _registry;
    }

    function setSwapRouter(address _router) external onlyVaultAdminOrOperations {
        swapRouter = _router;
    }

    function getHardcap() external view returns (uint256) {
        return vaultData.stableHardcap;
    }

    function getUnderlyingTokens() external view returns (address[] memory) {
        return vaultData.VITs;
    }
    
    function getUnderlyingTokenAmounts() external view returns (uint256[] memory) {
        return vaultData.VITAmounts;
    }

    function getLockupTimes() external view returns (uint256[] memory) {
        return vaultData.lockupTimes;
    }

    /// @inheritdoc IVaultBase
    function setFee(VaultDataTypes.VaultFee calldata _newFee) external onlyVaultAdmin {
        vaultData.fee = _newFee;
        emit FeeChanged(_newFee);
    }

    /// @inheritdoc IVaultBase
    function setVaultData(VaultDataTypes.VaultData calldata _newVaultData) external onlyVaultAdmin {
        vaultData = _newVaultData;
        emit VaultDataSet(_newVaultData);
    }
}