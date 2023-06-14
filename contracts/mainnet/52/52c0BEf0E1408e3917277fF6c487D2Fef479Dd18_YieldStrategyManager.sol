// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

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
    function acceptOwnership() external {
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @notice An error used to indicate that an argument passed to a function is illegal or
///         inappropriate.
///
/// @param message The error message.
error IllegalArgumentWithReason(string message);

/// @notice An error used to indicate that a function has encountered an unrecoverable state.
///
/// @param message The error message.
error IllegalStateWithReason(string message);

/// @notice An error used to indicate that an operation is unsupported.
///
/// @param message The error message.
error UnsupportedOperationWithReason(string message);

/// @notice An error used to indicate that a message sender tried to execute a privileged function.
///
/// @param message The error message.
error UnauthorizedWithReason(string message);

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @notice An error used to indicate that an action could not be completed because either the `msg.sender` or
///         `msg.origin` is not authorized.
error Unauthorized();

/// @notice An error used to indicate that an action could not be completed because the contract either already existed
///         or entered an illegal condition which is not recoverable from.
error IllegalState();

/// @notice An error used to indicate that an action could not be completed because of an illegal argument was passed
///         to the function.
error IllegalArgument();

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  Mutex
/// @author Savvy DeFi
///
/// @notice Provides a mutual exclusion lock for implementing contracts.
abstract contract Mutex {
    /// @notice An error which is thrown when a lock is attempted to be claimed before it has been freed.
    error LockAlreadyClaimed();

    /// @notice The lock state. Non-zero values indicate the lock has been claimed.
    uint256 private _lockState;

    /// @dev A modifier which acquires the mutex.
    modifier lock() {
        _claimLock();

        _;

        _freeLock();
    }

    /// @dev Gets if the mutex is locked.
    ///
    /// @return if the mutex is locked.
    function _isLocked() internal view returns (bool) {
        return _lockState == 1;
    }

    /// @dev Claims the lock. If the lock is already claimed, then this will revert.
    function _claimLock() internal {
        // Check that the lock has not been claimed yet.
        require(_lockState == 0, "LockAlreadyClaimed");

        // Claim the lock.
        _lockState = 1;
    }

    /// @dev Frees the lock.
    function _freeLock() internal {
        _lockState = 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./IERC20Minimal.sol";

/// @title  IERC20Burnable
/// @author Savvy DeFi
interface IERC20Burnable is IERC20Minimal {
    /// @notice Burns `amount` tokens from the balance of `msg.sender`.
    ///
    /// @param amount The amount of tokens to burn.
    ///
    /// @return If burning the tokens was successful.
    function burn(uint256 amount) external returns (bool);

    /// @notice Burns `amount` tokens from `owner`'s balance.
    ///
    /// @param owner  The address to burn tokens from.
    /// @param amount The amount of tokens to burn.
    ///
    /// @return If burning the tokens was successful.
    function burnFrom(address owner, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  IERC20Metadata
/// @author Savvy DeFi
interface IERC20Metadata {
    /// @notice Gets the name of the token.
    ///
    /// @return The name.
    function name() external view returns (string memory);

    /// @notice Gets the symbol of the token.
    ///
    /// @return The symbol.
    function symbol() external view returns (string memory);

    /// @notice Gets the number of decimals that the token has.
    ///
    /// @return The number of decimals.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  IERC20Minimal
/// @author Savvy DeFi
interface IERC20Minimal {
    /// @notice An event which is emitted when tokens are transferred between two parties.
    ///
    /// @param owner     The owner of the tokens from which the tokens were transferred.
    /// @param recipient The recipient of the tokens to which the tokens were transferred.
    /// @param amount    The amount of tokens which were transferred.
    event Transfer(
        address indexed owner,
        address indexed recipient,
        uint256 amount
    );

    /// @notice An event which is emitted when an approval is made.
    ///
    /// @param owner   The address which made the approval.
    /// @param spender The address which is allowed to transfer tokens on behalf of `owner`.
    /// @param amount  The amount of tokens that `spender` is allowed to transfer.
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice Gets the current total supply of tokens.
    ///
    /// @return The total supply.
    function totalSupply() external view returns (uint256);

    /// @notice Gets the balance of tokens that an account holds.
    ///
    /// @param account The account address.
    ///
    /// @return The balance of the account.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Gets the allowance that an owner has allotted for a spender.
    ///
    /// @param owner   The owner address.
    /// @param spender The spender address.
    ///
    /// @return The number of tokens that `spender` is allowed to transfer on behalf of `owner`.
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /// @notice Transfers `amount` tokens from `msg.sender` to `recipient`.
    ///
    /// @notice Emits a {Transfer} event.
    ///
    /// @param recipient The address which will receive the tokens.
    /// @param amount    The amount of tokens to transfer.
    ///
    /// @return If the transfer was successful.
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Approves `spender` to transfer `amount` tokens on behalf of `msg.sender`.
    ///
    /// @notice Emits a {Approval} event.
    ///
    /// @param spender The address which is allowed to transfer tokens on behalf of `msg.sender`.
    /// @param amount  The amount of tokens that `spender` is allowed to transfer.
    ///
    /// @return If the approval was successful.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `owner` to `recipient` using an approval that `owner` gave to `msg.sender`.
    ///
    /// @notice Emits a {Approval} event.
    /// @notice Emits a {Transfer} event.
    ///
    /// @param owner     The address to transfer tokens from.
    /// @param recipient The address that will receive the tokens.
    /// @param amount    The amount of tokens to transfer.
    ///
    /// @return If the transfer was successful.
    function transferFrom(
        address owner,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./IERC20Minimal.sol";

/// @title  IERC20Mintable
/// @author Savvy DeFi
interface IERC20Mintable is IERC20Minimal {
    /// @notice Mints `amount` tokens to `recipient`.
    ///
    /// @param recipient The address which will receive the minted tokens.
    /// @param amount    The amount of tokens to mint.
    ///
    /// @return If minting the tokens was successful.
    function mint(address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  ITokenAdapter
/// @author Savvy DeFi
interface ITokenAdapter {
    /// @notice Gets the current version.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Gets the address of the yield token that this adapter supports.
    ///
    /// @return The address of the yield token.
    function token() external view returns (address);

    /// @notice Gets the address of the base token that the yield token wraps.
    ///
    /// @return The address of the base token.
    function baseToken() external view returns (address);

    /// @notice Gets the number of base tokens that a single whole yield token is redeemable for.
    ///
    /// @return The price.
    function price() external view returns (uint256);

    /// @notice Wraps `amount` base tokens into the yield token.
    ///
    /// @param amount           The amount of the base token to wrap.
    /// @param recipient        The address which will receive the yield tokens.
    ///
    /// @return amountYieldTokens The amount of yield tokens minted to `recipient`.
    function wrap(
        uint256 amount,
        address recipient
    ) external returns (uint256 amountYieldTokens);

    /// @notice Unwraps `amount` yield tokens into the base token.
    ///
    /// @param amount           The amount of yield-tokens to redeem.
    /// @param recipient        The recipient of the resulting base tokens.
    ///
    /// @return amountBaseTokens The amount of base tokens unwrapped to `recipient`.
    function unwrap(
        uint256 amount,
        address recipient
    ) external returns (uint256 amountBaseTokens);

    /// @notice Add address of SavvyPositionManager to allowlist
    /// @dev Only owner can call this function/
    /// @param allowlistAddresses The addresses of SavvyPositionManager/YieldStrategyManager.
    /// @param status Status for allowlist. true/false = on/off.
    function addAllowlist(
        address[] memory allowlistAddresses,
        bool status
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./savvy/ISavvyTokenParams.sol";
import "./savvy/ISavvyErrors.sol";
import "./savvy/ISavvyEvents.sol";
import "./savvy/ISavvyAdminActions.sol";
import "./savvy/IYieldStrategyManagerStates.sol";
import "./savvy/IYieldStrategyManagerActions.sol";
import "../libraries/Limiters.sol";

/// @title  IYieldStrategyManager
/// @author Savvy DeFi
interface IYieldStrategyManager is
    ISavvyTokenParams,
    ISavvyErrors,
    ISavvyEvents,
    IYieldStrategyManagerStates,
    IYieldStrategyManagerActions
{

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  ISavvyAdminActions
/// @author Savvy DeFi
///
/// @notice Specifies admin and/or sentinel actions.
/// @notice Used by SavvyPositionManager
interface ISavvyAdminActions {
    /// @notice Contract initialization parameters.
    struct InitializationParams {
        // The initial admin account.
        address admin;
        // The ERC20 token used to represent debt.
        address debtToken;
        // The initial savvySage or savvySage buffer.
        address savvySage;
        // The address of giving rewards to users.
        address svyBooster;
        // The address of SavvyPriceFeed contract.
        address svyPriceFeed;
        // The redlist is active.
        bool redlistActive;
        // The address of Redlist contract.
        address savvyRedlist;
        // The address of YieldStrategyManager contract.
        address yieldStrategyManager;
        // The minimum collateralization ratio that an account must maintain.
        uint256 minimumCollateralization;
        // The percentage fee taken from each harvest measured in units of basis points.
        uint256 protocolFee;
        // The address that receives protocol fees.
        address protocolFeeReceiver;
        // A limit used to prevent administrators from making borrowing functionality inoperable.
        uint256 borrowingLimitMinimum;
        // The maximum number of tokens that can be borrowed per period of time.
        uint256 borrowingLimitMaximum;
        // The number of blocks that it takes for the borrowing limit to be refreshed.
        uint256 borrowingLimitBlocks;
        // The address of the allowlist.
        address allowlist;
        // Base base token to calculate token price.
        address baseToken;
        /// The address of WrapTokenGateway contract.
        address wrapTokenGateway;
    }

    /// @notice Configuration parameters for an base token.
    struct BaseTokenConfig {
        // A limit used to prevent administrators from making repayment functionality inoperable.
        uint256 repayLimitMinimum;
        // The maximum number of base tokens that can be repaid per period of time.
        uint256 repayLimitMaximum;
        // The number of blocks that it takes for the repayment limit to be refreshed.
        uint256 repayLimitBlocks;
        // A limit used to prevent administrators from making repayWithCollateral functionality inoperable.
        uint256 repayWithCollateralLimitMinimum;
        // The maximum number of base tokens that can be repaidWithCollateral per period of time.
        uint256 repayWithCollateralLimitMaximum;
        // The number of blocks that it takes for the repayWithCollateral limit to be refreshed.
        uint256 repayWithCollateralLimitBlocks;
    }

    /// @notice Configuration parameters of a yield token.
    struct YieldTokenConfig {
        // The adapter used by the system to interop with the token.
        address adapter;
        // The maximum percent loss in expected value that can occur before certain actions are disabled.
        // Measured in units of basis points.
        uint256 maximumLoss;
        // The maximum value that can be held by the system before certain actions are disabled.
        //  measured in the base token.
        uint256 maximumExpectedValue;
        // The number of blocks that credit will be distributed over to depositors.
        uint256 creditUnlockBlocks;
    }

    /// @notice Initialize the contract.
    ///
    /// @notice `params.protocolFee` must be in range or this call will with an {IllegalArgument} error.
    /// @notice The borrowing growth limiter parameters must be valid or this will revert with an {IllegalArgument} error. For more information, see the {Limiters} library.
    ///
    /// @notice Emits an {AdminUpdated} event.
    /// @notice Emits a {SavvySageUpdated} event.
    /// @notice Emits a {MinimumCollateralizationUpdated} event.
    /// @notice Emits a {ProtocolFeeUpdated} event.
    /// @notice Emits a {ProtocolFeeReceiverUpdated} event.
    /// @notice Emits a {BorrowingLimitUpdated} event.
    ///
    /// @param params The contract initialization parameters.
    function initialize(InitializationParams calldata params) external;

    /// @notice Sets the pending administrator.
    ///
    /// @notice `msg.sender` must be the pending admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {PendingAdminUpdated} event.
    ///
    /// @dev This is the first step in the two-step process of setting a new administrator. After this function is called, the pending administrator will then need to call {acceptAdmin} to complete the process.
    ///
    /// @param value the address to set the pending admin to.
    function setPendingAdmin(address value) external;

    /// @notice Allows for `msg.sender` to accepts the role of administrator.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice The current pending administrator must be non-zero or this call will revert with an {IllegalState} error.
    ///
    /// @dev This is the second step in the two-step process of setting a new administrator. After this function is successfully called, this pending administrator will be reset and the new administrator will be set.
    ///
    /// @notice Emits a {AdminUpdated} event.
    /// @notice Emits a {PendingAdminUpdated} event.
    function acceptAdmin() external;

    /// @notice Sets an address as a sentinel.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param sentinel The address to set or unset as a sentinel.
    /// @param flag     A flag indicating of the address should be set or unset as a sentinel.
    function setSentinel(address sentinel, bool flag) external;

    /// @notice Sets an address as a keeper.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param keeper The address to set or unset as a keeper.
    /// @param flag   A flag indicating of the address should be set or unset as a keeper.
    function setKeeper(address keeper, bool flag) external;

    /// @notice Sets the redlist to active or not.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param flag A flag indicating if the redlist should be active or not.
    function setRedlistActive(bool flag) external;

    /// @notice Sets the requiring protocol token active or not.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param flag A flag indicating if the protocolTokenRequired should be active or not.
    function setProtocolTokenRequiredActive(bool flag) external;

    /// @notice Adds an base token to the system.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param baseToken The address of the base token to add.
    /// @param config          The initial base token configuration.
    function addBaseToken(
        address baseToken,
        BaseTokenConfig calldata config
    ) external;

    /// @notice Adds a yield token to the system.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {AddYieldToken} event.
    /// @notice Emits a {TokenAdapterUpdated} event.
    /// @notice Emits a {MaximumLossUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to add.
    /// @param config     The initial yield token configuration.
    function addYieldToken(
        address yieldToken,
        YieldTokenConfig calldata config
    ) external;

    /// @notice Sets an base token as either enabled or disabled.
    ///
    /// @notice `msg.sender` must be either the admin or a sentinel or this call will revert with an {Unauthorized} error.
    /// @notice `baseToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits an {BaseTokenEnabled} event.
    ///
    /// @param baseToken The address of the base token to enable or disable.
    /// @param enabled         If the base token should be enabled or disabled.
    function setBaseTokenEnabled(address baseToken, bool enabled) external;

    /// @notice Sets a yield token as either enabled or disabled.
    ///
    /// @notice `msg.sender` must be either the admin or a sentinel or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {YieldTokenEnabled} event.
    ///
    /// @param yieldToken The address of the yield token to enable or disable.
    /// @param enabled    If the base token should be enabled or disabled.
    function setYieldTokenEnabled(address yieldToken, bool enabled) external;

    /// @notice Configures the the repay limit of `baseToken`.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `baseToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {ReplayLimitUpdated} event.
    ///
    /// @param baseToken The address of the base token to configure the repay limit of.
    /// @param maximum         The maximum repay limit.
    /// @param blocks          The number of blocks it will take for the maximum repayment limit to be replenished when it is completely exhausted.
    function configureRepayLimit(
        address baseToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Configure the repayWithCollateral limiter of `baseToken`.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `baseToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {RepayWithCollateralLimitUpdated} event.
    ///
    /// @param baseToken The address of the base token to configure the repayWithCollateral limit of.
    /// @param maximum         The maximum repayWithCollateral limit.
    /// @param blocks          The number of blocks it will take for the maximum repayWithCollateral limit to be replenished when it is completely exhausted.
    function configureRepayWithCollateralLimit(
        address baseToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Set the address of the savvySage.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {SavvySageUpdated} event.
    ///
    /// @param savvySage The address of the savvySage.
    function setSavvySage(address savvySage) external;

    /// @notice Set the minimum collateralization ratio.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {MinimumCollateralizationUpdated} event.
    ///
    /// @param value The new minimum collateralization ratio.
    function setMinimumCollateralization(uint256 value) external;

    /// @notice Sets the fee that the protocol will take from harvests.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be in range or this call will with an {IllegalArgument} error.
    ///
    /// @notice Emits a {ProtocolFeeUpdated} event.
    ///
    /// @param value The value to set the protocol fee to measured in basis points.
    function setProtocolFee(uint256 value) external;

    /// @notice Sets the address which will receive protocol fees.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {ProtocolFeeReceiverUpdated} event.
    ///
    /// @param value The address to set the protocol fee receiver to.
    function setProtocolFeeReceiver(address value) external;

    /// @notice Configures the borrowing limiter.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {BorrowingLimitUpdated} event.
    ///
    /// @param maximum The maximum borrowing limit.
    /// @param blocks  The number of blocks it will take for the maximum borrowing limit to be replenished when it is completely exhausted.
    function configureBorrowingLimit(uint256 maximum, uint256 blocks) external;

    /// @notice Sets the rate at which credit will be completely available to depositors after it is harvested.
    ///
    /// @notice Emits a {CreditUnlockRateUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to set the credit unlock rate for.
    /// @param blocks     The number of blocks that it will take before the credit will be unlocked.
    function configureCreditUnlockRate(
        address yieldToken,
        uint256 blocks
    ) external;

    /// @notice Sets the token adapter of a yield token.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice The token that `adapter` supports must be `yieldToken` or this call will revert with a {IllegalState} error.
    ///
    /// @notice Emits a {TokenAdapterUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to set the adapter for.
    /// @param adapter    The address to set the token adapter to.
    function setTokenAdapter(address yieldToken, address adapter) external;

    /// @notice Sets the maximum expected value of a yield token that the system can hold.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @param yieldToken The address of the yield token to set the maximum expected value for.
    /// @param value      The maximum expected value of the yield token denoted measured in its base token.
    function setMaximumExpectedValue(
        address yieldToken,
        uint256 value
    ) external;

    /// @notice Sets the maximum loss that a yield bearing token will permit before restricting certain actions.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @dev There are two types of loss of value for yield bearing tokens: temporary or permanent. The system will automatically restrict actions which are sensitive to both forms of loss when detected. For example, deposits must be restricted when an excessive loss is encountered to prevent users from having their collateral harvested from them. While the user would receive credit, which then could be exchanged for value equal to the collateral that was harvested from them, it is seen as a negative user experience because the value of their collateral should have been higher than what was originally recorded when they made their deposit.
    ///
    /// @param yieldToken The address of the yield bearing token to set the maximum loss for.
    /// @param value      The value to set the maximum loss to. This is in units of basis points.
    function setMaximumLoss(address yieldToken, uint256 value) external;

    /// @notice Snap the expected value `yieldToken` to the current value.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @dev This function should only be used in the event of a loss in the target yield-token. For example, say a third-party protocol experiences a fifty percent loss. The expected value (amount of base tokens) of the yield tokens being held by the system would be two times the real value that those yield tokens could be redeemed for. This function gives governance a way to realize those losses so that users can continue using the token as normal.
    ///
    /// @param yieldToken The address of the yield token to snap.
    function snap(address yieldToken) external;

    /// @notice Sweep all of 'rewardtoken' from the savvy into the admin.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `rewardToken` must not be a yield or base token or this call will revert with a {UnsupportedToken} error.
    ///
    /// @param rewardToken The address of the reward token to snap.
    /// @param amount The amount of 'rewardToken' to sweep to the admin.
    function sweepTokens(address rewardToken, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  ISavvyErrors
/// @author Savvy DeFi
///
/// @notice Specifies errors.
interface ISavvyErrors {
    /// @notice An error which is used to indicate that an operation failed because it tried to operate on a token that the system did not recognize.
    ///
    /// @param token The address of the token.
    error UnsupportedToken(address token);

    /// @notice An error which is used to indicate that an operation failed because it tried to operate on a token that has been disabled.
    ///
    /// @param token The address of the token.
    error TokenDisabled(address token);

    /// @notice An error which is used to indicate that an operation failed because an account became undercollateralized.
    error Undercollateralized();

    /// @notice An error which is used to indicate that an operation failed because the expected value of a yield token in the system exceeds the maximum value permitted.
    ///
    /// @param yieldToken           The address of the yield token.
    /// @param expectedValue        The expected value measured in units of the base token.
    /// @param maximumExpectedValue The maximum expected value permitted measured in units of the base token.
    error ExpectedValueExceeded(
        address yieldToken,
        uint256 expectedValue,
        uint256 maximumExpectedValue
    );

    /// @notice An error which is used to indicate that an operation failed because the loss that a yield token in the system exceeds the maximum value permitted.
    ///
    /// @param yieldToken  The address of the yield token.
    /// @param loss        The amount of loss measured in basis points.
    /// @param maximumLoss The maximum amount of loss permitted measured in basis points.
    error LossExceeded(address yieldToken, uint256 loss, uint256 maximumLoss);

    /// @notice An error which is used to indicate that a borrowing operation failed because the borrowing limit has been exceeded.
    ///
    /// @param amount    The amount of debt tokens that were requested to be borrowed.
    /// @param available The amount of debt tokens which are available to borrow.
    error BorrowingLimitExceeded(uint256 amount, uint256 available);

    /// @notice An error which is used to indicate that an repay operation failed because the repay limit for an base token has been exceeded.
    ///
    /// @param baseToken The address of the base token.
    /// @param amount          The amount of base tokens that were requested to be repaid.
    /// @param available       The amount of base tokens that are available to be repaid.
    error RepayLimitExceeded(
        address baseToken,
        uint256 amount,
        uint256 available
    );

    /// @notice An error which is used to indicate that an repay operation failed because the repayWithCollateral limit for an base token has been exceeded.
    ///
    /// @param baseToken The address of the base token.
    /// @param amount          The amount of base tokens that were requested to be repaidWithCollateral.
    /// @param available       The amount of base tokens that are available to be repaidWithCollateral.
    error RepayWithCollateralLimitExceeded(
        address baseToken,
        uint256 amount,
        uint256 available
    );

    /// @notice An error which is used to indicate that the slippage of a wrap or unwrap operation was exceeded.
    ///
    /// @param amount           The amount of underlying or yield tokens returned by the operation.
    /// @param minimumAmountOut The minimum amount of the underlying or yield token that was expected when performing
    ///                         the operation.
    error SlippageExceeded(uint256 amount, uint256 minimumAmountOut);
}

library Errors {
    // TokenUtils
    string internal constant ERC20CALLFAILED_EXPECTDECIMALS = "SVY101";
    string internal constant ERC20CALLFAILED_SAFEBALANCEOF = "SVY102";
    string internal constant ERC20CALLFAILED_SAFETRANSFER = "SVY103";
    string internal constant ERC20CALLFAILED_SAFEAPPROVE = "SVY104";
    string internal constant ERC20CALLFAILED_SAFETRANSFERFROM = "SVY105";
    string internal constant ERC20CALLFAILED_SAFEMINT = "SVY106";
    string internal constant ERC20CALLFAILED_SAFEBURN = "SVY107";
    string internal constant ERC20CALLFAILED_SAFEBURNFROM = "SVY108";

    // SavvyPositionManager
    string internal constant SPM_FEE_EXCEEDS_BPS = "SVY201"; // protocol fee exceeds BPS
    string internal constant SPM_ZERO_ADMIN_ADDRESS = "SVY202"; // zero pending admin address
    string internal constant SPM_UNAUTHORIZED_PENDING_ADMIN = "SVY203"; // Unauthorized pending admin
    string internal constant SPM_ZERO_SAVVY_SAGE_ADDRESS = "SVY204"; // zero savvy sage address
    string internal constant SPM_ZERO_PROTOCOL_FEE_RECEIVER_ADDRESS = "SVY205"; // zero protocol fee receiver address
    string internal constant SPM_ZERO_RECIPIENT_ADDRESS = "SVY206"; // zero recipient address
    string internal constant SPM_ZERO_TOKEN_AMOUNT = "SVY207"; // zero token amount
    string internal constant SPM_INVALID_DEBT_AMOUNT = "SVY208"; // invalid debt amount
    string internal constant SPM_ZERO_COLLATERAL_AMOUNT = "SVY209"; // zero collateral amount
    string internal constant SPM_INVALID_UNREALIZED_DEBT_AMOUNT = "SVY210"; // invalid unrealized debt amount
    string internal constant SPM_UNAUTHORIZED_ADMIN = "SVY211"; // Unauthorized admin
    string internal constant SPM_UNAUTHORIZED_REDLIST = "SVY212"; // Unauthorized redlist
    string internal constant SPM_UNAUTHORIZED_SENTINEL_OR_ADMIN = "SVY213"; // Unauthorized sentinel or admin
    string internal constant SPM_UNAUTHORIZED_KEEPER = "SVY214"; // Unauthorized keeper
    string internal constant SPM_BORROWING_LIMIT_EXCEEDED = "SVY215"; // Borrowing limit exceeded
    string internal constant SPM_INVALID_TOKEN_AMOUNT = "SVY216"; // invalid token amount
    string internal constant SPM_EXPECTED_VALUE_EXCEEDED = "SVY217"; // Expected Value exceeded
    string internal constant SPM_SLIPPAGE_EXCEEDED = "SVY218"; // Slippage exceeded
    string internal constant SPM_UNDERCOLLATERALIZED = "SVY219"; // Undercollateralized
    string internal constant SPM_UNAUTHORIZED_NOT_ALLOWLISTED = "SVY220"; // Unathorized, not allowlisted
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  ISavvyEvents
/// @author Savvy DeFi
interface ISavvyEvents {
    /// @notice Emitted when the pending admin is updated.
    ///
    /// @param pendingAdmin The address of the pending admin.
    event PendingAdminUpdated(address pendingAdmin);

    /// @notice Emitted when the redlist mode is updated.
    ///
    /// @param flag A flag indicating if the redlist is active.
    event RedlistActiveUpdated(bool flag);

    /// @notice Emitted when the protocolTokenRequire mode is updated.
    ///
    /// @param flag A flag indicating if the protocolTokenRequire is active.
    event ProtocolTokenRequiredActiveUpdated(bool flag);

    /// @notice Emitted when the administrator is updated.
    ///
    /// @param admin The address of the administrator.
    event AdminUpdated(address admin);

    /// @notice Emitted when an address is set or unset as a sentinel.
    ///
    /// @param sentinel The address of the sentinel.
    /// @param flag     A flag indicating if `sentinel` was set or unset as a sentinel.
    event SentinelSet(address sentinel, bool flag);

    /// @notice Emitted when an address is set or unset as a keeper.
    ///
    /// @param sentinel The address of the keeper.
    /// @param flag     A flag indicating if `keeper` was set or unset as a sentinel.
    event KeeperSet(address sentinel, bool flag);

    /// @notice Emitted when an base token is added.
    ///
    /// @param baseToken The address of the base token that was added.
    event AddBaseToken(address indexed baseToken);

    /// @notice Emitted when a yield token is added.
    ///
    /// @param yieldToken The address of the yield token that was added.
    event AddYieldToken(address indexed yieldToken);

    /// @notice Emitted when an base token is enabled or disabled.
    ///
    /// @param baseToken The address of the base token that was enabled or disabled.
    /// @param enabled         A flag indicating if the base token was enabled or disabled.
    event BaseTokenEnabled(address indexed baseToken, bool enabled);

    /// @notice Emitted when an yield token is enabled or disabled.
    ///
    /// @param yieldToken The address of the yield token that was enabled or disabled.
    /// @param enabled    A flag indicating if the yield token was enabled or disabled.
    event YieldTokenEnabled(address indexed yieldToken, bool enabled);

    /// @notice Emitted when the repay limit of an base token is updated.
    ///
    /// @param baseToken The address of the base token.
    /// @param maximum         The updated maximum repay limit.
    /// @param blocks          The updated number of blocks it will take for the maximum repayment limit to be replenished when it is completely exhausted.
    event RepayLimitUpdated(
        address indexed baseToken,
        uint256 maximum,
        uint256 blocks
    );

    /// @notice Emitted when the repayWithCollateral limit of an base token is updated.
    ///
    /// @param baseToken The address of the base token.
    /// @param maximum         The updated maximum repayWithCollateral limit.
    /// @param blocks          The updated number of blocks it will take for the maximum repayWithCollateral limit to be replenished when it is completely exhausted.
    event RepayWithCollateralLimitUpdated(
        address indexed baseToken,
        uint256 maximum,
        uint256 blocks
    );

    /// @notice Emitted when the savvySage is updated.
    ///
    /// @param savvySage The updated address of the savvySage.
    event SavvySageUpdated(address savvySage);

    /// @notice Emitted when the minimum collateralization is updated.
    ///
    /// @param minimumCollateralization The updated minimum collateralization.
    event MinimumCollateralizationUpdated(uint256 minimumCollateralization);

    /// @notice Emitted when the protocol fee is updated.
    ///
    /// @param protocolFee The updated protocol fee.
    event ProtocolFeeUpdated(uint256 protocolFee);

    /// @notice Emitted when the protocol fee receiver is updated.
    ///
    /// @param protocolFeeReceiver The updated address of the protocol fee receiver.
    event ProtocolFeeReceiverUpdated(address protocolFeeReceiver);

    /// @notice Emitted when the borrowing limit is updated.
    ///
    /// @param maximum The updated maximum borrowing limit.
    /// @param blocks  The updated number of blocks it will take for the maximum borrowing limit to be replenished when it is completely exhausted.
    event BorrowingLimitUpdated(uint256 maximum, uint256 blocks);

    /// @notice Emitted when the credit unlock rate is updated.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param blocks     The number of blocks that distributed credit will unlock over.
    event CreditUnlockRateUpdated(address yieldToken, uint256 blocks);

    /// @notice Emitted when the adapter of a yield token is updated.
    ///
    /// @param yieldToken   The address of the yield token.
    /// @param tokenAdapter The updated address of the token adapter.
    event TokenAdapterUpdated(address yieldToken, address tokenAdapter);

    /// @notice Emitted when the maximum expected value of a yield token is updated.
    ///
    /// @param yieldToken           The address of the yield token.
    /// @param maximumExpectedValue The updated maximum expected value.
    event MaximumExpectedValueUpdated(
        address indexed yieldToken,
        uint256 maximumExpectedValue
    );

    /// @notice Emitted when the maximum loss of a yield token is updated.
    ///
    /// @param yieldToken  The address of the yield token.
    /// @param maximumLoss The updated maximum loss.
    event MaximumLossUpdated(address indexed yieldToken, uint256 maximumLoss);

    /// @notice Emitted when the expected value of a yield token is snapped to its current value.
    ///
    /// @param yieldToken    The address of the yield token.
    /// @param expectedValue The updated expected value measured in the yield token's base token.
    event Snap(address indexed yieldToken, uint256 expectedValue);

    /// @notice Emitted when a the admin sweeps all of one reward token from the Savvy
    ///
    /// @param rewardToken The address of the reward token.
    /// @param amount      The amount of 'rewardToken' swept into the admin.
    event SweepTokens(address indexed rewardToken, uint256 amount);

    /// @notice Emitted when `owner` grants `spender` the ability to borrow debt tokens on its behalf.
    ///
    /// @param owner   The address of the account owner.
    /// @param spender The address which is being permitted to borrow tokens on the behalf of `owner`.
    /// @param amount  The amount of debt tokens that `spender` is allowed to borrow.
    event ApproveBorrow(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice Emitted when `owner` grants `spender` the ability to withdraw `yieldToken` from its account.
    ///
    /// @param owner      The address of the account owner.
    /// @param spender    The address which is being permitted to borrow tokens on the behalf of `owner`.
    /// @param yieldToken The address of the yield token that `spender` is allowed to withdraw.
    /// @param amount     The amount of shares of `yieldToken` that `spender` is allowed to withdraw.
    event ApproveWithdraw(
        address indexed owner,
        address indexed spender,
        address indexed yieldToken,
        uint256 amount
    );

    /// @notice Emitted when a user deposits `amount of `yieldToken` to `recipient`.
    ///
    /// @notice This event does not imply that `sender` directly deposited yield tokens. It is possible that the
    ///         base tokens were wrapped.
    ///
    /// @param sender       The address of the user which deposited funds.
    /// @param yieldToken   The address of the yield token that was deposited.
    /// @param amount       The amount of yield tokens that were deposited.
    /// @param recipient    The address that received the deposited funds.
    event DepositYieldToken(
        address indexed sender,
        address indexed yieldToken,
        uint256 amount,
        address recipient
    );

    /// @notice Emitted when `shares` shares of `yieldToken` are burned to withdraw `yieldToken` from the account owned
    ///         by `owner` to `recipient`.
    ///
    /// @notice This event does not imply that `recipient` received yield tokens. It is possible that the yield tokens
    ///         were unwrapped.
    ///
    /// @param owner      The address of the account owner.
    /// @param yieldToken The address of the yield token that was withdrawn.
    /// @param shares     The amount of shares that were burned.
    /// @param recipient  The address that received the withdrawn funds.
    event WithdrawYieldToken(
        address indexed owner,
        address indexed yieldToken,
        uint256 shares,
        address recipient
    );

    /// @notice Emitted when `amount` debt tokens are borrowed to `recipient` using the account owned by `owner`.
    ///
    /// @param owner     The address of the account owner.
    /// @param amount    The amount of tokens that were borrowed.
    /// @param recipient The recipient of the borrowed tokens.
    event Borrow(address indexed owner, uint256 amount, address recipient);

    /// @notice Emitted when `sender` burns `amount` debt tokens to grant credit to `recipient`.
    ///
    /// @param sender    The address which is burning tokens.
    /// @param amount    The amount of tokens that were burned.
    /// @param recipient The address that received credit for the burned tokens.
    event RepayWithDebtToken(
        address indexed sender,
        uint256 amount,
        address recipient
    );

    /// @notice Emitted when `amount` of `baseToken` are repaid to grant credit to `recipient`.
    ///
    /// @param sender          The address which is repaying tokens.
    /// @param baseToken The address of the base token that was used to repay debt.
    /// @param amount          The amount of the base token that was used to repay debt.
    /// @param recipient       The address that received credit for the repaid tokens.
    /// @param credit          The amount of debt that was paid-off to the account owned by owner.
    event RepayWithBaseToken(
        address indexed sender,
        address indexed baseToken,
        uint256 amount,
        address recipient,
        uint256 credit
    );

    /// @notice Emitted when `sender` repayWithCollateral `share` shares of `yieldToken`.
    ///
    /// @param owner           The address of the account owner repaying with collateral.
    /// @param yieldToken      The address of the yield token.
    /// @param baseToken The address of the base token.
    /// @param shares          The amount of the shares of `yieldToken` that were repaidWithCollateral.
    /// @param credit          The amount of debt that was paid-off to the account owned by owner.
    event RepayWithCollateral(
        address indexed owner,
        address indexed yieldToken,
        address indexed baseToken,
        uint256 shares,
        uint256 credit
    );

    /// @notice Emitted when `sender` burns `amount` debt tokens to grant credit to users who have deposited `yieldToken`.
    ///
    /// @param sender     The address which burned debt tokens.
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of debt tokens which were burned.
    event Donate(
        address indexed sender,
        address indexed yieldToken,
        uint256 amount
    );

    /// @notice Emitted when `yieldToken` is harvested.
    ///
    /// @param yieldToken     The address of the yield token that was harvested.
    /// @param minimumAmountOut    The maximum amount of loss that is acceptable when unwrapping the base tokens into yield tokens, measured in basis points.
    /// @param totalHarvested The total amount of base tokens harvested.
    /// @param credit           The total amount of debt repaid to depositors of `yieldToken`.
    event Harvest(
        address indexed yieldToken,
        uint256 minimumAmountOut,
        uint256 totalHarvested,
        uint256 credit
    );

    /// @notice Emitted when the offset as baseToken exceeds to limit.
    ///
    /// @param yieldToken      The address of the yield token that was harvested.
    /// @param currentValue    Current value as baseToken.
    /// @param expectedValue   Limit offset value.
    event HarvestExceedsOffset(
        address indexed yieldToken,
        uint256 currentValue,
        uint256 expectedValue
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  ISavvyTokenParams
/// @author Savvy DeFi
interface ISavvyTokenParams {
    /// @notice Defines base token parameters.
    struct BaseTokenParams {
        // A coefficient used to normalize the token to a value comparable to the debt token. For example, if the
        // base token is 8 decimals and the debt token is 18 decimals then the conversion factor will be
        // 10^10. One unit of the base token will be comparably equal to one unit of the debt token.
        uint256 conversionFactor;
        // The number of decimals the token has. This value is cached once upon registering the token so it is important
        // that the decimals of the token are immutable or the system will begin to have computation errors.
        uint8 decimals;
        // A flag to indicate if the token is enabled.
        bool enabled;
    }

    /// @notice Defines yield token parameters.
    struct YieldTokenParams {
        // The maximum percentage loss that is acceptable before disabling certain actions.
        uint256 maximumLoss;
        // The maximum value of yield tokens that the system can hold, measured in units of the base token.
        uint256 maximumExpectedValue;
        // The percent of credit that will be unlocked per block. The representation of this value is a 18  decimal
        // fixed point integer.
        uint256 creditUnlockRate;
        // The current balance of yield tokens which are held by users.
        uint256 activeBalance;
        // The current balance of yield tokens which are earmarked to be harvested by the system at a later time.
        uint256 harvestableBalance;
        // The total number of shares that have been borrowed for this token.
        uint256 totalShares;
        // The expected value of the tokens measured in base tokens. This value controls how much of the token
        // can be harvested. When users deposit yield tokens, it increases the expected value by how much the tokens
        // are exchangeable for in the base token. When users withdraw yield tokens, it decreases the expected
        // value by how much the tokens are exchangeable for in the base token.
        uint256 expectedValue;
        // The current amount of credit which is will be distributed over time to depositors.
        uint256 pendingCredit;
        // The amount of the pending credit that has been distributed.
        uint256 distributedCredit;
        // The block number which the last credit distribution occurred.
        uint256 lastDistributionBlock;
        // The total accrued weight. This is used to calculate how much credit a user has been granted over time. The
        // representation of this value is a 18 decimal fixed point integer.
        uint256 accruedWeight;
        // The associated base token that can be redeemed for the yield-token.
        address baseToken;
        // The adapter used by the system to wrap, unwrap, and lookup the conversion rate of this token into its
        // base token.
        address adapter;
        // The number of decimals the token has. This value is cached once upon registering the token so it is important
        // that the decimals of the token are immutable or the system will begin to have computation errors.
        uint8 decimals;
        // A flag to indicate if the token is enabled.
        bool enabled;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../libraries/Limiters.sol";
import "./ISavvyAdminActions.sol";
import "./ISavvyTokenParams.sol";

/// @title  IYieldStrategyManagerActions
/// @author Savvy DeFi
interface IYieldStrategyManagerActions is ISavvyTokenParams {
    /// @dev Unwraps `amount` of `yieldToken` into its base token.
    ///
    /// @param yieldToken       The address of the yield token to unwrap.
    /// @param amount           The amount of the yield token to wrap.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be received from the
    ///                         operation.
    ///
    /// @return The amount of base tokens that resulted from the operation.
    function unwrap(
        address yieldToken,
        uint256 amount,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256);

    /// @notice Burns `amount` debt tokens to credit accounts which have deposited `yieldToken`.
    ///
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {Donate} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 amtRepayWithCollateral = 5000;
    /// @notice SavvyPositionManager(savvyAddress).repayWithCollateral(dai, amtRepayWithCollateral, 1);
    /// @notice ```
    ///
    /// @param yieldToken The address of the yield token to credit accounts for.
    /// @param amount     The amount of debt tokens to burn.
    /// @param shares     The amount of share left in savvy.
    function donate(
        address yieldToken,
        uint256 amount,
        uint256 shares
    ) external returns (uint256);

    /// @notice Harvests outstanding yield that a yield token has accumulated and distributes it as credit to holders.
    ///
    /// @notice `msg.sender` must be a keeper or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice The amount being harvested must be greater than zero or else this call will revert with an {IllegalState} error.
    ///
    /// @notice Emits a {Harvest} event.
    ///
    /// @param yieldToken       The address of the yield token to harvest.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be withdrawn to `recipient`.
    /// @param protocolFee      The rate of protocol fee.
    /// @return baseToken           The address of base token.
    /// @return amountBaseTokens    The amount of base token.
    /// @return feeAmount           The amount of protocol fee.
    /// @return distributeAmount    The amount of distribute
    /// @return credit              The amount of debt.
    function harvest(
        address yieldToken,
        uint256 minimumAmountOut,
        uint256 protocolFee
    )
        external
        returns (
            address baseToken,
            uint256 amountBaseTokens,
            uint256 feeAmount,
            uint256 distributeAmount,
            uint256 credit
        );

    /// @notice Synchronizes the active balance and expected value of `yieldToken`.
    /// @param yieldToken       The address of yield token.
    /// @param amount           The amount to add or subtract from the debt.
    /// @param addOperation     Present for add or sub.
    /// @return                 The config of yield token.
    function syncYieldToken(
        address yieldToken,
        uint256 amount,
        bool addOperation
    ) external returns (YieldTokenParams memory);

    /// @dev Burns `share` shares of `yieldToken` from the account owned by `owner`.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param shares     The amount of shares to burn.
    function burnShares(address yieldToken, uint256 shares) external;

    /// @dev Issues shares of `yieldToken` for `amount` of its base token to `recipient`.
    ///
    /// IMPORTANT: `amount` must never be 0.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of yield token.
    /// @return shares    The amount of shars.
    function issueSharesForAmount(
        address yieldToken,
        uint256 amount
    ) external returns (uint256 shares);

    /// @notice Update repay limiters and returns debt amount and actual amount of base token.
    /// @param baseToken The address of base token.
    /// @return Return debt amount same worth as `amount` of base token.
    /// @return Return actual amount of base token for repay debt.
    function repayWithBaseToken(
        address baseToken,
        uint256 amount,
        int256 debt
    ) external view returns (uint256, uint256);

    /// @notice Check if had condition to do repayWithCollateral.
    /// @notice checkSupportedYieldToken(), checkTokenEnabled(), checkLoss()
    /// @param yieldToken The address of yield token.
    /// @return baseToken The address of base token.
    function repayWithCollateralCheck(
        address yieldToken
    ) external view returns (address baseToken);

    /// @dev Distributes unlocked credit of `yieldToken` to all depositors.
    ///
    /// @param yieldToken The address of the yield token to distribute unlocked credit for.
    function distributeUnlockedCredit(address yieldToken) external;

    /// @dev Preemptively harvests `yieldToken`.
    ///
    /// @dev This will earmark yield tokens to be harvested at a future time when the current value of the token is
    ///      greater than the expected value. The purpose of this function is to synchronize the balance of the yield
    ///      token which is held by users versus tokens which will be seized by the protocol.
    ///
    /// @param yieldToken The address of the yield token to preemptively harvest.
    function preemptivelyHarvest(address yieldToken) external;

    /// @notice Snap the expected value `yieldToken` to the current value.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @dev This function should only be used in the event of a loss in the target yield-token. For example, say a third-party protocol experiences a fifty percent loss. The expected value (amount of base tokens) of the yield tokens being held by the system would be two times the real value that those yield tokens could be redeemed for. This function gives governance a way to realize those losses so that users can continue using the token as normal.
    ///
    /// @param yieldToken The address of the yield token to snap.
    function snap(address yieldToken) external returns (uint256);

    /// @notice Do pre actions for deposit.
    /// @notice checkTokenEnabled(), checkLoss(), preemptivelyHarvest()
    /// @param yieldToken The address of yield token.
    /// @return yieldTokenParam The config of yield token.
    function depositPrepare(
        address yieldToken
    )
        external
        returns (YieldTokenParams memory yieldTokenParam);

    /// @notice `shares` will be limited up to an equal amount of debt that `recipient` currently holds.
    /// @dev Explain to a developer any extra details
    /// @param yieldToken       The address of the yield token to repayWithCollateral.
    /// @param recipient        The address of user that will derease debt.
    /// @param shares           The number of shares to burn for credit.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be repaidWithCollateral.
    /// @param unrealizedDebt   The amount of the debt unrealized.
    /// @return The amount of base token.
    /// @return The amount of yield token.
    /// @return The amount of shares that used actually to decrease debt.
    function repayWithCollateral(
        address yieldToken,
        address recipient,
        uint256 shares,
        uint256 minimumAmountOut,
        int256 unrealizedDebt
    ) external returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../libraries/Limiters.sol";
import "./ISavvyAdminActions.sol";
import "./ISavvyTokenParams.sol";

/// @title  IYieldStrategyManagerState
/// @author Savvy DeFi
interface IYieldStrategyManagerStates is ISavvyTokenParams {
    /// @notice Configures the the repay limit of `baseToken`.
    /// @param baseToken The address of the base token to configure the repay limit of.
    /// @param maximum         The maximum repay limit.
    /// @param blocks          The number of blocks it will take for the maximum repayment limit to be replenished when it is completely exhausted.
    function configureRepayLimit(
        address baseToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Configure the repayWithCollateral limiter of `baseToken`.
    /// @param baseToken The address of the base token to configure the repayWithCollateral limit of.
    /// @param maximum         The maximum repayWithCollateral limit.
    /// @param blocks          The number of blocks it will take for the maximum repayWithCollateral limit to be replenished when it is completely exhausted.
    function configureRepayWithCollateralLimit(
        address baseToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Configures the borrowing limiter.
    ///
    /// @param maximum The maximum borrowing limit.
    /// @param rate  The number of blocks it will take for the maximum borrowing limit to be replenished when it is completely exhausted.
    function configureBorrowingLimit(uint256 maximum, uint256 rate) external;

    /// @notice Sets the rate at which credit will be completely available to depositors after it is harvested.
    /// @param yieldToken The address of the yield token to set the credit unlock rate for.
    /// @param blocks     The number of blocks that it will take before the credit will be unlocked.
    function configureCreditUnlockRate(
        address yieldToken,
        uint256 blocks
    ) external;

    /// @notice Sets the maximum expected value of a yield token that the system can hold.
    ///
    /// @param yieldToken The address of the yield token to set the maximum expected value for.
    /// @param value      The maximum expected value of the yield token denoted measured in its base token.
    function setMaximumExpectedValue(
        address yieldToken,
        uint256 value
    ) external;

    /// @notice Sets the maximum loss that a yield bearing token will permit before restricting certain actions.
    /// @param yieldToken The address of the yield bearing token to set the maximum loss for.
    /// @param value      The value to set the maximum loss to. This is in units of basis points.
    function setMaximumLoss(address yieldToken, uint256 value) external;

    /// @notice Sets the token adapter of a yield token.
    /// @param yieldToken The address of the yield token to set the adapter for.
    /// @param adapter    The address to set the token adapter to.
    function setTokenAdapter(address yieldToken, address adapter) external;

    /// @notice Set the borrowing limiter.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {BorrowingLimitUpdated} event.
    ///
    /// @param borrowingLimiter Limit information for borrowing.
    function setBorrowingLimiter(
        Limiters.LinearGrowthLimiter calldata borrowingLimiter
    ) external;

    /// @notice Set savvyPositionManager address.
    /// @dev Only owner can call this function.
    /// @param savvyPositionManager The address of savvyPositionManager.
    function setSavvyPositionManager(address savvyPositionManager) external;

    /// @notice Gets the conversion rate of base tokens per share.
    ///
    /// @param yieldToken The address of the yield token to get the conversion rate for.
    ///
    /// @return rate The rate of base tokens per share.
    function getBaseTokensPerShare(
        address yieldToken
    ) external view returns (uint256 rate);

    /// @notice Gets the conversion rate of yield tokens per share.
    ///
    /// @param yieldToken The address of the yield token to get the conversion rate for.
    ///
    /// @return rate The rate of yield tokens per share.
    function getYieldTokensPerShare(
        address yieldToken
    ) external view returns (uint256 rate);

    /// @notice Gets the supported base tokens.
    ///
    /// @dev The order of the entries returned by this function is not guaranteed to be consistent between calls.
    ///
    /// @return tokens The supported base tokens.
    function getSupportedBaseTokens()
        external
        view
        returns (address[] memory tokens);

    /// @notice Gets the supported yield tokens.
    ///
    /// @dev The order of the entries returned by this function is not guaranteed to be consistent between calls.
    ///
    /// @return tokens The supported yield tokens.
    function getSupportedYieldTokens()
        external
        view
        returns (address[] memory tokens);

    /// @notice Gets if an base token is supported.
    ///
    /// @param baseToken The address of the base token to check.
    ///
    /// @return isSupported If the base token is supported.
    function isSupportedBaseToken(
        address baseToken
    ) external view returns (bool isSupported);

    /// @notice Gets if a yield token is supported.
    ///
    /// @param yieldToken The address of the yield token to check.
    ///
    /// @return isSupported If the yield token is supported.
    function isSupportedYieldToken(
        address yieldToken
    ) external view returns (bool isSupported);

    /// @notice Gets the parameters of an base token.
    ///
    /// @param baseToken The address of the base token.
    ///
    /// @return params The base token parameters.
    function getBaseTokenParameters(
        address baseToken
    ) external view returns (BaseTokenParams memory params);

    /// @notice Get the parameters and state of a yield-token.
    ///
    /// @param yieldToken The address of the yield token.
    ///
    /// @return params The yield token parameters.
    function getYieldTokenParameters(
        address yieldToken
    ) external view returns (YieldTokenParams memory params);

    /// @notice Gets current limit, maximum, and rate of the borrowing limiter.
    ///
    /// @return currentLimit The current amount of debt tokens that can be borrowed.
    /// @return rate         The maximum possible amount of tokens that can be repaidWithCollateral at a time.
    /// @return maximum      The highest possible maximum amount of debt tokens that can be borrowed at a time.
    function getBorrowLimitInfo()
        external
        view
        returns (uint256 currentLimit, uint256 rate, uint256 maximum);

    /// @notice Gets current limit, maximum, and rate of a repay limiter for `baseToken`.
    ///
    /// @param baseToken The address of the base token.
    ///
    /// @return currentLimit The current amount of base tokens that can be repaid.
    /// @return rate         The rate at which the the current limit increases back to its maximum in tokens per block.
    /// @return maximum      The maximum possible amount of tokens that can be repaid at a time.
    function getRepayLimitInfo(
        address baseToken
    )
        external
        view
        returns (uint256 currentLimit, uint256 rate, uint256 maximum);

    /// @notice Gets current limit, maximum, and rate of the repayWithCollateral limiter for `baseToken`.
    ///
    /// @param baseToken The address of the base token.
    ///
    /// @return currentLimit The current amount of base tokens that can be repaid with Collateral.
    /// @return rate         The rate at which the function increases back to its maximum limit (tokens / block).
    /// @return maximum      The highest possible maximum amount of debt tokens that can be repaidWithCollateral at a time.
    function getRepayWithCollateralLimitInfo(
        address baseToken
    )
        external
        view
        returns (uint256 currentLimit, uint256 rate, uint256 maximum);

    /// @dev Gets the amount of shares that `amount` of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of yield tokens.
    ///
    /// @return The number of shares.
    function convertYieldTokensToShares(
        address yieldToken,
        uint256 amount
    ) external view returns (uint256);

    /// @dev Gets the amount of shares of `yieldToken` that `amount` of its base token is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of base tokens.
    ///
    /// @return The amount of shares.
    function convertBaseTokensToShares(
        address yieldToken,
        uint256 amount
    ) external view returns (uint256);

    /// @dev Gets the amount of yield tokens that `shares` shares of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param shares     The amount of shares.
    ///
    /// @return The amount of yield tokens.
    function convertSharesToYieldTokens(
        address yieldToken,
        uint256 shares
    ) external view returns (uint256);

    /// @dev Gets the amount of an base token that `amount` of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of yield tokens.
    ///
    /// @return The amount of base tokens.
    function convertYieldTokensToBaseToken(
        address yieldToken,
        uint256 amount
    ) external view returns (uint256);

    /// @dev Gets the amount of `yieldToken` that `amount` of its base token is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of base tokens.
    ///
    /// @return The amount of yield tokens.
    function convertBaseTokensToYieldToken(
        address yieldToken,
        uint256 amount
    ) external view returns (uint256);

    /// @dev Gets the amount of base tokens that `shares` shares of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param shares     The amount of shares.
    ///
    /// @return baseToken           The address of base token.
    /// @return amountBaseTokens    The amount of base tokens.
    function convertSharesToBaseTokens(
        address yieldToken,
        uint256 shares
    ) external view returns (address baseToken, uint256 amountBaseTokens);

    /// @dev Calculates the amount of unlocked credit for `yieldToken` that is available for distribution.
    ///
    /// @param yieldToken The address of the yield token.
    ///
    /// @return currentAccruedWeight The current total accrued weight.
    /// @return unlockedCredit The amount of unlocked credit available.
    function calculateUnlockedCredit(
        address yieldToken
    )
        external
        view
        returns (uint256 currentAccruedWeight, uint256 unlockedCredit);

    /// @dev Gets the virtual active balance of `yieldToken`.
    ///
    /// @dev The virtual active balance is the active balance minus any harvestable tokens which have yet to be realized.
    ///
    /// @param yieldToken The address of the yield token to get the virtual active balance of.
    ///
    /// @return The virtual active balance.
    function calculateUnrealizedActiveBalance(
        address yieldToken
    ) external view returns (uint256);

    /// @notice Check token is supported by Savvy.
    /// @dev The token should not be yield token or base token that savvy contains.
    /// @dev If token is yield token or base token, reverts UnsupportedToken.
    /// @param rewardToken The address of token to check.
    function checkSupportTokens(address rewardToken) external view;

    /// @dev Checks if an address is a supported yield token.
    /// If the address is not a supported yield token, this function will revert using a {UnsupportedToken} error.
    /// @param yieldToken The address to check.
    function checkSupportedYieldToken(address yieldToken) external view;

    /// @dev Checks if an address is a supported base token.
    ///
    /// If the address is not a supported yield token, this function will revert using a {UnsupportedToken} error.
    ///
    /// @param baseToken The address to check.
    function checkSupportedBaseToken(address baseToken) external view;

    /// @notice Get repay limit information of baseToken.
    /// @param baseToken The address of base token.
    /// @return Repay limit information of baseToken.
    function repayLimiters(
        address baseToken
    ) external view returns (Limiters.LinearGrowthLimiter memory);

    /// @notice Get currnet borrow limit information.
    /// @return Current borrowing limit information.
    function currentBorrowingLimiter() external view returns (uint256);

    /// @notice Get current repay limit information of baseToken.
    /// @param baseToken The address of base token.
    /// @return Current repay limit information of baseToken.
    function currentRepayWithBaseTokenLimit(
        address baseToken
    ) external view returns (uint256);

    /// @notice Get current repayWithCollateral limit information of baseToken.
    /// @param baseToken The address of base token.
    /// @return Current repayWithCollateral limit information of baseToken.
    function currentRepayWithCollateralLimit(
        address baseToken
    ) external view returns (uint256);

    /// @notice Get repayWithCollateral limit information of baseToken.
    /// @param baseToken The address of base token.
    /// @return RepayWithCollateral limit information of baseToken.
    function repayWithCollateralLimiters(
        address baseToken
    ) external view returns (Limiters.LinearGrowthLimiter memory);

    /// @notice Get yield token parameter of yield token.
    /// @param yieldToken The address of yield token.
    /// @return The parameter of yield token.
    function getYieldTokenParams(
        address yieldToken
    ) external view returns (YieldTokenParams memory);

    /// @notice Check yield token loss is exceeds max loss.
    /// @dev If it's exceeds to max loss, revert `LossExceed(yieldToken, currentLoss, maximumLoss)`.
    /// @param yieldToken The address of yield token.
    function checkLoss(address yieldToken) external view;

    /// @notice Adds an base token to the system.
    /// @param debtToken The address of debt Token.
    /// @param baseToken The address of the base token to add.
    /// @param config          The initial base token configuration.
    function addBaseToken(
        address debtToken,
        address baseToken,
        ISavvyAdminActions.BaseTokenConfig calldata config
    ) external;

    /// @notice Adds a yield token to the system.
    /// @param yieldToken The address of the yield token to add.
    /// @param config     The initial yield token configuration.
    function addYieldToken(
        address yieldToken,
        ISavvyAdminActions.YieldTokenConfig calldata config
    ) external;

    /// @notice Sets an base token as either enabled or disabled.
    /// @param baseToken The address of the base token to enable or disable.
    /// @param enabled         If the base token should be enabled or disabled.
    function setBaseTokenEnabled(address baseToken, bool enabled) external;

    /// @notice Sets a yield token as either enabled or disabled.
    /// @param yieldToken The address of the yield token to enable or disable.
    /// @param enabled    If the base token should be enabled or disabled.
    function setYieldTokenEnabled(address yieldToken, bool enabled) external;

    /// @notice Get base token parameter of base token.
    /// @param baseToken The address of base token.
    /// @return The parameter of base token.
    function getBaseTokenParams(
        address baseToken
    ) external view returns (BaseTokenParams memory);

    /// @notice Get borrow limit information.
    /// @return Borrowing limit information.
    function borrowingLimiter()
        external
        view
        returns (Limiters.LinearGrowthLimiter memory);

    /// @notice Decrease borrowing limiter.
    /// @param amount The amount of borrowing to decrease.
    function decreaseBorrowingLimiter(uint256 amount) external;

    /// @notice Increase borrowing limiter.
    /// @param amount The amount of borrowing to increase.
    function increaseBorrowingLimiter(uint256 amount) external;

    /// @notice Decrease repayWithCollateral limiter.
    /// @param amount The amount of repayWithCollateral to decrease.
    function decreaseRepayWithCollateralLimiter(
        address baseToken,
        uint256 amount
    ) external;

    /// @notice Decrease base token repay limiter.
    /// @param amount The amount of base token repay to decrease.
    function decreaseRepayWithBaseTokenLimiter(
        address baseToken,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../base/ErrorMessages.sol";

// a library for validating conditions.

library Checker {
    /// @dev Checks an expression and reverts with an {IllegalArgument} error if the expression is {false}.
    ///
    /// @param expression The expression to check.
    /// @param message The error message to display if the check fails.
    function checkArgument(
        bool expression,
        string memory message
    ) internal pure {
        require(expression, message);
    }

    /// @dev Checks an expression and reverts with an {IllegalState} error if the expression is {false}.
    ///
    /// @param expression The expression to check.
    /// @param message The error message to display if the check fails.
    function checkState(bool expression, string memory message) internal pure {
        require(expression, message);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IllegalArgument} from "../base/Errors.sol";
import "./Checker.sol";

/// @title  Functions
/// @author Savvy DeFi
library Limiters {
    using Limiters for LinearGrowthLimiter;

    /// @dev A maximum cooldown to avoid malicious governance bricking the contract.
    /// @dev 1 day @ 12 sec / block
    uint256 public constant MAX_COOLDOWN_BLOCKS = 7200;

    /// @dev The scalar used to convert integral types to fixed point numbers.
    uint256 public constant FIXED_POINT_SCALAR = 1e18;

    /// @dev The configuration and state of a linear growth function (LGF).
    struct LinearGrowthLimiter {
        uint256 maximum; /// The maximum limit of the function.
        uint256 rate; /// The rate at which the function increases back to its maximum.
        uint256 lastValue; /// The most recently saved value of the function.
        uint256 lastBlock; /// The block that `lastValue` was recorded.
        uint256 minLimit; /// A minimum limit to avoid malicious governance bricking the contract
    }

    /// @dev Instantiates a new linear growth function.
    ///
    /// @param maximum The maximum value for the LGF.
    /// @param blocks  The number of blocks that determins the rate of the LGF.
    ///
    /// @return The LGF struct.
    function createLinearGrowthLimiter(
        uint256 maximum,
        uint256 blocks,
        uint256 _minLimit
    ) internal view returns (LinearGrowthLimiter memory) {
        Checker.checkArgument(blocks <= MAX_COOLDOWN_BLOCKS, "invalid blocks");
        Checker.checkArgument(maximum >= _minLimit, "invalid minLimit");

        return
            LinearGrowthLimiter({
                maximum: maximum,
                rate: (maximum * FIXED_POINT_SCALAR) / blocks,
                lastValue: maximum,
                lastBlock: block.number,
                minLimit: _minLimit
            });
    }

    /// @dev Configure an LGF.
    ///
    /// @param self    The LGF to configure.
    /// @param maximum The maximum value of the LFG.
    /// @param blocks  The number of recovery blocks of the LGF.
    function configure(
        LinearGrowthLimiter storage self,
        uint256 maximum,
        uint256 blocks
    ) internal {
        Checker.checkArgument(blocks <= MAX_COOLDOWN_BLOCKS, "invalid blocks");
        Checker.checkArgument(maximum >= self.minLimit, "invalid minLimit");

        if (self.lastValue > maximum) {
            self.lastValue = maximum;
        }

        self.maximum = maximum;
        self.rate = (maximum * FIXED_POINT_SCALAR) / blocks;
    }

    /// @dev Updates the state of an LGF by updating `lastValue` and `lastBlock`.
    ///
    /// @param self the LGF to update.
    function update(LinearGrowthLimiter storage self) internal {
        self.lastValue = self.get();
        self.lastBlock = block.number;
    }

    /// @dev Increase the value of the linear growth limiter.
    ///
    /// @param self   The linear growth limiter.
    /// @param amount The amount to decrease `lastValue`.
    function increase(
        LinearGrowthLimiter storage self,
        uint256 amount
    ) internal {
        uint256 value = self.get();
        self.lastValue = value + amount;
        self.lastBlock = block.number;
    }

    /// @dev Decrease the value of the linear growth limiter.
    ///
    /// @param self   The linear growth limiter.
    /// @param amount The amount to decrease `lastValue`.
    function decrease(
        LinearGrowthLimiter storage self,
        uint256 amount
    ) internal {
        uint256 value = self.get();
        self.lastValue = value - amount;
        self.lastBlock = block.number;
    }

    /// @dev Get the current value of the linear growth limiter.
    ///
    /// @return The current value.
    function get(
        LinearGrowthLimiter storage self
    ) internal view returns (uint256) {
        uint256 elapsed = block.number - self.lastBlock;
        if (elapsed == 0) {
            return self.lastValue;
        }
        uint256 delta = (elapsed * self.rate) / FIXED_POINT_SCALAR;
        uint256 value = self.lastValue + delta;
        return value > self.maximum ? self.maximum : value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

// a library for performing various math operations

library Math {
    uint256 public constant WAD = 1e18;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y >> (1 + 1);
            while (x < z) {
                z = x;
                x = (y / x + x) >> 1;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD >> 1)) / WAD;
    }

    function uoperation(
        uint256 x,
        uint256 y,
        bool addOperation
    ) internal pure returns (uint256 z) {
        if (addOperation) {
            return uadd(x, y);
        } else {
            return usub(x, y);
        }
    }

    /// @dev Subtracts two unsigned 256 bit integers together and returns the result.
    ///
    /// @dev This operation is checked and will fail if the result overflows.
    ///
    /// @param x The first operand.
    /// @param y The second operand.
    ///
    /// @return z the result.
    function usub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x < y) {
            return 0;
        }
        z = x - y;
    }

    /// @dev Adds two unsigned 256 bit integers together and returns the result.
    ///
    /// @dev This operation is checked and will fail if the result overflows.
    ///
    /// @param x The first operand.
    /// @param y The second operand.
    ///
    /// @return z The result.
    function uadd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    /// @notice Return minimum uint256 value.
    /// @param x The first operand.
    /// @param y The second operand.
    /// @return z The result
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? y : x;
    }

    /// @notice Return maximum uint256 value.
    /// @param x The first operand.
    /// @param y The second operand.
    /// @return z The result
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    /**
     * @dev Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        if (a > (type(uint256).max - halfRAY) / b) {
            return 0;
        }

        return (a * b + halfRAY) / RAY;
    }

    /**
     * @dev Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            return 0;
        }
        uint256 halfB = b / 2;

        if (a > (type(uint256).max - halfB) / RAY) {
            return 0;
        }

        return (a * RAY + halfB) / b;
    }

    /// @notice utility function to find weighted averages without any underflows or zero division problems.
    /// @dev use x to determine weights, with y being the values you're weighting
    /// @param valueToAdd new allotment amount
    /// @param currentValue current allotment amount
    /// @param weightToAdd new amount of y being added to weighted average
    /// @param currentWeight current weighted average of y
    /// @return Update duration
    function findWeightedAverage(
        uint256 valueToAdd,
        uint256 currentValue,
        uint256 weightToAdd,
        uint256 currentWeight
    ) internal pure returns (uint256) {
        uint256 totalWeight = weightToAdd + currentWeight;
        if (totalWeight == 0) {
            return 0;
        }
        uint256 totalValue = (valueToAdd * weightToAdd) +
            (currentValue * currentWeight);
        return totalValue / totalWeight;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  Sets
/// @author Savvy DeFi
library Sets {
    using Sets for AddressSet;

    /// @notice A data structure holding an array of values with an index mapping for O(1) lookup.
    struct AddressSet {
        address[] values;
        mapping(address => uint256) indexes;
    }

    /// @dev Add a value to a Set
    ///
    /// @param self  The Set.
    /// @param value The value to add.
    ///
    /// @return Whether the operation was successful (unsuccessful if the value is already contained in the Set)
    function add(
        AddressSet storage self,
        address value
    ) internal returns (bool) {
        if (self.contains(value)) {
            return false;
        }
        self.values.push(value);
        self.indexes[value] = self.values.length;
        return true;
    }

    /// @dev Remove a value from a Set
    ///
    /// @param self  The Set.
    /// @param value The value to remove.
    ///
    /// @return Whether the operation was successful (unsuccessful if the value was not contained in the Set)
    function remove(
        AddressSet storage self,
        address value
    ) internal returns (bool) {
        uint256 index = self.indexes[value];
        if (index == 0) {
            return false;
        }

        // Normalize the index since we know that the element is in the set.
        index--;

        uint256 lastIndex = self.values.length - 1;

        if (index != lastIndex) {
            address lastValue = self.values[lastIndex];
            self.values[index] = lastValue;
            self.indexes[lastValue] = index + 1;
        }

        self.values.pop();

        delete self.indexes[value];

        return true;
    }

    /// @dev Returns true if the value exists in the Set
    ///
    /// @param self  The Set.
    /// @param value The value to check.
    ///
    /// @return True if the value is contained in the Set, False if it is not.
    function contains(
        AddressSet storage self,
        address value
    ) internal view returns (bool) {
        return self.indexes[value] != 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../interfaces/savvy/ISavvyErrors.sol";
import "../interfaces/IERC20Burnable.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IERC20Minimal.sol";
import "../interfaces/IERC20Mintable.sol";

/// @title  TokenUtils
/// @author Savvy DeFi
library TokenUtils {
    /// @dev A safe function to get the decimals of an ERC20 token.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
    ///
    /// @param token The target token.
    ///
    /// @return The amount of decimals of the token.
    function expectDecimals(address token) internal view returns (uint8) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );

        require(success, Errors.ERC20CALLFAILED_EXPECTDECIMALS);

        return abi.decode(data, (uint8));
    }

    /// @dev Gets the balance of tokens held by an account.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
    ///
    /// @param token   The token to check the balance of.
    /// @param account The address of the token holder.
    ///
    /// @return The balance of the tokens held by an account.
    function safeBalanceOf(
        address token,
        address account
    ) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, account)
        );
        require(success, Errors.ERC20CALLFAILED_SAFEBALANCEOF);

        return abi.decode(data, (uint256));
    }

    /// @dev Transfers tokens to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer failed or returns an unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransfer(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC20Minimal.transfer.selector,
                recipient,
                amount
            )
        );

        require(success, Errors.ERC20CALLFAILED_SAFETRANSFER);
    }

    /// @dev Approves tokens for the smart contract.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the approval fails or returns an unexpected value.
    ///
    /// @param token   The token to approve.
    /// @param spender The contract to spend the tokens.
    /// @param value   The amount of tokens to approve.
    function safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC20Minimal.approve.selector,
                spender,
                value
            )
        );

        require(success, Errors.ERC20CALLFAILED_SAFEAPPROVE);
    }

    /// @dev Transfer tokens from one address to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer fails or returns an unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param owner     The address of the owner.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransferFrom(
        address token,
        address owner,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 balanceBefore = IERC20Minimal(token).balanceOf(recipient);
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC20Minimal.transferFrom.selector,
                owner,
                recipient,
                amount
            )
        );
        uint256 balanceAfter = IERC20Minimal(token).balanceOf(recipient);

        require(success, Errors.ERC20CALLFAILED_SAFETRANSFERFROM);

        return (balanceAfter - balanceBefore);
    }

    /// @dev Mints tokens to an address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the mint fails or returns an unexpected value.
    ///
    /// @param token     The token to mint.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to mint.
    function safeMint(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC20Mintable.mint.selector,
                recipient,
                amount
            )
        );

        require(success, Errors.ERC20CALLFAILED_SAFEMINT);
    }

    /// @dev Burns tokens.
    ///
    /// Reverts with a `CallFailed` error if execution of the burn fails or returns an unexpected value.
    ///
    /// @param token  The token to burn.
    /// @param amount The amount of tokens to burn.
    function safeBurn(address token, uint256 amount) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(IERC20Burnable.burn.selector, amount)
        );

        require(success, Errors.ERC20CALLFAILED_SAFEBURN);
    }

    /// @dev Burns tokens from its total supply.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the burn fails or returns an unexpected value.
    ///
    /// @param token  The token to burn.
    /// @param owner  The owner of the tokens.
    /// @param amount The amount of tokens to burn.
    function safeBurnFrom(
        address token,
        address owner,
        uint256 amount
    ) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC20Burnable.burnFrom.selector,
                owner,
                amount
            )
        );

        require(success, Errors.ERC20CALLFAILED_SAFEBURNFROM);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {Unauthorized, IllegalState, IllegalArgument} from "./base/Errors.sol";
import "./interfaces/IYieldStrategyManager.sol";
import "./interfaces/ITokenAdapter.sol";

import "./libraries/Sets.sol";
import "./libraries/Checker.sol";
import "./libraries/TokenUtils.sol";
import "./libraries/Math.sol";

import "./base/Mutex.sol";

contract YieldStrategyManager is
    IYieldStrategyManager,
    Mutex,
    Ownable2StepUpgradeable
{
    using Limiters for Limiters.LinearGrowthLimiter;
    using Sets for Sets.AddressSet;

    /// @notice The number of basis points there are to represent exactly 100%.
    uint256 public constant BPS = 10000;

    /// @notice The scalar used for conversion of integral numbers to fixed point numbers. Fixed point numbers in this
    ///         implementation have 18 decimals of resolution, meaning that 1 is represented as 1e18, 0.5 is
    ///         represented as 5e17, and 2 is represented as 2e18.
    uint256 public constant FIXED_POINT_SCALAR = 1e18;

    /// @dev Base token parameters mapped by token address.
    mapping(address => BaseTokenParams) private _baseTokens;

    /// @dev yield token parameters mapped by token address.
    mapping(address => YieldTokenParams) private _yieldTokens;

    /// @dev A linear growth function that limits the amount of debt-token borrowed.
    Limiters.LinearGrowthLimiter private _borrowingLimiter;

    // @dev The repay limiters for each base token.
    mapping(address => Limiters.LinearGrowthLimiter) private _repayLimiters;

    // @dev The repayWithCollateral limiters for each base token.
    mapping(address => Limiters.LinearGrowthLimiter)
        private _repayWithCollateralLimiters;

    /// @dev An iterable set of the base tokens that are supported by the system.
    Sets.AddressSet private _supportedBaseTokens;

    /// @dev An iterable set of the yield tokens that are supported by the system.
    Sets.AddressSet private _supportedYieldTokens;

    /// @dev The address of SavvyPositionManager.
    address public savvyPositionManager;

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    modifier onlySavvyPositionManager() {
        require(msg.sender == savvyPositionManager, "Unauthorized");
        _;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function setSavvyPositionManager(
        address savvyPositionManager_
    ) external onlyOwner {
        savvyPositionManager = savvyPositionManager_;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function getBaseTokensPerShare(
        address yieldToken
    ) external view returns (uint256) {
        (, uint256 baseTokenAmount) = convertSharesToBaseTokens(
            yieldToken,
            FIXED_POINT_SCALAR
        );
        return baseTokenAmount;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function getYieldTokensPerShare(
        address yieldToken
    ) external view returns (uint256) {
        return convertSharesToYieldTokens(yieldToken, FIXED_POINT_SCALAR);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function getSupportedBaseTokens() external view returns (address[] memory) {
        return _supportedBaseTokens.values;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function getSupportedYieldTokens()
        external
        view
        returns (address[] memory)
    {
        return _supportedYieldTokens.values;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function isSupportedBaseToken(
        address baseToken
    ) external view returns (bool) {
        return _supportedBaseTokens.contains(baseToken);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function isSupportedYieldToken(
        address yieldToken
    ) external view returns (bool) {
        return _supportedYieldTokens.contains(yieldToken);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function getBaseTokenParameters(
        address baseToken
    ) external view returns (BaseTokenParams memory) {
        return _baseTokens[baseToken];
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function getYieldTokenParameters(
        address yieldToken
    ) external view returns (YieldTokenParams memory) {
        return _yieldTokens[yieldToken];
    }

    function borrowingLimiter()
        external
        view
        returns (Limiters.LinearGrowthLimiter memory)
    {
        return _borrowingLimiter;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function getBorrowLimitInfo()
        external
        view
        returns (uint256 currentLimit, uint256 rate, uint256 maximum)
    {
        return (
            _borrowingLimiter.get(),
            _borrowingLimiter.rate,
            _borrowingLimiter.maximum
        );
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function getRepayLimitInfo(
        address baseToken
    )
        external
        view
        returns (uint256 currentLimit, uint256 rate, uint256 maximum)
    {
        Limiters.LinearGrowthLimiter storage limiter = _repayLimiters[
            baseToken
        ];
        return (limiter.get(), limiter.rate, limiter.maximum);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function getRepayWithCollateralLimitInfo(
        address baseToken
    )
        external
        view
        returns (uint256 currentLimit, uint256 rate, uint256 maximum)
    {
        Limiters.LinearGrowthLimiter
            storage limiter = _repayWithCollateralLimiters[baseToken];
        return (limiter.get(), limiter.rate, limiter.maximum);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function decreaseBorrowingLimiter(
        uint256 amount
    ) external onlySavvyPositionManager {
        _borrowingLimiter.decrease(amount);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function increaseBorrowingLimiter(
        uint256 amount
    ) external onlySavvyPositionManager {
        _borrowingLimiter.increase(amount);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function decreaseRepayWithCollateralLimiter(
        address baseToken,
        uint256 amount
    ) external onlySavvyPositionManager {
        _repayWithCollateralLimiters[baseToken].decrease(amount);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function decreaseRepayWithBaseTokenLimiter(
        address baseToken,
        uint256 amount
    ) external onlySavvyPositionManager {
        _repayLimiters[baseToken].decrease(amount);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function addBaseToken(
        address debtToken,
        address baseToken,
        ISavvyAdminActions.BaseTokenConfig calldata config
    ) external onlySavvyPositionManager {
        Checker.checkState(
            !_supportedBaseTokens.contains(baseToken),
            "same base token already exists"
        );

        uint8 tokenDecimals = TokenUtils.expectDecimals(baseToken);
        uint8 debtTokenDecimals = TokenUtils.expectDecimals(debtToken);

        Checker.checkArgument(
            tokenDecimals < 19 && tokenDecimals < debtTokenDecimals + 1,
            "invalid token decimals"
        );

        _baseTokens[baseToken] = BaseTokenParams({
            decimals: tokenDecimals,
            conversionFactor: 10 ** (debtTokenDecimals - tokenDecimals),
            enabled: false
        });

        _repayLimiters[baseToken] = Limiters.createLinearGrowthLimiter(
            config.repayLimitMaximum,
            config.repayLimitBlocks,
            config.repayLimitMinimum
        );

        _repayWithCollateralLimiters[baseToken] = Limiters
            .createLinearGrowthLimiter(
                config.repayWithCollateralLimitMaximum,
                config.repayWithCollateralLimitBlocks,
                config.repayWithCollateralLimitMinimum
            );

        _supportedBaseTokens.add(baseToken);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function addYieldToken(
        address yieldToken,
        ISavvyAdminActions.YieldTokenConfig calldata config
    ) external onlySavvyPositionManager {
        Checker.checkArgument(
            config.maximumLoss < BPS + 1,
            "invalid maximumLoss"
        );
        Checker.checkArgument(
            config.creditUnlockBlocks > 0,
            "invalid creditUnlockBlocks"
        );

        Checker.checkState(
            !_supportedYieldTokens.contains(yieldToken),
            "same yield token already exists"
        );

        ITokenAdapter adapter = ITokenAdapter(config.adapter);

        Checker.checkState(
            yieldToken == adapter.token(),
            "invalid yield token address"
        );
        _checkSupportedBaseToken(adapter.baseToken());

        uint8 yieldTokenDecimals = TokenUtils.expectDecimals(yieldToken);
        Checker.checkArgument(
            yieldTokenDecimals < 19,
            "invalid token decimals"
        );

        _yieldTokens[yieldToken] = YieldTokenParams({
            decimals: yieldTokenDecimals,
            baseToken: adapter.baseToken(),
            adapter: config.adapter,
            maximumLoss: config.maximumLoss,
            maximumExpectedValue: config.maximumExpectedValue,
            creditUnlockRate: FIXED_POINT_SCALAR / config.creditUnlockBlocks,
            activeBalance: 0,
            harvestableBalance: 0,
            totalShares: 0,
            expectedValue: 0,
            accruedWeight: 0,
            pendingCredit: 0,
            distributedCredit: 0,
            lastDistributionBlock: 0,
            enabled: false
        });

        _supportedYieldTokens.add(yieldToken);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function setBaseTokenEnabled(
        address baseToken,
        bool enabled
    ) external onlySavvyPositionManager {
        _checkSupportedBaseToken(baseToken);
        _baseTokens[baseToken].enabled = enabled;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function setYieldTokenEnabled(
        address yieldToken,
        bool enabled
    ) external onlySavvyPositionManager {
        _checkSupportedYieldToken(yieldToken);
        _yieldTokens[yieldToken].enabled = enabled;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function configureRepayLimit(
        address baseToken,
        uint256 maximum,
        uint256 blocks
    ) external onlySavvyPositionManager {
        _checkSupportedBaseToken(baseToken);
        _repayLimiters[baseToken].update();
        _repayLimiters[baseToken].configure(maximum, blocks);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function configureRepayWithCollateralLimit(
        address baseToken,
        uint256 maximum,
        uint256 blocks
    ) external onlySavvyPositionManager {
        _checkSupportedBaseToken(baseToken);
        _repayWithCollateralLimiters[baseToken].update();
        _repayWithCollateralLimiters[baseToken].configure(maximum, blocks);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function configureBorrowingLimit(
        uint256 maximum,
        uint256 blocks
    ) external onlySavvyPositionManager {
        _borrowingLimiter.update();
        _borrowingLimiter.configure(maximum, blocks);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function configureCreditUnlockRate(
        address yieldToken,
        uint256 blocks
    ) external onlySavvyPositionManager {
        Checker.checkArgument(blocks > 0, "zero blocks");
        _checkSupportedYieldToken(yieldToken);
        _yieldTokens[yieldToken].creditUnlockRate = FIXED_POINT_SCALAR / blocks;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function setTokenAdapter(
        address yieldToken,
        address adapter
    ) external onlySavvyPositionManager {
        address oldAdapter = _yieldTokens[yieldToken].adapter;
        Checker.checkState(
            yieldToken == ITokenAdapter(adapter).token(),
            "invalid yield token address"
        );
        Checker.checkState(
            ITokenAdapter(oldAdapter).baseToken() ==
                ITokenAdapter(adapter).baseToken(),
            "invalid base token address"
        );
        _checkSupportedYieldToken(yieldToken);

        TokenUtils.safeApprove(yieldToken, oldAdapter, 0);
        TokenUtils.safeApprove(
            ITokenAdapter(oldAdapter).baseToken(),
            oldAdapter,
            0
        );

        TokenUtils.safeApprove(yieldToken, adapter, type(uint256).max);
        TokenUtils.safeApprove(
            ITokenAdapter(adapter).baseToken(),
            adapter,
            type(uint256).max
        );

        _yieldTokens[yieldToken].adapter = adapter;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function setMaximumExpectedValue(
        address yieldToken,
        uint256 value
    ) external onlySavvyPositionManager {
        _checkSupportedYieldToken(yieldToken);
        _yieldTokens[yieldToken].maximumExpectedValue = value;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function setMaximumLoss(
        address yieldToken,
        uint256 value
    ) external onlySavvyPositionManager {
        Checker.checkArgument(value < BPS + 1, "invalid maximumLoss");
        _checkSupportedYieldToken(yieldToken);

        _yieldTokens[yieldToken].maximumLoss = value;
    }

    /// @inheritdoc IYieldStrategyManagerActions
    function distributeUnlockedCredit(
        address yieldToken
    ) external onlySavvyPositionManager {
        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];

        (, uint256 unlockedCredit) = calculateUnlockedCredit(yieldToken);
        if (unlockedCredit == 0) {
            return;
        }

        yieldTokenParams.accruedWeight +=
            (unlockedCredit * FIXED_POINT_SCALAR) /
            yieldTokenParams.totalShares;
        yieldTokenParams.distributedCredit += unlockedCredit;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function convertYieldTokensToShares(
        address yieldToken,
        uint256 amount
    ) public view returns (uint256) {
        YieldTokenParams memory yieldTokenParams = _yieldTokens[yieldToken];
        if (yieldTokenParams.totalShares == 0) {
            return amount * _getYieldTokenFixedPoint(yieldToken);
        }

        return
            (amount * yieldTokenParams.totalShares) /
            calculateUnrealizedActiveBalance(yieldToken);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function convertBaseTokensToShares(
        address yieldToken,
        uint256 amount
    ) public view returns (uint256) {
        uint256 amountYieldTokens = convertBaseTokensToYieldToken(
            yieldToken,
            amount
        );
        return convertYieldTokensToShares(yieldToken, amountYieldTokens);
    }

    /// @inheritdoc IYieldStrategyManagerActions
    function snap(
        address yieldToken
    ) external onlySavvyPositionManager returns (uint256) {
        _checkSupportedYieldToken(yieldToken);

        uint256 expectedValue = convertYieldTokensToBaseToken(
            yieldToken,
            _yieldTokens[yieldToken].activeBalance
        );

        _yieldTokens[yieldToken].expectedValue = expectedValue;

        return expectedValue;
    }

    /// @inheritdoc IYieldStrategyManagerActions
    function preemptivelyHarvest(
        address yieldToken
    ) public onlySavvyPositionManager {
        YieldTokenParams memory _yieldToken = _yieldTokens[yieldToken];
        uint256 activeBalance = _yieldToken.activeBalance;
        if (activeBalance == 0) {
            return;
        }

        uint256 currentValue = convertYieldTokensToBaseToken(
            yieldToken,
            activeBalance
        );
        uint256 expectedValue = _yieldToken.expectedValue;
        if (currentValue < expectedValue + 1) {
            emit HarvestExceedsOffset(yieldToken, currentValue, expectedValue);
            return;
        }

        uint256 harvestable = convertBaseTokensToYieldToken(
            yieldToken,
            currentValue - expectedValue
        );
        if (harvestable == 0) {
            return;
        }
        _preemptivelyHarvest(yieldToken, harvestable);
    }

    /// @inheritdoc IYieldStrategyManagerActions
    function donate(
        address yieldToken,
        uint256 amount,
        uint256 shares
    ) external onlySavvyPositionManager returns (uint256) {
        return (_yieldTokens[yieldToken].accruedWeight +=
            (amount * FIXED_POINT_SCALAR) /
            shares);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function checkSupportTokens(address rewardToken) external view {
        require(
            !_supportedYieldTokens.contains(rewardToken) &&
                !_supportedBaseTokens.contains(rewardToken),
            "UnsupportedToken"
        );
    }

    /// @inheritdoc IYieldStrategyManagerActions
    function repayWithBaseToken(
        address baseToken,
        uint256 amount,
        int256 debt
    ) external view onlySavvyPositionManager returns (uint256, uint256) {
        // Determine the maximum amount of base tokens that can be repaid.
        //
        // It is implied that this value is greater than zero because `debt` is greater than zero so a noop is not possible
        // beyond this point. Casting the debt to an unsigned integer is also safe because `debt` is greater than zero.
        uint256 maximumAmount = _normalizeDebtTokensToUnderlying(
            baseToken,
            uint256(debt)
        );

        // Limit the number of base tokens to repay up to the maximum allowed.
        uint256 actualAmount = amount > maximumAmount ? maximumAmount : amount;

        // Check to make sure that the base token repay limit has not been breached.
        uint256 _currentRepayWithBaseTokenLimit = _repayLimiters[baseToken]
            .get();
        require(
            actualAmount <= _currentRepayWithBaseTokenLimit,
            "RepayLimitExceeded"
        );

        uint256 credit = _normalizeBaseTokensToDebt(baseToken, actualAmount);

        return (credit, actualAmount);
    }

    /// @inheritdoc IYieldStrategyManagerActions
    function unwrap(
        address yieldToken,
        uint256 amount,
        address recipient,
        uint256 minimumAmountOut
    ) public onlySavvyPositionManager returns (uint256) {
        YieldTokenParams memory yieldTokenParams = _yieldTokens[yieldToken];
        ITokenAdapter adapter = ITokenAdapter(yieldTokenParams.adapter);
        TokenUtils.safeApprove(yieldToken, address(adapter), amount);
        uint256 amountUnwrapped = adapter.unwrap(amount, recipient);
        require(amountUnwrapped >= minimumAmountOut, "SlippageExceeded");
        return amountUnwrapped;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function checkLoss(address yieldToken) public view {
        uint256 loss = _loss(yieldToken);
        YieldTokenParams memory _yieldToken = _yieldTokens[yieldToken];
        uint256 maximumLoss = _yieldToken.maximumLoss;
        require(loss <= maximumLoss, "LossExceeded");
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function repayLimiters(
        address baseToken
    ) external view returns (Limiters.LinearGrowthLimiter memory) {
        return _repayLimiters[baseToken];
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function repayWithCollateralLimiters(
        address baseToken
    ) external view returns (Limiters.LinearGrowthLimiter memory) {
        return _repayWithCollateralLimiters[baseToken];
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function getYieldTokenParams(
        address yieldToken
    ) public view returns (YieldTokenParams memory) {
        return _yieldTokens[yieldToken];
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function getBaseTokenParams(
        address baseToken
    ) external view returns (BaseTokenParams memory) {
        return _baseTokens[baseToken];
    }

    /// @inheritdoc IYieldStrategyManagerActions
    function repayWithCollateral(
        address yieldToken,
        address recipient,
        uint256 shares,
        uint256 minimumAmountOut,
        int256 unrealizedDebt
    ) external onlySavvyPositionManager returns (uint256, uint256, uint256) {
        address baseToken = _yieldTokens[yieldToken].baseToken;
        // Determine the maximum amount of shares that can be repaidWithCollateral from the unrealized debt.
        //
        // It is implied that this value is greater than zero because `debt` is greater than zero. Casting the debt to an
        // unsigned integer is also safe for this reason.
        uint256 maximumShares = convertBaseTokensToShares(
            yieldToken,
            _normalizeDebtTokensToUnderlying(baseToken, uint256(unrealizedDebt))
        );

        // Limit the number of shares to repayWithCollateral up to the maximum allowed.
        uint256 actualShares = shares > maximumShares ? maximumShares : shares;

        // Unwrap the yield tokens that the shares are worth.
        uint256 amountYieldTokens = convertSharesToYieldTokens(
            yieldToken,
            actualShares
        );
        amountYieldTokens = TokenUtils.safeTransferFrom(
            yieldToken,
            msg.sender,
            address(this),
            amountYieldTokens
        );
        uint256 amountBaseTokens = unwrap(
            yieldToken,
            amountYieldTokens,
            recipient,
            minimumAmountOut
        );

        // Again, perform another noop check. It is possible that the amount of base tokens that were received by
        // unwrapping the yield tokens was zero because the amount of yield tokens to unwrap was too small.
        Checker.checkState(amountBaseTokens > 0, "zero base token amount");

        // Check to make sure that the base token repayWithCollateral limit has not been breached.
        uint256 repayWithCollateralLimit = _repayWithCollateralLimiters[
            baseToken
        ].get();
        require(
            amountBaseTokens <= repayWithCollateralLimit,
            "RepayWithCollateralLimitExceeded"
        );

        // Buffers any harvestable yield tokens. This will properly synchronize the balance which is held by users
        // and the balance which is held by the system. This is required for `_sync` to function correctly.
        preemptivelyHarvest(yieldToken);

        return (amountBaseTokens, amountYieldTokens, actualShares);
    }

    /// @inheritdoc IYieldStrategyManagerActions
    function harvest(
        address yieldToken,
        uint256 minimumAmountOut,
        uint256 protocolFee
    )
        external
        onlySavvyPositionManager
        returns (
            address baseToken,
            uint256 amountBaseTokens,
            uint256 feeAmount,
            uint256 distributeAmount,
            uint256 credit
        )
    {
        _checkSupportedYieldToken(yieldToken);

        // Buffer any harvestable yield tokens. This will properly synchronize the balance which is held by users
        // and the balance which is held by the system to be harvested during this call.
        preemptivelyHarvest(yieldToken);

        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];

        // Load and proactively clear the amount of harvestable tokens so that future calls do not rely on stale data.
        // Because we cannot call an external unwrap until the amount of harvestable tokens has been calculated,
        // clearing this data immediately prevents any potential reentrancy attacks which would use stale harvest
        // buffer values.
        uint256 harvestableAmount = yieldTokenParams.harvestableBalance;
        yieldTokenParams.harvestableBalance = 0;

        // Check that the harvest will not be a no-op.
        Checker.checkState(harvestableAmount != 0, "zero harvestable amount");

        baseToken = yieldTokenParams.baseToken;
        amountBaseTokens = _unwrap(
            yieldToken,
            harvestableAmount,
            savvyPositionManager,
            minimumAmountOut
        );

        // Calculate how much of the unwrapped base tokens will be allocated for fees and distributed to users.
        feeAmount = (amountBaseTokens * protocolFee) / BPS;
        distributeAmount = amountBaseTokens - feeAmount;

        credit = _normalizeBaseTokensToDebt(baseToken, distributeAmount);

        // Distribute credit to all of the users who hold shares of the yield token.
        _distributeCredit(yieldToken, credit);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function currentBorrowingLimiter() external view returns (uint256) {
        return _borrowingLimiter.get();
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function currentRepayWithBaseTokenLimit(
        address baseToken
    ) external view returns (uint256) {
        return _repayLimiters[baseToken].get();
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function currentRepayWithCollateralLimit(
        address baseToken
    ) external view returns (uint256) {
        return _repayWithCollateralLimiters[baseToken].get();
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function setBorrowingLimiter(
        Limiters.LinearGrowthLimiter calldata borrowingLimiter_
    ) external {
        // This is first time so savvyPositionManager should be zero.
        require(savvyPositionManager == address(0), "Unauthorized");
        _borrowingLimiter = borrowingLimiter_;
    }

    /// @inheritdoc IYieldStrategyManagerActions
    function syncYieldToken(
        address yieldToken,
        uint256 amount,
        bool addOperation
    ) external onlySavvyPositionManager returns (YieldTokenParams memory) {
        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];

        uint256 amountBaseTokens = convertYieldTokensToBaseToken(
            yieldToken,
            amount
        );
        uint256 updatedActiveBalance = Math.uoperation(
            yieldTokenParams.activeBalance,
            amount,
            addOperation
        );
        uint256 updatedExpectedValue = Math.uoperation(
            yieldTokenParams.expectedValue,
            amountBaseTokens,
            addOperation
        );

        // _yieldStrategyManager.syncYieldToken(yieldToken, updatedActiveBalance, updatedExpectedValue);
        yieldTokenParams.activeBalance = updatedActiveBalance;
        yieldTokenParams.expectedValue = updatedExpectedValue;

        // Check that the maximum expected value has not been breached.
        Checker.checkState(
            yieldTokenParams.expectedValue <=
                yieldTokenParams.maximumExpectedValue,
            Errors.SPM_EXPECTED_VALUE_EXCEEDED
        );

        return yieldTokenParams;
    }

    /// @inheritdoc IYieldStrategyManagerActions
    function burnShares(
        address yieldToken,
        uint256 shares
    ) external onlySavvyPositionManager {
        _yieldTokens[yieldToken].totalShares -= shares;
    }

    /// @inheritdoc IYieldStrategyManagerActions
    function issueSharesForAmount(
        address yieldToken,
        uint256 amount
    ) external onlySavvyPositionManager returns (uint256 shares) {
        shares = convertYieldTokensToShares(yieldToken, amount);
        _yieldTokens[yieldToken].totalShares += shares;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function checkSupportedYieldToken(address yieldToken) external view {
        _checkSupportedYieldToken(yieldToken);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function checkSupportedBaseToken(address baseToken) external view {
        _checkSupportedBaseToken(baseToken);
        _checkBaseTokenEnabled(baseToken);
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function convertSharesToBaseTokens(
        address yieldToken,
        uint256 shares
    ) public view returns (address baseToken, uint256 amountBaseTokens) {
        YieldTokenParams memory yieldTokenParam = _yieldTokens[yieldToken];
        baseToken = yieldTokenParam.baseToken;
        uint256 amountYieldTokens = convertSharesToYieldTokens(
            yieldToken,
            shares
        );
        amountBaseTokens = convertYieldTokensToBaseToken(
            yieldToken,
            amountYieldTokens
        );
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function convertSharesToYieldTokens(
        address yieldToken,
        uint256 shares
    ) public view returns (uint256) {
        uint256 totalShares = _yieldTokens[yieldToken].totalShares;
        if (totalShares == 0) {
            return shares / _getYieldTokenFixedPoint(yieldToken);
        }
        return
            (shares * calculateUnrealizedActiveBalance(yieldToken)) /
            totalShares;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function convertYieldTokensToBaseToken(
        address yieldToken,
        uint256 amount
    ) public view returns (uint256) {
        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];
        ITokenAdapter adapter = ITokenAdapter(yieldTokenParams.adapter);
        return (amount * adapter.price()) / 10 ** yieldTokenParams.decimals;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function calculateUnrealizedActiveBalance(
        address yieldToken
    ) public view returns (uint256) {
        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];

        uint256 activeBalance = yieldTokenParams.activeBalance;
        if (activeBalance == 0) {
            return activeBalance;
        }

        uint256 currentValue = convertYieldTokensToBaseToken(
            yieldToken,
            activeBalance
        );
        uint256 expectedValue = yieldTokenParams.expectedValue;
        if (currentValue < expectedValue + 1) {
            return activeBalance;
        }

        uint256 harvestable = convertBaseTokensToYieldToken(
            yieldToken,
            currentValue - expectedValue
        );
        if (harvestable == 0) {
            return activeBalance;
        }

        return activeBalance - harvestable;
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function convertBaseTokensToYieldToken(
        address yieldToken,
        uint256 amount
    ) public view returns (uint256) {
        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];
        ITokenAdapter adapter = ITokenAdapter(yieldTokenParams.adapter);
        return (amount * 10 ** yieldTokenParams.decimals) / adapter.price();
    }

    /// @inheritdoc IYieldStrategyManagerStates
    function calculateUnlockedCredit(
        address yieldToken
    )
        public
        view
        returns (uint256 currentAccruedWeight, uint256 unlockedCredit)
    {
        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];
        currentAccruedWeight = yieldTokenParams.accruedWeight;

        {
            uint256 pendingCredit = yieldTokenParams.pendingCredit;
            if (pendingCredit > 0) {
                uint256 creditUnlockRate = yieldTokenParams.creditUnlockRate;
                uint256 distributedCredit = yieldTokenParams.distributedCredit;
                uint256 lastDistributionBlock = yieldTokenParams
                    .lastDistributionBlock;

                uint256 percentUnlocked = (block.number -
                    lastDistributionBlock) * creditUnlockRate;

                unlockedCredit = percentUnlocked < FIXED_POINT_SCALAR
                    ? ((pendingCredit * percentUnlocked) / FIXED_POINT_SCALAR) -
                        distributedCredit
                    : pendingCredit - distributedCredit;
            }
        }

        currentAccruedWeight += unlockedCredit > 0
            ? (unlockedCredit * FIXED_POINT_SCALAR) /
                yieldTokenParams.totalShares
            : 0;
    }

    /// @inheritdoc IYieldStrategyManagerActions
    function repayWithCollateralCheck(
        address yieldToken
    ) external view returns (address baseToken) {
        YieldTokenParams memory yieldTokenParams = _yieldTokens[yieldToken];
        baseToken = yieldTokenParams.baseToken;

        _checkSupportedYieldToken(yieldToken);
        _checkYieldTokenEnabled(yieldToken);
        _checkBaseTokenEnabled(baseToken);
        checkLoss(yieldToken);
    }

    /// @inheritdoc IYieldStrategyManagerActions
    function depositPrepare(
        address yieldToken
    ) external returns (YieldTokenParams memory yieldTokenParam) {
        yieldTokenParam = _yieldTokens[yieldToken];
        address baseToken = yieldTokenParam.baseToken;

        // Check that the yield token and it's base token are enabled. Disabling the yield token and/or the
        // base token prevents the system from holding more of the disabled yield token or base token.
        _checkYieldTokenEnabled(yieldToken);
        _checkBaseTokenEnabled(baseToken);

        // Check to assure that the token has not experienced a sudden unexpected loss. This prevents users from being
        // able to deposit funds and then have them siphoned if the price recovers.
        checkLoss(yieldToken);

        // Buffers any harvestable yield tokens. This will properly synchronize the balance which is held by users
        // and the balance which is held by the system to eventually be harvested.
        YieldTokenParams memory _yieldToken = _yieldTokens[yieldToken];
        uint256 activeBalance = _yieldToken.activeBalance;
        if (activeBalance == 0) {
            return yieldTokenParam;
        }

        uint256 currentValue = convertYieldTokensToBaseToken(
            yieldToken,
            activeBalance
        );
        uint256 expectedValue = _yieldToken.expectedValue;
        if (currentValue < expectedValue + 1) {
            return yieldTokenParam;
        }

        uint256 harvestable = convertBaseTokensToYieldToken(
            yieldToken,
            currentValue - expectedValue
        );
        if (harvestable == 0) {
            return yieldTokenParam;
        }
        _preemptivelyHarvest(yieldToken, harvestable);
    }

    /// @dev Checks if an address is a supported base token.
    ///
    /// If the address is not a supported yield token, this function will revert using a {UnsupportedToken} error.
    ///
    /// @param baseToken The address to check.
    function _checkSupportedBaseToken(address baseToken) internal view {
        require(_supportedBaseTokens.contains(baseToken), "UnsupportedToken");
    }

    /// @dev Checks if an address is a supported yield token.
    ///
    /// If the address is not a supported yield token, this function will revert using a {UnsupportedToken} error.
    ///
    /// @param yieldToken The address to check.
    function _checkSupportedYieldToken(address yieldToken) internal view {
        require(_supportedYieldTokens.contains(yieldToken), "UnsupportedToken");
    }

    /// @dev Unwraps `amount` of `yieldToken` into its base token.
    ///
    /// @param yieldToken       The address of the yield token to unwrap.
    /// @param amount           The amount of the yield token to wrap.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be received from the
    ///                         operation.
    ///
    /// @return The amount of base tokens that resulted from the operation.
    function _unwrap(
        address yieldToken,
        uint256 amount,
        address recipient,
        uint256 minimumAmountOut
    ) internal returns (uint256) {
        amount = TokenUtils.safeTransferFrom(
            yieldToken,
            msg.sender,
            address(this),
            amount
        );
        ITokenAdapter adapter = ITokenAdapter(_yieldTokens[yieldToken].adapter);
        TokenUtils.safeApprove(yieldToken, address(adapter), amount);
        uint256 amountUnwrapped = adapter.unwrap(amount, recipient);
        require(amountUnwrapped >= minimumAmountOut, "SlippageExceeded");
        return amountUnwrapped;
    }

    /// @dev Normalize `amount` of `baseToken` to a value which is comparable to units of the debt token.
    ///
    /// @param baseToken The address of the base token.
    /// @param amount          The amount of the debt token.
    ///
    /// @return The normalized amount.
    function _normalizeBaseTokensToDebt(
        address baseToken,
        uint256 amount
    ) internal view returns (uint256) {
        return amount * _baseTokens[baseToken].conversionFactor;
    }

    /// @dev Distributes `amount` credit to all depositors of `yieldToken`.
    ///
    /// @param yieldToken The address of the yield token to distribute credit for.
    /// @param amount     The amount of credit to distribute in debt tokens.
    function _distributeCredit(address yieldToken, uint256 amount) internal {
        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];

        uint256 pendingCredit = yieldTokenParams.pendingCredit;
        uint256 distributedCredit = yieldTokenParams.distributedCredit;
        (, uint256 unlockedCredit) = calculateUnlockedCredit(yieldToken);
        uint256 lockedCredit = pendingCredit -
            (distributedCredit + unlockedCredit);

        // Distribute any unlocked credit before overriding it.
        if (unlockedCredit > 0) {
            yieldTokenParams.accruedWeight +=
                (unlockedCredit * FIXED_POINT_SCALAR) /
                yieldTokenParams.totalShares;
        }

        yieldTokenParams.pendingCredit = amount + lockedCredit;
        yieldTokenParams.distributedCredit = 0;
        yieldTokenParams.lastDistributionBlock = block.number;
    }

    /// @dev Checks if a yield token is enabled.
    ///
    /// @param yieldToken The address of the yield token.
    function _checkYieldTokenEnabled(address yieldToken) internal view {
        YieldTokenParams memory _yieldToken = _yieldTokens[yieldToken];
        require(_yieldToken.enabled, "TokenDisabled");
    }

    /// @dev Checks if an base token is enabled.
    ///
    /// @param baseToken The address of the base token.
    function _checkBaseTokenEnabled(address baseToken) internal view {
        BaseTokenParams memory _baseToken = _baseTokens[baseToken];
        require(_baseToken.enabled, "TokenDisabled");
    }

    /// @dev Normalize `amount` of the debt token to a value which is comparable to units of `baseToken`.
    ///
    /// @dev This operation will result in truncation of some of the least significant digits of `amount`. This
    ///      truncation amount will be the least significant N digits where N is the difference in decimals between
    ///      the debt token and the base token.
    ///
    /// @param baseToken The address of the base token.
    /// @param amount          The amount of the debt token.
    ///
    /// @return The normalized amount.
    function _normalizeDebtTokensToUnderlying(
        address baseToken,
        uint256 amount
    ) internal view returns (uint256) {
        BaseTokenParams memory baseTokenParams = _baseTokens[baseToken];
        return amount / baseTokenParams.conversionFactor;
    }

    /// @dev Gets the amount of loss that `yieldToken` has incurred measured in basis points. When the expected
    ///      underlying value is less than the actual value, this will return zero.
    ///
    /// @param yieldToken The address of the yield token.
    ///
    /// @return The loss in basis points.
    function _loss(address yieldToken) internal view returns (uint256) {
        YieldTokenParams memory yieldTokenParams = _yieldTokens[yieldToken];

        uint256 amountBaseTokens = convertYieldTokensToBaseToken(
            yieldToken,
            yieldTokenParams.activeBalance
        );
        uint256 expectedUnderlyingValue = yieldTokenParams.expectedValue;

        if (amountBaseTokens == 0) {
            return 1;
        } else {
            return
                expectedUnderlyingValue > amountBaseTokens
                    ? ((expectedUnderlyingValue - amountBaseTokens) * BPS) /
                        expectedUnderlyingValue
                    : 0;
        }
    }

    function _preemptivelyHarvest(
        address yieldToken,
        uint256 harvestable
    ) internal {
        _yieldTokens[yieldToken].activeBalance -= harvestable;
        _yieldTokens[yieldToken].harvestableBalance += harvestable;
    }

    function _getYieldTokenFixedPoint(
        address yieldToken
    ) internal view returns (uint256) {
        YieldTokenParams memory yieldTokenParams = _yieldTokens[yieldToken];
        return 10 ** (18 - yieldTokenParams.decimals);
    }

    uint256[100] private __gap;
}