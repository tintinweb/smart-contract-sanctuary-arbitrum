// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
import {Initializable} from "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.25;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import "./IAccessControlManagerV8.sol";

/**
 * @title AccessControlledV8
 * @author Venus
 * @notice This contract is helper between access control manager and actual contract. This contract further inherited by other contract (using solidity 0.8.13)
 * to integrate access controlled mechanism. It provides initialise methods and verifying access methods.
 */
abstract contract AccessControlledV8 is Initializable, Ownable2StepUpgradeable {
    /// @notice Access control manager contract
    IAccessControlManagerV8 private _accessControlManager;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    /// @notice Emitted when access control manager contract address is changed
    event NewAccessControlManager(address oldAccessControlManager, address newAccessControlManager);

    /// @notice Thrown when the action is prohibited by AccessControlManager
    error Unauthorized(address sender, address calledContract, string methodSignature);

    function __AccessControlled_init(address accessControlManager_) internal onlyInitializing {
        __Ownable2Step_init();
        __AccessControlled_init_unchained(accessControlManager_);
    }

    function __AccessControlled_init_unchained(address accessControlManager_) internal onlyInitializing {
        _setAccessControlManager(accessControlManager_);
    }

    /**
     * @notice Sets the address of AccessControlManager
     * @dev Admin function to set address of AccessControlManager
     * @param accessControlManager_ The new address of the AccessControlManager
     * @custom:event Emits NewAccessControlManager event
     * @custom:access Only Governance
     */
    function setAccessControlManager(address accessControlManager_) external onlyOwner {
        _setAccessControlManager(accessControlManager_);
    }

    /**
     * @notice Returns the address of the access control manager contract
     */
    function accessControlManager() external view returns (IAccessControlManagerV8) {
        return _accessControlManager;
    }

    /**
     * @dev Internal function to set address of AccessControlManager
     * @param accessControlManager_ The new address of the AccessControlManager
     */
    function _setAccessControlManager(address accessControlManager_) internal {
        require(address(accessControlManager_) != address(0), "invalid acess control manager address");
        address oldAccessControlManager = address(_accessControlManager);
        _accessControlManager = IAccessControlManagerV8(accessControlManager_);
        emit NewAccessControlManager(oldAccessControlManager, accessControlManager_);
    }

    /**
     * @notice Reverts if the call is not allowed by AccessControlManager
     * @param signature Method signature
     */
    function _checkAccessAllowed(string memory signature) internal view {
        bool isAllowedToCall = _accessControlManager.isAllowedToCall(msg.sender, signature);

        if (!isAllowedToCall) {
            revert Unauthorized(msg.sender, address(this), signature);
        }
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title IAccessControlManagerV8
 * @author Venus
 * @notice Interface implemented by the `AccessControlManagerV8` contract.
 */
interface IAccessControlManagerV8 is IAccessControl {
    function giveCallPermission(address contractAddress, string calldata functionSig, address accountToPermit) external;

    function revokeCallPermission(
        address contractAddress,
        string calldata functionSig,
        address accountToRevoke
    ) external;

    function isAllowedToCall(address account, string calldata functionSig) external view returns (bool);

    function hasPermission(
        address account,
        address contractAddress,
        string calldata functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
// SPDX-FileCopyrightText: 2022 Venus
pragma solidity 0.8.25;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/VBep20Interface.sol";
import "./interfaces/OracleInterface.sol";
import "@venusprotocol/governance-contracts/contracts/Governance/AccessControlledV8.sol";

/**
 * @title ResilientOracle
 * @author Venus
 * @notice The Resilient Oracle is the main contract that the protocol uses to fetch prices of assets.
 *
 * DeFi protocols are vulnerable to price oracle failures including oracle manipulation and incorrectly
 * reported prices. If only one oracle is used, this creates a single point of failure and opens a vector
 * for attacking the protocol.
 *
 * The Resilient Oracle uses multiple sources and fallback mechanisms to provide accurate prices and protect
 * the protocol from oracle attacks. Currently it includes integrations with Chainlink, Pyth, Binance Oracle
 * and TWAP (Time-Weighted Average Price) oracles. TWAP uses PancakeSwap as the on-chain price source.
 *
 * For every market (vToken) we configure the main, pivot and fallback oracles. The oracles are configured per
 * vToken's underlying asset address. The main oracle oracle is the most trustworthy price source, the pivot
 * oracle is used as a loose sanity checker and the fallback oracle is used as a backup price source.
 *
 * To validate prices returned from two oracles, we use an upper and lower bound ratio that is set for every
 * market. The upper bound ratio represents the deviation between reported price (the price that’s being
 * validated) and the anchor price (the price we are validating against) above which the reported price will
 * be invalidated. The lower bound ratio presents the deviation between reported price and anchor price below
 * which the reported price will be invalidated. So for oracle price to be considered valid the below statement
 * should be true:

```
anchorRatio = anchorPrice/reporterPrice
isValid = anchorRatio <= upperBoundAnchorRatio && anchorRatio >= lowerBoundAnchorRatio
```

 * In most cases, Chainlink is used as the main oracle, TWAP or Pyth oracles are used as the pivot oracle depending
 * on which supports the given market and Binance oracle is used as the fallback oracle. For some markets we may
 * use Pyth or TWAP as the main oracle if the token price is not supported by Chainlink or Binance oracles.
 *
 * For a fetched price to be valid it must be positive and not stagnant. If the price is invalid then we consider the
 * oracle to be stagnant and treat it like it's disabled.
 */
contract ResilientOracle is PausableUpgradeable, AccessControlledV8, ResilientOracleInterface {
    /**
     * @dev Oracle roles:
     * **main**: The most trustworthy price source
     * **pivot**: Price oracle used as a loose sanity checker
     * **fallback**: The backup source when main oracle price is invalidated
     */
    enum OracleRole {
        MAIN,
        PIVOT,
        FALLBACK
    }

    struct TokenConfig {
        /// @notice asset address
        address asset;
        /// @notice `oracles` stores the oracles based on their role in the following order:
        /// [main, pivot, fallback],
        /// It can be indexed with the corresponding enum OracleRole value
        address[3] oracles;
        /// @notice `enableFlagsForOracles` stores the enabled state
        /// for each oracle in the same order as `oracles`
        bool[3] enableFlagsForOracles;
    }

    uint256 public constant INVALID_PRICE = 0;

    /// @notice Native market address
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable nativeMarket;

    /// @notice VAI address
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable vai;

    /// @notice Set this as asset address for Native token on each chain.
    address public immutable nativeAsset;

    /// @notice Bound validator contract address
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    BoundValidatorInterface public immutable boundValidator;

    mapping(address => TokenConfig) private tokenConfigs;

    event TokenConfigAdded(
        address indexed asset,
        address indexed mainOracle,
        address indexed pivotOracle,
        address fallbackOracle
    );

    /// Event emitted when an oracle is set
    event OracleSet(address indexed asset, address indexed oracle, uint256 indexed role);

    /// Event emitted when an oracle is enabled or disabled
    event OracleEnabled(address indexed asset, uint256 indexed role, bool indexed enable);

    /**
     * @notice Checks whether an address is null or not
     */
    modifier notNullAddress(address someone) {
        if (someone == address(0)) revert("can't be zero address");
        _;
    }

    /**
     * @notice Checks whether token config exists by checking whether asset is null address
     * @dev address can't be null, so it's suitable to be used to check the validity of the config
     * @param asset asset address
     */
    modifier checkTokenConfigExistence(address asset) {
        if (tokenConfigs[asset].asset == address(0)) revert("token config must exist");
        _;
    }

    /// @notice Constructor for the implementation contract. Sets immutable variables.
    /// @dev nativeMarketAddress can be address(0) if on the chain we do not support native market
    ///      (e.g vETH on ethereum would not be supported, only vWETH)
    /// @param nativeMarketAddress The address of a native market (for bsc it would be vBNB address)
    /// @param vaiAddress The address of the VAI token (if there is VAI on the deployed chain).
    ///          Set to address(0) of VAI is not existent.
    /// @param _boundValidator Address of the bound validator contract
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address nativeMarketAddress,
        address nativeAssetAddress,
        address vaiAddress,
        BoundValidatorInterface _boundValidator
    ) notNullAddress(address(_boundValidator)) {
        nativeMarket = nativeMarketAddress;
        nativeAsset = nativeAssetAddress;
        vai = vaiAddress;
        boundValidator = _boundValidator;

        _disableInitializers();
    }

    /**
     * @notice Initializes the contract admin and sets the BoundValidator contract address
     * @param accessControlManager_ Address of the access control manager contract
     */
    function initialize(address accessControlManager_) external initializer {
        __AccessControlled_init(accessControlManager_);
        __Pausable_init();
    }

    /**
     * @notice Pauses oracle
     * @custom:access Only Governance
     */
    function pause() external {
        _checkAccessAllowed("pause()");
        _pause();
    }

    /**
     * @notice Unpauses oracle
     * @custom:access Only Governance
     */
    function unpause() external {
        _checkAccessAllowed("unpause()");
        _unpause();
    }

    /**
     * @notice Batch sets token configs
     * @param tokenConfigs_ Token config array
     * @custom:access Only Governance
     * @custom:error Throws a length error if the length of the token configs array is 0
     */
    function setTokenConfigs(TokenConfig[] memory tokenConfigs_) external {
        if (tokenConfigs_.length == 0) revert("length can't be 0");
        uint256 numTokenConfigs = tokenConfigs_.length;
        for (uint256 i; i < numTokenConfigs; ) {
            setTokenConfig(tokenConfigs_[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Sets oracle for a given asset and role.
     * @dev Supplied asset **must** exist and main oracle may not be null
     * @param asset Asset address
     * @param oracle Oracle address
     * @param role Oracle role
     * @custom:access Only Governance
     * @custom:error Null address error if main-role oracle address is null
     * @custom:error NotNullAddress error is thrown if asset address is null
     * @custom:error TokenConfigExistance error is thrown if token config is not set
     * @custom:event Emits OracleSet event with asset address, oracle address and role of the oracle for the asset
     */
    function setOracle(
        address asset,
        address oracle,
        OracleRole role
    ) external notNullAddress(asset) checkTokenConfigExistence(asset) {
        _checkAccessAllowed("setOracle(address,address,uint8)");
        if (oracle == address(0) && role == OracleRole.MAIN) revert("can't set zero address to main oracle");
        tokenConfigs[asset].oracles[uint256(role)] = oracle;
        emit OracleSet(asset, oracle, uint256(role));
    }

    /**
     * @notice Enables/ disables oracle for the input asset. Token config for the input asset **must** exist
     * @dev Configuration for the asset **must** already exist and the asset cannot be 0 address
     * @param asset Asset address
     * @param role Oracle role
     * @param enable Enabled boolean of the oracle
     * @custom:access Only Governance
     * @custom:error NotNullAddress error is thrown if asset address is null
     * @custom:error TokenConfigExistance error is thrown if token config is not set
     */
    function enableOracle(
        address asset,
        OracleRole role,
        bool enable
    ) external notNullAddress(asset) checkTokenConfigExistence(asset) {
        _checkAccessAllowed("enableOracle(address,uint8,bool)");
        tokenConfigs[asset].enableFlagsForOracles[uint256(role)] = enable;
        emit OracleEnabled(asset, uint256(role), enable);
    }

    /**
     * @notice Updates the TWAP pivot oracle price.
     * @dev This function should always be called before calling getUnderlyingPrice
     * @param vToken vToken address
     */
    function updatePrice(address vToken) external override {
        address asset = _getUnderlyingAsset(vToken);
        (address pivotOracle, bool pivotOracleEnabled) = getOracle(asset, OracleRole.PIVOT);
        if (pivotOracle != address(0) && pivotOracleEnabled) {
            //if pivot oracle is not TwapOracle it will revert so we need to catch the revert
            try TwapInterface(pivotOracle).updateTwap(asset) {} catch {}
        }
    }

    /**
     * @notice Updates the pivot oracle price. Currently using TWAP
     * @dev This function should always be called before calling getPrice
     * @param asset asset address
     */
    function updateAssetPrice(address asset) external {
        (address pivotOracle, bool pivotOracleEnabled) = getOracle(asset, OracleRole.PIVOT);
        if (pivotOracle != address(0) && pivotOracleEnabled) {
            //if pivot oracle is not TwapOracle it will revert so we need to catch the revert
            try TwapInterface(pivotOracle).updateTwap(asset) {} catch {}
        }
    }

    /**
     * @dev Gets token config by asset address
     * @param asset asset address
     * @return tokenConfig Config for the asset
     */
    function getTokenConfig(address asset) external view returns (TokenConfig memory) {
        return tokenConfigs[asset];
    }

    /**
     * @notice Gets price of the underlying asset for a given vToken. Validation flow:
     * - Check if the oracle is paused globally
     * - Validate price from main oracle against pivot oracle
     * - Validate price from fallback oracle against pivot oracle if the first validation failed
     * - Validate price from main oracle against fallback oracle if the second validation failed
     * In the case that the pivot oracle is not available but main price is available and validation is successful,
     * main oracle price is returned.
     * @param vToken vToken address
     * @return price USD price in scaled decimal places.
     * @custom:error Paused error is thrown when resilent oracle is paused
     * @custom:error Invalid resilient oracle price error is thrown if fetched prices from oracle is invalid
     */
    function getUnderlyingPrice(address vToken) external view override returns (uint256) {
        if (paused()) revert("resilient oracle is paused");

        address asset = _getUnderlyingAsset(vToken);
        return _getPrice(asset);
    }

    /**
     * @notice Gets price of the asset
     * @param asset asset address
     * @return price USD price in scaled decimal places.
     * @custom:error Paused error is thrown when resilent oracle is paused
     * @custom:error Invalid resilient oracle price error is thrown if fetched prices from oracle is invalid
     */
    function getPrice(address asset) external view override returns (uint256) {
        if (paused()) revert("resilient oracle is paused");
        return _getPrice(asset);
    }

    /**
     * @notice Sets/resets single token configs.
     * @dev main oracle **must not** be a null address
     * @param tokenConfig Token config struct
     * @custom:access Only Governance
     * @custom:error NotNullAddress is thrown if asset address is null
     * @custom:error NotNullAddress is thrown if main-role oracle address for asset is null
     * @custom:event Emits TokenConfigAdded event when the asset config is set successfully by the authorized account
     */
    function setTokenConfig(
        TokenConfig memory tokenConfig
    ) public notNullAddress(tokenConfig.asset) notNullAddress(tokenConfig.oracles[uint256(OracleRole.MAIN)]) {
        _checkAccessAllowed("setTokenConfig(TokenConfig)");

        tokenConfigs[tokenConfig.asset] = tokenConfig;
        emit TokenConfigAdded(
            tokenConfig.asset,
            tokenConfig.oracles[uint256(OracleRole.MAIN)],
            tokenConfig.oracles[uint256(OracleRole.PIVOT)],
            tokenConfig.oracles[uint256(OracleRole.FALLBACK)]
        );
    }

    /**
     * @notice Gets oracle and enabled status by asset address
     * @param asset asset address
     * @param role Oracle role
     * @return oracle Oracle address based on role
     * @return enabled Enabled flag of the oracle based on token config
     */
    function getOracle(address asset, OracleRole role) public view returns (address oracle, bool enabled) {
        oracle = tokenConfigs[asset].oracles[uint256(role)];
        enabled = tokenConfigs[asset].enableFlagsForOracles[uint256(role)];
    }

    function _getPrice(address asset) internal view returns (uint256) {
        uint256 pivotPrice = INVALID_PRICE;

        // Get pivot oracle price, Invalid price if not available or error
        (address pivotOracle, bool pivotOracleEnabled) = getOracle(asset, OracleRole.PIVOT);
        if (pivotOracleEnabled && pivotOracle != address(0)) {
            try OracleInterface(pivotOracle).getPrice(asset) returns (uint256 pricePivot) {
                pivotPrice = pricePivot;
            } catch {}
        }

        // Compare main price and pivot price, return main price and if validation was successful
        // note: In case pivot oracle is not available but main price is available and
        // validation is successful, the main oracle price is returned.
        (uint256 mainPrice, bool validatedPivotMain) = _getMainOraclePrice(
            asset,
            pivotPrice,
            pivotOracleEnabled && pivotOracle != address(0)
        );
        if (mainPrice != INVALID_PRICE && validatedPivotMain) return mainPrice;

        // Compare fallback and pivot if main oracle comparision fails with pivot
        // Return fallback price when fallback price is validated successfully with pivot oracle
        (uint256 fallbackPrice, bool validatedPivotFallback) = _getFallbackOraclePrice(asset, pivotPrice);
        if (fallbackPrice != INVALID_PRICE && validatedPivotFallback) return fallbackPrice;

        // Lastly compare main price and fallback price
        if (
            mainPrice != INVALID_PRICE &&
            fallbackPrice != INVALID_PRICE &&
            boundValidator.validatePriceWithAnchorPrice(asset, mainPrice, fallbackPrice)
        ) {
            return mainPrice;
        }

        revert("invalid resilient oracle price");
    }

    /**
     * @notice Gets a price for the provided asset
     * @dev This function won't revert when price is 0, because the fallback oracle may still be
     * able to fetch a correct price
     * @param asset asset address
     * @param pivotPrice Pivot oracle price
     * @param pivotEnabled If pivot oracle is not empty and enabled
     * @return price USD price in scaled decimals
     * e.g. asset decimals is 8 then price is returned as 10**18 * 10**(18-8) = 10**28 decimals
     * @return pivotValidated Boolean representing if the validation of main oracle price
     * and pivot oracle price were successful
     * @custom:error Invalid price error is thrown if main oracle fails to fetch price of the asset
     * @custom:error Invalid price error is thrown if main oracle is not enabled or main oracle
     * address is null
     */
    function _getMainOraclePrice(
        address asset,
        uint256 pivotPrice,
        bool pivotEnabled
    ) internal view returns (uint256, bool) {
        (address mainOracle, bool mainOracleEnabled) = getOracle(asset, OracleRole.MAIN);
        if (mainOracleEnabled && mainOracle != address(0)) {
            try OracleInterface(mainOracle).getPrice(asset) returns (uint256 mainOraclePrice) {
                if (!pivotEnabled) {
                    return (mainOraclePrice, true);
                }
                if (pivotPrice == INVALID_PRICE) {
                    return (mainOraclePrice, false);
                }
                return (
                    mainOraclePrice,
                    boundValidator.validatePriceWithAnchorPrice(asset, mainOraclePrice, pivotPrice)
                );
            } catch {
                return (INVALID_PRICE, false);
            }
        }

        return (INVALID_PRICE, false);
    }

    /**
     * @dev This function won't revert when the price is 0 because getPrice checks if price is > 0
     * @param asset asset address
     * @return price USD price in 18 decimals
     * @return pivotValidated Boolean representing if the validation of fallback oracle price
     * and pivot oracle price were successfull
     * @custom:error Invalid price error is thrown if fallback oracle fails to fetch price of the asset
     * @custom:error Invalid price error is thrown if fallback oracle is not enabled or fallback oracle
     * address is null
     */
    function _getFallbackOraclePrice(address asset, uint256 pivotPrice) private view returns (uint256, bool) {
        (address fallbackOracle, bool fallbackEnabled) = getOracle(asset, OracleRole.FALLBACK);
        if (fallbackEnabled && fallbackOracle != address(0)) {
            try OracleInterface(fallbackOracle).getPrice(asset) returns (uint256 fallbackOraclePrice) {
                if (pivotPrice == INVALID_PRICE) {
                    return (fallbackOraclePrice, false);
                }
                return (
                    fallbackOraclePrice,
                    boundValidator.validatePriceWithAnchorPrice(asset, fallbackOraclePrice, pivotPrice)
                );
            } catch {
                return (INVALID_PRICE, false);
            }
        }

        return (INVALID_PRICE, false);
    }

    /**
     * @dev This function returns the underlying asset of a vToken
     * @param vToken vToken address
     * @return asset underlying asset address
     */
    function _getUnderlyingAsset(address vToken) private view notNullAddress(vToken) returns (address asset) {
        if (vToken == nativeMarket) {
            asset = nativeAsset;
        } else if (vToken == vai) {
            asset = vai;
        } else {
            asset = VBep20Interface(vToken).underlying();
        }
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.25;

interface OracleInterface {
    function getPrice(address asset) external view returns (uint256);
}

interface ResilientOracleInterface is OracleInterface {
    function updatePrice(address vToken) external;

    function updateAssetPrice(address asset) external;

    function getUnderlyingPrice(address vToken) external view returns (uint256);
}

interface TwapInterface is OracleInterface {
    function updateTwap(address asset) external returns (uint256);
}

interface BoundValidatorInterface {
    function validatePriceWithAnchorPrice(
        address asset,
        uint256 reporterPrice,
        uint256 anchorPrice
    ) external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface VBep20Interface is IERC20Metadata {
    /**
     * @notice Underlying asset for this VToken
     */
    function underlying() external view returns (address);
}