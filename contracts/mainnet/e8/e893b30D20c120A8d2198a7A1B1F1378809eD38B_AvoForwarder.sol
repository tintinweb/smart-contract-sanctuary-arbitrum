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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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
 * ```
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
pragma solidity >=0.8.17;

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/// @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
/// explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
contract AvoAdmin is ProxyAdmin {
    constructor(address _owner) {
        _transferOwnership(_owner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { IAvoWalletV3 } from "./interfaces/IAvoWalletV3.sol";
import { IAvoFactory } from "./interfaces/IAvoFactory.sol";
import { IAvoAuthoritiesList } from "./interfaces/IAvoAuthoritiesList.sol";

// empty interface used for Natspec docs for nice layout in automatically generated docs:
//
/// @title  AvoAuthoritiesList v3.0.0
/// @notice Tracks allowed authorities for AvoSafes, making available a list of all authorities
/// linked to an AvoSafe or all AvoSafes for a certain authority address.
///
/// If `trackInStorage` flag is set to false, then only an event will be emitted for off-chain tracking.
/// The contract itself will not track avoMultiSafes per signer!
///
/// Upgradeable through AvoAuthoritiesListProxy.
///
/// [email protected] Notes:_
/// In off-chain tracking, make sure to check for duplicates (i.e. mapping already exists).
/// This should not happen but when not tracking the data on-chain there is no way to be sure.
interface AvoAuthoritiesList_V3 {

}

abstract contract AvoAuthoritiesListErrors {
    /// @notice thrown when a method is called with invalid params (e.g. zero address)
    error AvoAuthoritiesList__InvalidParams();

    /// @notice thrown when a view method is called that would require storage mapping data,
    /// but the flag `trackInStorage` is set to false and thus data is not available.
    error AvoAuthoritiesList__NotTracked();
}

abstract contract AvoAuthoritiesListConstants is AvoAuthoritiesListErrors {
    /// @notice AvoFactory used to confirm that an address is an Avocado smart wallet
    IAvoFactory public immutable avoFactory;

    /// @notice flag to signal if tracking should happen in storage or only events should be emitted (for off-chain).
    /// This can be set to false to reduce gas cost on expensive chains
    bool public immutable trackInStorage;

    /// @notice constructor sets the immutable `avoFactory` (proxy) address and the `trackInStorage` flag
    constructor(IAvoFactory avoFactory_, bool trackInStorage_) {
        if (address(avoFactory_) == address(0)) {
            revert AvoAuthoritiesList__InvalidParams();
        }
        avoFactory = avoFactory_;

        trackInStorage = trackInStorage_;
    }
}

abstract contract AvoAuthoritiesListVariables is AvoAuthoritiesListConstants {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev add a gap for slot 0 to 100 to easily inherit Initializable / OwnableUpgradeable etc. later on
    uint256[101] private __gap;

    // ---------------- slot 101 -----------------

    /// @notice tracks all AvoSafes mapped to an authority: authority => EnumerableSet AvoSafes list
    /// @dev mappings to a struct with a mapping can not be public because the getter function that Solidity automatically
    /// generates for public variables cannot handle the potentially infinite size caused by mappings within the structs.
    mapping(address => EnumerableSet.AddressSet) internal _safesPerAuthority;

    // ---------------- slot 102 -----------------

    /// @notice tracks all authorities mapped to an AvoSafe: AvoSafe => EnumerableSet authorities list
    mapping(address => EnumerableSet.AddressSet) internal _authoritiesPerSafe;
}

abstract contract AvoAuthoritiesListEvents {
    /// @notice emitted when a new authority <> AvoSafe mapping is added
    event AuthorityMappingAdded(address authority, address avoSafe);

    /// @notice emitted when an authority <> AvoSafe mapping is removed
    event AuthorityMappingRemoved(address authority, address avoSafe);
}

abstract contract AvoAuthoritiesListViews is AvoAuthoritiesListVariables {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice returns true if `authority_` is an allowed authority of `avoSafe_`
    function isAuthorityOf(address avoSafe_, address authority_) public view returns (bool) {
        if (trackInStorage) {
            return _safesPerAuthority[authority_].contains(avoSafe_);
        } else {
            return IAvoWalletV3(avoSafe_).isAuthority(authority_);
        }
    }

    /// @notice returns all authorities for a certain `avoSafe_`.
    /// reverts with `AvoAuthoritiesList__NotTracked()` if `trackInStorage` is set to false (data not available)
    function authorities(address avoSafe_) public view returns (address[] memory) {
        if (trackInStorage) {
            return _authoritiesPerSafe[avoSafe_].values();
        } else {
            revert AvoAuthoritiesList__NotTracked();
        }
    }

    /// @notice returns all avoSafes for a certain `authority_'.
    /// reverts with `AvoAuthoritiesList__NotTracked()` if `trackInStorage` is set to false (data not available)
    function avoSafes(address authority_) public view returns (address[] memory) {
        if (trackInStorage) {
            return _safesPerAuthority[authority_].values();
        } else {
            revert AvoAuthoritiesList__NotTracked();
        }
    }

    /// @notice returns the number of mapped authorities for a certain `avoSafe_'.
    /// reverts with `AvoAuthoritiesList__NotTracked()` if `trackInStorage` is set to false (data not available)
    function authoritiesCount(address avoSafe_) public view returns (uint256) {
        if (trackInStorage) {
            return _authoritiesPerSafe[avoSafe_].length();
        } else {
            revert AvoAuthoritiesList__NotTracked();
        }
    }

    /// @notice returns the number of mapped AvoSafes for a certain `authority_'.
    /// reverts with `AvoAuthoritiesList__NotTracked()` if `trackInStorage` is set to false (data not available)
    function avoSafesCount(address authority_) public view returns (uint256) {
        if (trackInStorage) {
            return _safesPerAuthority[authority_].length();
        } else {
            revert AvoAuthoritiesList__NotTracked();
        }
    }
}

contract AvoAuthoritiesList is
    AvoAuthoritiesListErrors,
    AvoAuthoritiesListConstants,
    AvoAuthoritiesListVariables,
    AvoAuthoritiesListEvents,
    AvoAuthoritiesListViews,
    IAvoAuthoritiesList
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice constructor sets the immutable `avoFactory` (proxy) address and the `trackInStorage` flag
    constructor(
        IAvoFactory avoFactory_,
        bool trackInStorage_
    ) AvoAuthoritiesListConstants(avoFactory_, trackInStorage_) {}

    /// @inheritdoc IAvoAuthoritiesList
    function syncAvoAuthorityMappings(address avoSafe_, address[] calldata authorities_) external {
        // make sure `avoSafe_` is an actual AvoSafe
        if (avoFactory.isAvoSafe(avoSafe_) == false) {
            revert AvoAuthoritiesList__InvalidParams();
        }

        uint256 authoritiesLength_ = authorities_.length;

        bool isAuthority_;
        for (uint256 i; i < authoritiesLength_; ) {
            // check if authority is an allowed authority at the AvoWallet
            isAuthority_ = IAvoWalletV3(avoSafe_).isAuthority(authorities_[i]);

            if (isAuthority_) {
                if (trackInStorage) {
                    // `.add()` method also checks if authority is already mapped to the address
                    if (_safesPerAuthority[authorities_[i]].add(avoSafe_) == true) {
                        _authoritiesPerSafe[avoSafe_].add(authorities_[i]);
                        emit AuthorityMappingAdded(authorities_[i], avoSafe_);
                    }
                    // else ignore silently if mapping is already present
                } else {
                    emit AuthorityMappingAdded(authorities_[i], avoSafe_);
                }
            } else {
                if (trackInStorage) {
                    // `.remove()` method also checks if authority is not mapped to the address
                    if (_safesPerAuthority[authorities_[i]].remove(avoSafe_) == true) {
                        _authoritiesPerSafe[avoSafe_].remove(authorities_[i]);
                        emit AuthorityMappingRemoved(authorities_[i], avoSafe_);
                    }
                    // else ignore silently if mapping is not present
                } else {
                    emit AuthorityMappingRemoved(authorities_[i], avoSafe_);
                }
            }

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/// @title    AvoAuthoritiesListProxy
/// @notice   Default ERC1967Proxy for AvoAuthoritiesList
contract AvoAuthoritiesListProxy is TransparentUpgradeableProxy {
    constructor(
        address logic_,
        address admin_,
        bytes memory data_
    ) payable TransparentUpgradeableProxy(logic_, admin_, data_) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import { InstaFlashReceiverInterface } from "../external/InstaFlashReceiverInterface.sol";
import { IAvoVersionsRegistry } from "../interfaces/IAvoVersionsRegistry.sol";
import { Initializable } from "./lib/Initializable.sol";
import { AvoCoreVariables } from "./AvoCoreVariables.sol";
import { AvoCoreEvents } from "./AvoCoreEvents.sol";
import { AvoCoreErrors } from "./AvoCoreErrors.sol";
import { AvoCoreStructs } from "./AvoCoreStructs.sol";

abstract contract AvoCore is
    AvoCoreErrors,
    AvoCoreVariables,
    AvoCoreEvents,
    AvoCoreStructs,
    Initializable,
    ERC721Holder,
    ERC1155Holder,
    InstaFlashReceiverInterface,
    IERC1271
{
    /// @dev ensures the method can only be called by the same contract itself.
    modifier onlySelf() {
        _requireSelfCalled();
        _;
    }

    /// @dev internal method for modifier logic to reduce bytecode size of contract.
    function _requireSelfCalled() internal view {
        if (msg.sender != address(this)) {
            revert AvoCore__Unauthorized();
        }
    }

    /// @dev sets the initial state of the contract for `owner_` as owner
    function _initializeOwner(address owner_) internal {
        // owner must be EOA
        if (Address.isContract(owner_) || owner_ == address(0)) {
            revert AvoCore__InvalidParams();
        }

        owner = owner_;
    }

    /// @dev executes multiple cast actions according to CastParams `params_`, reserving `reserveGas_` in this contract.
    /// Uses a sequential nonce unless `nonSequentialNonce_` is set.
    /// @return success_ boolean flag indicating whether all actions have been executed successfully.
    /// @return revertReason_ if `success_` is false, then revert reason is returned as string here.
    function _executeCast(
        CastParams calldata params_,
        uint256 reserveGas_,
        bytes32 nonSequentialNonce_
    ) internal returns (bool success_, string memory revertReason_) {
        // set status verified to 1 for call to _callTargets to avoid having to check signature etc. again
        _status = 1;

        // nonce must be used *always* if signature is valid
        if (nonSequentialNonce_ == bytes32(0)) {
            // use sequential nonce, already validated in `_validateParams()`
            avoSafeNonce++;
        } else {
            // use non-sequential nonce, already validated in `_verifySig()`
            nonSequentialNonces[nonSequentialNonce_] = 1;
        }

        // execute _callTargets via a low-level call to create a separate execution frame
        // this is used to revert all the actions if one action fails without reverting the whole transaction
        bytes memory calldata_ = abi.encodeCall(AvoCoreProtected._callTargets, (params_.actions, params_.id));
        bytes memory result_;
        // using inline assembly for delegatecall to define custom gas amount that should stay here in caller
        assembly {
            success_ := delegatecall(
                // reserve some gas to make sure we can emit CastFailed event even for out of gas cases
                // and execute fee paying logic for `castAuthorized()`
                sub(gas(), reserveGas_),
                sload(_avoImplementation.slot),
                add(calldata_, 0x20),
                mload(calldata_),
                0,
                0
            )
            let size := returndatasize()

            result_ := mload(0x40)
            mstore(0x40, add(result_, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(result_, size)
            returndatacopy(add(result_, 0x20), 0, size)
        }

        // reset _status flag to 0 in all cases. cost 200 gas
        _status = 0;

        // @dev starting point for measuring reserve gas should be here right after actions execution.
        // on changes in code after execution (below here or below `_executeCast()` call in calling method),
        // measure the needed reserve gas via `gasleft()` anew and update `CAST_AUTHORIZED_RESERVE_GAS`
        // and `CAST_EVENTS_RESERVE_GAS` accordingly. use a method that forces maximum logic execution,
        // e.g. `castAuthorized()` with failing action in gas-usage-report.
        if (!success_) {
            if (result_.length == 0) {
                // @dev this case might be caused by edge-case out of gas errors that we were unable to catch,
                // but could potentially also have other reasons
                revertReason_ = "AVO__REASON_NOT_DEFINED";
            } else if (bytes4(result_) == bytes4(0x30e4191c)) {
                // 0x30e4191c = selector for custom error AvoCore__OutOfGas()
                revertReason_ = "AVO__OUT_OF_GAS";
            } else {
                assembly {
                    result_ := add(result_, 0x04)
                }
                revertReason_ = abi.decode(result_, (string));
            }
        }
    }

    /// @dev executes `actions_` with respective target, calldata, operation etc.
    /// IMPORTANT: Validation of `id_` and `_status` is expected to happen in `executeOperation()` and `_callTargets()`.
    /// catches out of gas errors (as well as possible), reverting with `AvoCore__OutOfGas()`.
    /// reverts with action index + error code in case of failure (e.g. "1_SOME_ERROR").
    function _executeActions(Action[] memory actions_, uint256 id_, bool isFlashloanCallback_) internal {
        // reset status immediately to avert reentrancy etc.
        _status = 0;

        uint256 storageSlot0Snapshot_;
        uint256 storageSlot1Snapshot_;
        uint256 storageSlot54Snapshot_;
        // delegate call = ids 1 and 21
        if (id_ == 1 || id_ == 21) {
            // store values before execution to make sure core storage vars are not modified by a delegatecall.
            // this ensures the smart wallet does not end up in a corrupted state.
            // for mappings etc. it is hard to protect against storage changes, so we must rely on the owner / signer
            // to know what is being triggered and the effects of a tx
            assembly {
                storageSlot0Snapshot_ := sload(0x0) // avoImpl, nonce, status
                storageSlot1Snapshot_ := sload(0x1) // owner, _initialized, _initializing
            }

            if (IS_MULTISIG) {
                assembly {
                    storageSlot54Snapshot_ := sload(0x36) // storage slot 54 related variables such as signers for Multisig
                }
            }
        }

        uint256 actionsLength_ = actions_.length;
        for (uint256 i; i < actionsLength_; ) {
            Action memory action_ = actions_[i];

            // execute action
            bool success_;
            bytes memory result_;
            uint256 actionMinGasLeft_;
            if (action_.operation == 0 && (id_ < 2 || id_ == 20 || id_ == 21)) {
                // call (operation = 0 & id = call(0 / 20) or mixed(1 / 21))
                unchecked {
                    // store amount of gas that stays with caller, according to EIP150 to detect out of gas errors
                    // -> as close as possible to actual call
                    actionMinGasLeft_ = gasleft() / 64;
                }

                (success_, result_) = action_.target.call{ value: action_.value }(action_.data);
            } else if (action_.operation == 1 && storageSlot0Snapshot_ > 0) {
                // delegatecall (operation = 1 & id = mixed(1 / 21))
                unchecked {
                    // store amount of gas that stays with caller, according to EIP150 to detect out of gas errors
                    // -> as close as possible to actual call
                    actionMinGasLeft_ = gasleft() / 64;
                }

                // storageSlot0Snapshot_ is only set if id is set for a delegateCall
                (success_, result_) = action_.target.delegatecall(action_.data);
            } else if (action_.operation == 2 && (id_ == 20 || id_ == 21)) {
                // flashloan (operation = 2 & id = flashloan(20 / 21))
                if (isFlashloanCallback_) {
                    revert(string.concat(Strings.toString(i), "_AVO__NO_FLASHLOAN_IN_FLASHLOAN"));
                }
                // flashloan is always executed via .call, flashloan aggregator uses `msg.sender`, so .delegatecall
                // wouldn't send funds to this contract but rather to the original sender.

                // store `id_` temporarily as `_status` as flag to allow the flashloan callback (`executeOperation()`)
                _status = uint8(id_);

                unchecked {
                    // store amount of gas that stays with caller, according to EIP150 to detect out of gas errors
                    // -> as close as possible to actual call
                    actionMinGasLeft_ = gasleft() / 64;
                }

                (success_, result_) = action_.target.call{ value: action_.value }(action_.data);

                // reset _status flag to 0 in all cases. cost 200 gas
                _status = 0;
            } else {
                // either operation does not exist or the id was not set according to what the action wants to execute
                if (action_.operation > 2) {
                    revert(string.concat(Strings.toString(i), "_AVO__OPERATION_NOT_EXIST"));
                } else {
                    // enforce that id must be set according to operation
                    revert(string.concat(Strings.toString(i), "_AVO__ID_ACTION_MISMATCH"));
                }
            }

            if (!success_) {
                if (gasleft() < actionMinGasLeft_) {
                    // action ran out of gas, trigger revert with specific custom error
                    revert AvoCore__OutOfGas();
                }

                revert(string.concat(Strings.toString(i), _getRevertReasonFromReturnedData(result_)));
            }

            unchecked {
                ++i;
            }
        }

        // if actions include delegatecall (if snapshot is set), make sure storage was not modified
        if (storageSlot0Snapshot_ > 0) {
            uint256 storageSlot0_;
            uint256 storageSlot1_;
            assembly {
                storageSlot0_ := sload(0x0)
                storageSlot1_ := sload(0x1)
            }

            uint256 storageSlot54_;
            if (IS_MULTISIG) {
                assembly {
                    storageSlot54_ := sload(0x36) // storage slot 54 related variables such as signers for Multisig
                }
            }

            if (
                !(storageSlot0_ == storageSlot0Snapshot_ &&
                    storageSlot1_ == storageSlot1Snapshot_ &&
                    storageSlot54_ == storageSlot54Snapshot_)
            ) {
                revert("AVO__MODIFIED_STORAGE");
            }
        }
    }

    /// @dev                   Validates input params, reverts on invalid values.
    /// @param actionsLength_  the length of the actions array to execute
    /// @param avoSafeNonce_   the avoSafeNonce from input CastParams
    /// @param validAfter_     timestamp after which the request is valid
    /// @param validUntil_     timestamp before which the request is valid
    function _validateParams(
        uint256 actionsLength_,
        int256 avoSafeNonce_,
        uint256 validAfter_,
        uint256 validUntil_
    ) internal view {
        // make sure actions are defined and nonce is valid:
        // must be -1 to use a non-sequential nonce or otherwise it must match the avoSafeNonce
        if (!(actionsLength_ > 0 && (avoSafeNonce_ == -1 || uint256(avoSafeNonce_) == avoSafeNonce))) {
            revert AvoCore__InvalidParams();
        }

        // make sure request is within valid timeframe
        if ((validAfter_ > 0 && validAfter_ > block.timestamp) || (validUntil_ > 0 && validUntil_ < block.timestamp)) {
            revert AvoCore__InvalidTiming();
        }
    }

    /// @dev pays the fee for `castAuthorized()` calls via the AvoVersionsRegistry (or fallback)
    /// @param gasUsedFrom_ `gasleft()` snapshot at gas measurement starting point
    /// @param maxFee_      maximum acceptable fee to be paid, revert if fee is bigger than this value
    function _payAuthorizedFee(uint256 gasUsedFrom_, uint256 maxFee_) internal {
        // @dev part below costs ~24k gas for if `feeAmount_` and `maxFee_` is set
        uint256 feeAmount_;
        address payable feeCollector_;
        {
            uint256 gasUsed_;
            unchecked {
                // gas can not underflow
                // gasUsed already includes everything at this point except for paying fee logic
                gasUsed_ = gasUsedFrom_ - gasleft();
            }

            // Using a low-level function call to prevent reverts (making sure the contract is truly non-custodial)
            (bool success_, bytes memory result_) = address(avoVersionsRegistry).staticcall(
                abi.encodeWithSignature("calcFee(uint256)", gasUsed_)
            );

            if (success_) {
                (feeAmount_, feeCollector_) = abi.decode(result_, (uint256, address));
                if (feeAmount_ > AUTHORIZED_MAX_FEE) {
                    // make sure AvoVersionsRegistry fee is capped
                    feeAmount_ = AUTHORIZED_MAX_FEE;
                }
            } else {
                // registry calcFee failed. Use local backup minimum fee
                feeCollector_ = AUTHORIZED_FEE_COLLECTOR;
                feeAmount_ = AUTHORIZED_MIN_FEE;
            }
        }

        // pay fee, if any
        if (feeAmount_ > 0) {
            if (maxFee_ > 0 && feeAmount_ > maxFee_) {
                revert AvoCore__MaxFee(feeAmount_, maxFee_);
            }

            // sending fee based on OZ Address.sendValue, but modified to properly act based on actual error case
            // (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/utils/Address.sol#L60)
            if (address(this).balance < feeAmount_) {
                revert AvoCore__InsufficientBalance(feeAmount_);
            }

            // send along enough gas (22_000) to make any gas griefing attacks impossible. This should be enough for any
            // normal transfer to an EOA or an Avocado Multisig
            (bool success_, ) = feeCollector_.call{ value: feeAmount_, gas: 22_000 }("");

            if (success_) {
                emit FeePaid(feeAmount_);
            } else {
                // do not revert, as an error on the feeCollector_ side should not be the "fault" of the Avo contract.
                // Letting this case pass ensures that the contract is truly non-custodial (not blockable by feeCollector)
                emit FeePayFailed(feeAmount_);
            }
        } else {
            emit FeePaid(feeAmount_);
        }
    }

    /// @notice                  gets the digest (hash) used to verify an EIP712 signature
    /// @param params_           Cast params such as id, avoSafeNonce and actions to execute
    /// @param functionTypeHash_ whole function type hash, e.g. CAST_TYPE_HASH or CAST_AUTHORIZED_TYPE_HASH
    /// @param customStructHash_ struct hash added after CastParams hash, e.g. CastForwardParams or CastAuthorizedParams hash
    /// @return                  bytes32 digest e.g. for signature or non-sequential nonce
    function _getSigDigest(
        CastParams memory params_,
        bytes32 functionTypeHash_,
        bytes32 customStructHash_
    ) internal view returns (bytes32) {
        bytes32[] memory keccakActions_;

        {
            // get keccak256s for actions
            uint256 actionsLength_ = params_.actions.length;
            keccakActions_ = new bytes32[](actionsLength_);
            for (uint256 i; i < actionsLength_; ) {
                keccakActions_[i] = keccak256(
                    abi.encode(
                        ACTION_TYPE_HASH,
                        params_.actions[i].target,
                        keccak256(params_.actions[i].data),
                        params_.actions[i].value,
                        params_.actions[i].operation
                    )
                );

                unchecked {
                    ++i;
                }
            }
        }

        return
            ECDSA.toTypedDataHash(
                // domain separator
                _domainSeparatorV4(),
                // structHash
                keccak256(
                    abi.encode(
                        functionTypeHash_,
                        // CastParams hash
                        keccak256(
                            abi.encode(
                                CAST_PARAMS_TYPE_HASH,
                                // actions
                                keccak256(abi.encodePacked(keccakActions_)),
                                params_.id,
                                params_.avoSafeNonce,
                                params_.salt,
                                params_.source,
                                keccak256(params_.metadata)
                            )
                        ),
                        // CastForwardParams or CastAuthorizedParams hash
                        customStructHash_
                    )
                )
            );
    }

    /// @notice Returns the domain separator for the chain with id `DEFAULT_CHAIN_ID`
    function _domainSeparatorV4() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TYPE_HASH,
                    DOMAIN_SEPARATOR_NAME_HASHED,
                    DOMAIN_SEPARATOR_VERSION_HASHED,
                    DEFAULT_CHAIN_ID,
                    address(this),
                    keccak256(abi.encodePacked(block.chainid)) // in salt: ensure tx replay is not possible
                )
            );
    }

    /// @dev Get the revert reason from the returnedData (supports Panic, Error & Custom Errors).
    /// Based on https://github.com/superfluid-finance/protocol-monorepo/blob/dev/packages/ethereum-contracts/contracts/libs/CallUtils.sol
    /// This is needed in order to provide some human-readable revert message from a call.
    /// @param returnedData_ revert data of the call
    /// @return reason_      revert reason
    function _getRevertReasonFromReturnedData(
        bytes memory returnedData_
    ) internal pure returns (string memory reason_) {
        if (returnedData_.length < 4) {
            // case 1: catch all
            return "_REASON_NOT_DEFINED";
        } else {
            bytes4 errorSelector;
            assembly {
                errorSelector := mload(add(returnedData_, 0x20))
            }
            if (errorSelector == bytes4(0x4e487b71) /* `seth sig "Panic(uint256)"` */) {
                // case 2: Panic(uint256) (Defined since 0.8.0)
                // ref: https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require)
                reason_ = "_TARGET_PANICKED: 0x__";
                uint256 errorCode;
                assembly {
                    errorCode := mload(add(returnedData_, 0x24))
                    let reasonWord := mload(add(reason_, 0x20))
                    // [0..9] is converted to ['0'..'9']
                    // [0xa..0xf] is not correctly converted to ['a'..'f']
                    // but since panic code doesn't have those cases, we will ignore them for now!
                    let e1 := add(and(errorCode, 0xf), 0x30)
                    let e2 := shl(8, add(shr(4, and(errorCode, 0xf0)), 0x30))
                    reasonWord := or(
                        and(reasonWord, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000),
                        or(e2, e1)
                    )
                    mstore(add(reason_, 0x20), reasonWord)
                }
            } else {
                if (returnedData_.length > 68) {
                    // case 3: Error(string) (Defined at least since 0.7.0)
                    assembly {
                        returnedData_ := add(returnedData_, 0x04)
                    }
                    reason_ = string.concat("_", abi.decode(returnedData_, (string)));
                } else {
                    // case 4: Custom errors (Defined since 0.8.0)

                    // convert bytes4 selector to string
                    // based on https://ethereum.stackexchange.com/a/111876
                    bytes memory result = new bytes(10);
                    result[0] = bytes1("0");
                    result[1] = bytes1("x");
                    for (uint256 i; i < 4; ) {
                        result[2 * i + 2] = _toHexDigit(uint8(errorSelector[i]) / 16);
                        result[2 * i + 3] = _toHexDigit(uint8(errorSelector[i]) % 16);

                        unchecked {
                            ++i;
                        }
                    }

                    reason_ = string.concat("_CUSTOM_ERROR:", string(result));
                }
            }
        }
    }

    /// @dev used to convert bytes4 selector to string
    function _toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        revert();
    }
}

abstract contract AvoCoreEIP1271 is AvoCore {
    /// @inheritdoc IERC1271
    function isValidSignature(bytes32 hash, bytes calldata signature) external view virtual returns (bytes4 magicValue);

    /// @notice Marks a bytes32 `message_` (signature digest) as signed, making it verifiable by EIP-1271 `isValidSignature()`.
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param message_ data hash to be allow-listed as signed
    function signMessage(bytes32 message_) external onlySelf {
        _signedMessages[message_] = 1;

        emit SignedMessage(message_);
    }

    /// @notice Removes a previously `signMessage()` signed bytes32 `message_` (signature digest).
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param message_ data hash to be removed from allow-listed signatures
    function removeSignedMessage(bytes32 message_) external onlySelf {
        _signedMessages[message_] = 0;

        emit RemoveSignedMessage(message_);
    }
}

/// @dev Simple contract to upgrade the implementation address stored at storage slot 0x0.
///      Mostly based on OpenZeppelin ERC1967Upgrade contract, adapted with onlySelf etc.
///      IMPORTANT: For any new implementation, the upgrade method MUST be in the implementation itself,
///      otherwise it can not be upgraded anymore!
abstract contract AvoCoreSelfUpgradeable is AvoCore {
    /// @notice upgrade the contract to a new implementation address.
    ///         - Must be a valid version at the AvoVersionsRegistry.
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param avoImplementation_   New contract address
    function upgradeTo(address avoImplementation_) public virtual;

    /// @notice upgrade the contract to a new implementation address and call a function afterwards.
    ///         - Must be a valid version at the AvoVersionsRegistry.
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param avoImplementation_   New contract address
    /// @param data_                callData for function call on avoImplementation_ after upgrading
    /// @param forceCall_           optional flag to force send call even if callData (data_) is empty
    function upgradeToAndCall(
        address avoImplementation_,
        bytes calldata data_,
        bool forceCall_
    ) external payable virtual onlySelf {
        upgradeTo(avoImplementation_);
        if (data_.length > 0 || forceCall_) {
            Address.functionDelegateCall(avoImplementation_, data_);
        }
    }
}

abstract contract AvoCoreProtected is AvoCore {
    /***********************************|
    |             ONLY SELF             |
    |__________________________________*/

    /// @notice occupies the sequential `avoSafeNonces_` in storage. This can be used to cancel / invalidate
    ///         a previously signed request(s) because the nonce will be "used" up.
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param  avoSafeNonces_ sequential ascending ordered nonces to be occupied in storage.
    ///         E.g. if current AvoSafeNonce is 77 and txs are queued with avoSafeNonces 77, 78 and 79,
    ///         then you would submit [78, 79] here because 77 will be occupied by the tx executing
    ///         `occupyAvoSafeNonces()` as an action itself. If executing via non-sequential nonces, you would
    ///         submit [77, 78, 79].
    ///         - Maximum array length is 5.
    ///         - gap from the current avoSafeNonce will revert (e.g. [79, 80] if current one is 77)
    function occupyAvoSafeNonces(uint88[] calldata avoSafeNonces_) external onlySelf {
        uint256 avoSafeNoncesLength_ = avoSafeNonces_.length;
        if (avoSafeNoncesLength_ == 0) {
            // in case to cancel just one nonce via normal sequential nonce execution itself
            return;
        }

        if (avoSafeNoncesLength_ > 5) {
            revert AvoCore__InvalidParams();
        }

        uint256 nextAvoSafeNonce_ = avoSafeNonce;

        for (uint256 i; i < avoSafeNoncesLength_; ) {
            if (avoSafeNonces_[i] == nextAvoSafeNonce_) {
                // nonce to occupy is valid -> must match the current avoSafeNonce
                emit AvoSafeNonceOccupied(nextAvoSafeNonce_);
                nextAvoSafeNonce_++;
            } else if (avoSafeNonces_[i] > nextAvoSafeNonce_) {
                // input nonce is not smaller or equal current nonce -> invalid sorted ascending input params
                revert AvoCore__InvalidParams();
            }
            // else while nonce to occupy is < current nonce, skip ahead

            unchecked {
                ++i;
            }
        }

        avoSafeNonce = uint88(nextAvoSafeNonce_);
    }

    /// @notice occupies the `nonSequentialNonces_` in storage. This can be used to cancel / invalidate
    ///         previously signed request(s) because the nonce will be "used" up.
    ///         - Can only be self-called (authorization same as for `cast` methods).
    /// @param  nonSequentialNonces_ the non-sequential nonces to occupy
    function occupyNonSequentialNonces(bytes32[] calldata nonSequentialNonces_) external onlySelf {
        uint256 nonSequentialNoncesLength_ = nonSequentialNonces_.length;

        for (uint256 i; i < nonSequentialNoncesLength_; ) {
            nonSequentialNonces[nonSequentialNonces_[i]] = 1;

            emit NonSequentialNonceOccupied(nonSequentialNonces_[i]);

            unchecked {
                ++i;
            }
        }
    }

    /***********************************|
    |         FLASHLOAN CALLBACK        |
    |__________________________________*/

    /// @dev                    callback used by Instadapp Flashloan Aggregator, executes operations while owning
    ///                         the flashloaned amounts. `data_` must contain actions, one of them must pay back flashloan
    // /// @param assets_       assets_ received a flashloan for
    // /// @param amounts_      flashloaned amounts for each asset
    // /// @param premiums_     fees to pay for the flashloan
    /// @param initiator_       flashloan initiator -> must be this contract
    /// @param data_            data bytes containing the `abi.encoded()` actions that are executed like in `CastParams.actions`
    function executeOperation(
        address[] calldata /*  assets_ */,
        uint256[] calldata /*  amounts_ */,
        uint256[] calldata /*  premiums_ */,
        address initiator_,
        bytes calldata data_
    ) external returns (bool) {
        uint256 status_ = _status;

        // @dev using the valid case inverted via one ! instead of invalid case with 3 ! to optimize gas usage
        if (!((status_ == 20 || status_ == 21) && initiator_ == address(this))) {
            revert AvoCore__Unauthorized();
        }

        _executeActions(
            // decode actions to be executed after getting the flashloan
            abi.decode(data_, (Action[])),
            // _status is set to `CastParams.id` pre-flashloan trigger in `_executeActions()`
            status_,
            true
        );

        return true;
    }

    /***********************************|
    |         INDIRECT INTERNAL         |
    |__________________________________*/

    /// @dev             executes a low-level .call or .delegateCall on all `actions_`.
    ///                  Can only be self-called by this contract under certain conditions, essentially internal method.
    ///                  This is called like an external call to create a separate execution frame.
    ///                  This way we can revert all the `actions_` if one fails without reverting the whole transaction.
    /// @param actions_  the actions to execute (target, data, value, operation)
    /// @param id_       id for `actions_`, see `CastParams.id`
    function _callTargets(Action[] calldata actions_, uint256 id_) external payable {
        // status must be verified or 0x000000000000000000000000000000000000dEaD used for backend gas estimations
        if (!(_status == 1 || tx.origin == 0x000000000000000000000000000000000000dEaD)) {
            revert AvoCore__Unauthorized();
        }

        _executeActions(actions_, id_, false);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

abstract contract AvoCoreErrors {
    /// @notice thrown when a signature has expired or when a request isn't valid yet
    error AvoCore__InvalidTiming();

    /// @notice thrown when someone is trying to execute a in some way auth protected logic
    error AvoCore__Unauthorized();

    /// @notice thrown when actions execution runs out of gas
    error AvoCore__OutOfGas();

    /// @notice thrown when a method is called with invalid params (e.g. a zero address as input param)
    error AvoCore__InvalidParams();

    /// @notice thrown when an EIP1271 signature is invalid
    error AvoCore__InvalidEIP1271Signature();

    /// @notice thrown when a `castAuthorized()` `fee` is bigger than the `maxFee` given through the input param
    error AvoCore__MaxFee(uint256 fee, uint256 maxFee);

    /// @notice thrown when `castAuthorized()` fee can not be covered by available contract funds
    error AvoCore__InsufficientBalance(uint256 fee);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

abstract contract AvoCoreEvents {
    /// @notice Emitted when the implementation is upgraded to a new logic contract
    event Upgraded(address indexed newImplementation);

    /// @notice Emitted when a message is marked as allowed smart contract signature
    event SignedMessage(bytes32 indexed messageHash);

    /// @notice Emitted when a previously allowed signed message is removed
    event RemoveSignedMessage(bytes32 indexed messageHash);

    /// @notice emitted when the avoSafeNonce in storage is increased through an authorized call to
    /// `occupyAvoSafeNonces()`, which can be used to cancel a previously signed request
    event AvoSafeNonceOccupied(uint256 indexed occupiedAvoSafeNonce);

    /// @notice emitted when a non-sequential nonce is occupied in storage through an authorized call to
    /// `useNonSequentialNonces()`, which can be used to cancel a previously signed request
    event NonSequentialNonceOccupied(bytes32 indexed occupiedNonSequentialNonce);

    /// @notice Emitted when a fee is paid through use of the `castAuthorized()` method
    event FeePaid(uint256 indexed fee);

    /// @notice Emitted when paying a fee reverts at the recipient
    event FeePayFailed(uint256 indexed fee);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface AvoCoreStructs {
    /// @notice a combination of a bytes signature and its signer.
    struct SignatureParams {
        ///
        /// @param signature ECDSA signature of `getSigDigest()` for default flow or EIP1271 smart contract signature
        bytes signature;
        ///
        /// @param signer signer of the signature. Can be set to smart contract address that supports EIP1271
        address signer;
    }

    /// @notice an arbitrary executable action
    struct Action {
        ///
        /// @param target the target address to execute the action on
        address target;
        ///
        /// @param data the calldata to be passed to the call for each target
        bytes data;
        ///
        /// @param value the msg.value to be passed to the call for each target. set to 0 if none
        uint256 value;
        ///
        /// @param operation type of operation to execute:
        /// 0 -> .call; 1 -> .delegateCall, 2 -> flashloan (via .call)
        uint256 operation;
    }

    /// @notice common params for both `cast()` and `castAuthorized()`
    struct CastParams {
        Action[] actions;
        ///
        /// @param id             Required:
        ///                       id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall),
        ///                                           20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
        uint256 id;
        ///
        /// @param avoSafeNonce   Required:
        ///                       avoSafeNonce to be used for this tx. Must equal the avoSafeNonce value on smart
        ///                       wallet or alternatively it must be set to -1 to use a non-sequential nonce instead
        int256 avoSafeNonce;
        ///
        /// @param salt           Optional:
        ///                       Salt to customize non-sequential nonce (if `avoSafeNonce` is set to -1)
        bytes32 salt;
        ///
        /// @param source         Optional:
        ///                       Source / referral for this tx
        address source;
        ///
        /// @param metadata       Optional:
        ///                       metadata for any potential additional data to be tracked in the tx
        bytes metadata;
    }

    /// @notice `cast()` input params related to forwarding validity
    struct CastForwardParams {
        ///
        /// @param gas            Optional:
        ///                       As EIP-2770: user instructed minimum amount of gas that the relayer (AvoForwarder)
        ///                       must send for the execution. Sending less gas will fail the tx at the cost of the relayer.
        ///                       Also protects against potential gas griefing attacks
        ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        uint256 gas;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be forwarded in,
        ///                       or 0 if the request is not time-limited to occur after a certain time.
        ///                       Protects against relayers executing a certain transaction at an earlier moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validAfter;
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       can be forwarded, or 0 if request should be valid forever.
        ///                       Protects against relayers executing a certain transaction at a later moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validUntil;
    }

    /// @notice `castAuthorized()` input params
    struct CastAuthorizedParams {
        ///
        /// @param maxFee         Optional:
        ///                       the maximum Avocado charge-up allowed to be paid for tx execution
        uint256 maxFee;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be forwarded in,
        ///                       or 0 if the request is not time-limited to occur after a certain time.
        ///                       Protects against relayers executing a certain transaction at an earlier moment
        ///                       not intended by the user, where it might have a completely different effect.
        ///                       Has no effect for AvoWallet (Solo), only used for AvoMultisig.
        uint256 validAfter;
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       can be forwarded, or 0 if request should be valid forever.
        ///                       Protects against relayers executing a certain transaction at a later moment
        ///                       not intended by the user, where it might have a completely different effect.
        ///                       Has no effect for AvoWallet (Solo), only used for AvoMultisig.
        uint256 validUntil;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { AvoCoreErrors } from "./AvoCoreErrors.sol";
import { IAvoVersionsRegistry } from "../interfaces/IAvoVersionsRegistry.sol";
import { IAvoAuthoritiesList } from "../interfaces/IAvoAuthoritiesList.sol";

// --------------------------- DEVELOPER NOTES -----------------------------------------
// @dev IMPORTANT: Contracts using AvoCore must inherit this contract and define the immutables
// -------------------------------------------------------------------------------------
abstract contract AvoCoreConstantsOverride is AvoCoreErrors {
    // @dev: MUST SET DOMAIN_SEPARATOR_NAME & DOMAIN_SEPARATOR_VERSION IN CONTRACTS USING AvoCore.
    // Solidity offers no good way to create this inheritance or forcing implementation without increasing gas cost:
    // strings are not supported as immutable.
    // string public constant DOMAIN_SEPARATOR_NAME = "Avocado-Safe";
    // string public constant DOMAIN_SEPARATOR_VERSION = "3.0.0";

    // hashed EIP712 values
    bytes32 internal immutable DOMAIN_SEPARATOR_NAME_HASHED;
    bytes32 internal immutable DOMAIN_SEPARATOR_VERSION_HASHED;

    /// @dev amount of gas to keep in castAuthorized caller method as reserve for emitting event + paying fee
    uint256 internal immutable CAST_AUTHORIZED_RESERVE_GAS;
    /// @dev amount of gas to keep in cast caller method as reserve for emitting CastFailed / CastExecuted event
    uint256 internal immutable CAST_EVENTS_RESERVE_GAS;

    /// @dev flag for internal use to detect if current AvoCore is multisig logic
    bool internal immutable IS_MULTISIG;

    /// @dev minimum fee for fee charged via `castAuthorized()` to charge if `AvoVersionsRegistry.calcFee()` would fail
    uint256 public immutable AUTHORIZED_MIN_FEE;
    /// @dev global maximum for fee charged via `castAuthorized()`. If AvoVersionsRegistry returns a fee higher than this,
    /// then MAX_AUTHORIZED_FEE is charged as fee instead (capping)
    uint256 public immutable AUTHORIZED_MAX_FEE;
    /// @dev address that the fee charged via `castAuthorized()` is sent to in the fallback case
    address payable public immutable AUTHORIZED_FEE_COLLECTOR;

    constructor(
        string memory domainSeparatorName_,
        string memory domainSeparatorVersion_,
        uint256 castAuthorizedReserveGas_,
        uint256 castEventsReserveGas_,
        uint256 authorizedMinFee_,
        uint256 authorizedMaxFee_,
        address authorizedFeeCollector_,
        bool isMultisig
    ) {
        DOMAIN_SEPARATOR_NAME_HASHED = keccak256(bytes(domainSeparatorName_));
        DOMAIN_SEPARATOR_VERSION_HASHED = keccak256(bytes(domainSeparatorVersion_));

        CAST_AUTHORIZED_RESERVE_GAS = castAuthorizedReserveGas_;
        CAST_EVENTS_RESERVE_GAS = castEventsReserveGas_;

        // min & max fee settings, fee collector adress are required
        if (
            authorizedMinFee_ == 0 ||
            authorizedMaxFee_ == 0 ||
            authorizedFeeCollector_ == address(0) ||
            authorizedMinFee_ > authorizedMaxFee_
        ) {
            revert AvoCore__InvalidParams();
        }

        AUTHORIZED_MIN_FEE = authorizedMinFee_;
        AUTHORIZED_MAX_FEE = authorizedMaxFee_;
        AUTHORIZED_FEE_COLLECTOR = payable(authorizedFeeCollector_);

        IS_MULTISIG = isMultisig;
    }
}

abstract contract AvoCoreConstants is AvoCoreErrors {
    /***********************************|
    |              CONSTANTS            |
    |__________________________________*/

    /// @notice overwrite chain id for EIP712 is always set to 63400 for the Avocado RPC / network
    uint256 public constant DEFAULT_CHAIN_ID = 63400;

    /// @notice _TYPE_HASH is copied from OpenZeppelin EIP712 but with added salt as last param (we use it for `block.chainid`)
    bytes32 public constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");

    /// @notice EIP712 typehash for `cast()` calls, including structs
    bytes32 public constant CAST_TYPE_HASH =
        keccak256(
            "Cast(CastParams params,CastForwardParams forwardParams)Action(address target,bytes data,uint256 value,uint256 operation)CastForwardParams(uint256 gas,uint256 gasPrice,uint256 validAfter,uint256 validUntil)CastParams(Action[] actions,uint256 id,int256 avoSafeNonce,bytes32 salt,address source,bytes metadata)"
        );

    /// @notice EIP712 typehash for Action struct
    bytes32 public constant ACTION_TYPE_HASH =
        keccak256("Action(address target,bytes data,uint256 value,uint256 operation)");

    /// @notice EIP712 typehash for CastParams struct
    bytes32 public constant CAST_PARAMS_TYPE_HASH =
        keccak256(
            "CastParams(Action[] actions,uint256 id,int256 avoSafeNonce,bytes32 salt,address source,bytes metadata)Action(address target,bytes data,uint256 value,uint256 operation)"
        );
    /// @notice EIP712 typehash for CastForwardParams struct
    bytes32 public constant CAST_FORWARD_PARAMS_TYPE_HASH =
        keccak256("CastForwardParams(uint256 gas,uint256 gasPrice,uint256 validAfter,uint256 validUntil)");

    /// @dev "magic value" according to EIP1271 https://eips.ethereum.org/EIPS/eip-1271#specification
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x1626ba7e;

    /// @notice EIP712 typehash for `castAuthorized()` calls, including structs
    bytes32 public constant CAST_AUTHORIZED_TYPE_HASH =
        keccak256(
            "CastAuthorized(CastParams params,CastAuthorizedParams authorizedParams)Action(address target,bytes data,uint256 value,uint256 operation)CastAuthorizedParams(uint256 maxFee,uint256 gasPrice,uint256 validAfter,uint256 validUntil)CastParams(Action[] actions,uint256 id,int256 avoSafeNonce,bytes32 salt,address source,bytes metadata)"
        );

    /// @notice EIP712 typehash for CastAuthorizedParams struct
    bytes32 public constant CAST_AUTHORIZED_PARAMS_TYPE_HASH =
        keccak256("CastAuthorizedParams(uint256 maxFee,uint256 gasPrice,uint256 validAfter,uint256 validUntil)");

    /***********************************|
    |             IMMUTABLES            |
    |__________________________________*/

    /// @notice  registry holding the valid versions (addresses) for Avocado smart wallet implementation contracts
    ///          The registry is used to verify a valid version before upgrading & to pay fees for `castAuthorized()`
    IAvoVersionsRegistry public immutable avoVersionsRegistry;

    /// @notice address of the AvoForwarder (proxy) that is allowed to forward tx with valid signatures
    address public immutable avoForwarder;

    /***********************************|
    |            CONSTRUCTOR            |
    |__________________________________*/

    constructor(IAvoVersionsRegistry avoVersionsRegistry_, address avoForwarder_) {
        if (address(avoVersionsRegistry_) == address(0)) {
            revert AvoCore__InvalidParams();
        }
        avoVersionsRegistry = avoVersionsRegistry_;

        avoVersionsRegistry.requireValidAvoForwarderVersion(avoForwarder_);
        avoForwarder = avoForwarder_;
    }
}

abstract contract AvoCoreVariablesSlot0 {
    /// @notice address of the smart wallet logic / implementation contract.
    //  @dev    IMPORTANT: SAME STORAGE SLOT AS FOR PROXY. DO NOT MOVE THIS VARIABLE.
    //         _avoImplementation MUST ALWAYS be the first declared variable here in the logic contract and in the proxy!
    //         When upgrading, the storage at memory address 0x0 is upgraded (first slot).
    //         Note immutable and constants do not take up storage slots so they can come before.
    address internal _avoImplementation;

    /// @notice nonce that is incremented for every `cast` / `castAuthorized` transaction (unless it uses a non-sequential nonce)
    uint88 public avoSafeNonce;

    /// @dev flag set temporarily to signal various cases:
    /// 0 -> default state
    /// 1 -> triggered request had valid signatures, `_callTargets` can be executed
    /// 20 / 21 -> flashloan receive can be executed (set to original `CastParams.id` input param)
    uint8 internal _status;
}

abstract contract AvoCoreVariablesSlot1 {
    /// @notice owner of the Avocado smart wallet
    //  @dev theoretically immutable, can only be set in initialize (at proxy clone AvoFactory deployment)
    address public owner;

    /// @dev Initializable.sol variables (modified from OpenZeppelin), see ./lib folder
    /// @dev Indicates that the contract has been initialized.
    uint8 internal _initialized;
    /// @dev Indicates that the contract is in the process of being initialized.
    bool internal _initializing;

    // 10 bytes empty
}

abstract contract AvoCoreVariablesSlot2 {
    // contracts deployed before V2 contain two more variables from EIP712Upgradeable: hashed domain separator
    // name and version which were set at initialization (Now we do this in logic contract at deployment as constant)
    // https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/cryptography/EIP712Upgradeable.sol#L32

    // BEFORE VERSION 2.0.0:
    // bytes32 private _HASHED_NAME;

    /// @dev allow-listed signed messages, e.g. for Permit2 Uniswap interaction
    /// mappings are not in sequential storage slot, thus not influenced by previous storage variables
    /// (but consider the slot number in calculating the hash of the key to store).
    mapping(bytes32 => uint256) internal _signedMessages;
}

abstract contract AvoCoreVariablesSlot3 {
    // BEFORE VERSION 2.0.0:
    // bytes32 private _HASHED_VERSION; see comment in storage slot 2

    /// @notice used non-sequential nonces (which can not be used again)
    mapping(bytes32 => uint256) public nonSequentialNonces;
}

abstract contract AvoCoreSlotGaps {
    // create some storage slot gaps for future expansion of AvoCore variables before the customized variables
    // of AvoWallet & AvoMultisig
    uint256[50] private __gaps;
}

abstract contract AvoCoreVariables is
    AvoCoreConstants,
    AvoCoreConstantsOverride,
    AvoCoreVariablesSlot0,
    AvoCoreVariablesSlot1,
    AvoCoreVariablesSlot2,
    AvoCoreVariablesSlot3,
    AvoCoreSlotGaps
{}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { AvoCoreVariables } from "../AvoCoreVariables.sol";

/// @dev contract copied from OpenZeppelin Initializable but with storage vars moved to AvoCoreVariables.sol
/// from OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)
/// see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.1/contracts/proxy/utils/Initializable.sol

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
abstract contract Initializable is AvoCoreVariables {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    // uint8 private _initialized; // -> in AvoCoreVariables

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    // bool private _initializing; // -> in AvoCoreVariables

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
pragma solidity >=0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IAvoFactory } from "./interfaces/IAvoFactory.sol";

// empty interface used for Natspec docs for nice layout in automatically generated docs:
//
/// @title    AvoDepositManager v3.0.0
/// @notice   Handles deposits in a deposit token (e.g. USDC).
/// Note: user balances are tracked off-chain through events by the Avocado infrastructure.
///
/// Upgradeable through AvoDepositManagerProxy
interface AvoDepositManager_V3 {

}

abstract contract AvoDepositManagerConstants {
    /// @notice address of the deposit token (USDC)
    IERC20 public immutable depositToken;

    /// @notice address of the AvoFactory (proxy)
    IAvoFactory public immutable avoFactory;

    constructor(IERC20 depositToken_, IAvoFactory avoFactory_) {
        depositToken = depositToken_;
        avoFactory = avoFactory_;
    }
}

abstract contract AvoDepositManagerStructs {
    /// @notice struct to represent a withdrawal request in storage mapping
    struct WithdrawRequest {
        address to;
        uint256 amount;
    }
}

abstract contract AvoDepositManagerVariables is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    AvoDepositManagerStructs,
    AvoDepositManagerConstants
{
    // @dev variables here start at storage slot 151, before is:
    // - Initializable with storage slot 0:
    // uint8 private _initialized;
    // bool private _initializing;
    // - PausableUpgradeable with slots 1 to 100:
    // uint256[50] private __gap; (from ContextUpgradeable, slot 1 until slot 50)
    // bool private _paused; (at slot 51)
    // uint256[49] private __gap; (slot 52 until slot 100)
    // - OwnableUpgradeable with slots 100 to 150:
    // address private _owner; (at slot 101)
    // uint256[49] private __gap; (slot 102 until slot 150)

    // ---------------- slot 151 -----------------

    /// @notice address to which funds can be withdrawn to. Configurable by owner.
    address public withdrawAddress;

    /// @notice minimum amount which must stay in contract and can not be withdrawn. Configurable by owner.
    uint96 public withdrawLimit;

    // ---------------- slot 152 -----------------

    /// @notice static withdraw fee charged when a withdrawRequest is processed. Configurable by owner.
    uint96 public withdrawFee;

    /// @notice minimum withdraw amount that a user must request to withdraw. Configurable by owner.
    uint96 public minWithdrawAmount;

    // 8 bytes empty

    // ---------------- slot 153 -----------------

    /// @notice allowed auths list (1 = allowed) that can confirm withdraw requests. Configurable by owner.
    mapping(address => uint256) public auths;

    // ---------------- slot 154 -----------------

    /// @notice withdraw requests. unique id -> WithdrawRequest (amount and receiver)
    mapping(bytes32 => WithdrawRequest) public withdrawRequests;
}

abstract contract AvoDepositManagerEvents {
    /// @notice emitted when a deposit occurs through `depositOnBehalf()`
    event Deposit(address indexed sender, address indexed avoSafe, uint256 indexed amount);

    /// @notice emitted when a user requests a withdrawal
    event WithdrawRequested(bytes32 indexed id, address indexed avoSafe, uint256 indexed amount);

    /// @notice emitted when a withdraw request is executed
    event WithdrawProcessed(bytes32 indexed id, address indexed user, uint256 indexed amount, uint256 fee);

    /// @notice emitted when a withdraw request is removed
    event WithdrawRemoved(bytes32 indexed id);

    /// @notice emitted when someone requests a source withdrawal
    event SourceWithdrawRequested(bytes32 indexed id, address indexed user, uint256 indexed amount);

    // ------------------------ Settings events ------------------------
    /// @notice emitted when the withdrawLimit is modified by owner
    event SetWithdrawLimit(uint96 indexed withdrawLimit);
    /// @notice emitted when the withdrawFee is modified by owner
    event SetWithdrawFee(uint96 indexed withdrawFee);
    /// @notice emitted when the minWithdrawAmount is modified by owner
    event SetMinWithdrawAmount(uint96 indexed minWithdrawAmount);
    /// @notice emitted when the withdrawAddress is modified by owner
    event SetWithdrawAddress(address indexed withdrawAddress);
    /// @notice emitted when the auths are modified by owner
    event SetAuth(address indexed auth, bool indexed allowed);
}

abstract contract AvoDepositManagerErrors {
    /// @notice thrown when `msg.sender` is not authorized to access requested functionality
    error AvoDepositManager__Unauthorized();

    /// @notice thrown when invalid params for a method are submitted, e.g. zero address as input param
    error AvoDepositManager__InvalidParams();

    /// @notice thrown when a withdraw request already exists
    error AvoDepositManager__RequestAlreadyExist();

    /// @notice thrown when a withdraw request does not exist
    error AvoDepositManager__RequestNotExist();

    /// @notice thrown when a withdraw request does not at least request `minWithdrawAmount`
    error AvoDepositManager__MinWithdraw();

    /// @notice thrown when a withdraw request amount does not cover the withdraw fee at processing time
    error AvoDepositManager__FeeNotCovered();
}

abstract contract AvoDepositManagerCore is
    AvoDepositManagerConstants,
    AvoDepositManagerVariables,
    AvoDepositManagerErrors,
    AvoDepositManagerEvents
{
    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/

    /// @dev checks if an address is not the zero address
    modifier validAddress(address address_) {
        if (address_ == address(0)) {
            revert AvoDepositManager__InvalidParams();
        }
        _;
    }

    /// @dev checks if `msg.sender` is an allowed auth
    modifier onlyAuths() {
        // @dev using inverted positive case to save gas
        if (!(auths[msg.sender] == 1 || msg.sender == owner())) {
            revert AvoDepositManager__Unauthorized();
        }
        _;
    }

    /// @dev checks if `address_` is an Avocado smart wallet (through the AvoFactory)
    modifier onlyAvoSafe(address address_) {
        if (avoFactory.isAvoSafe(address_) == false) {
            revert AvoDepositManager__Unauthorized();
        }
        _;
    }

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    constructor(
        IERC20 depositToken_,
        IAvoFactory avoFactory_
    )
        validAddress(address(depositToken_))
        validAddress(address(avoFactory_))
        AvoDepositManagerConstants(depositToken_, avoFactory_)
    {
        // ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /***********************************|
    |               INTERNAL            |
    |__________________________________*/

    /// @dev handles a withdraw request for `amount_` for `msg.sender`, giving it a `uniqueId_` and storing it
    function _handleRequestWithdraw(uint256 amount_) internal returns (bytes32 uniqueId_) {
        if (amount_ < minWithdrawAmount || amount_ == 0) {
            revert AvoDepositManager__MinWithdraw();
        }

        // get a unique id based on block timestamp, sender and amount
        uniqueId_ = keccak256(abi.encode(block.timestamp, msg.sender, amount_));

        if (withdrawRequests[uniqueId_].amount > 0) {
            revert AvoDepositManager__RequestAlreadyExist();
        }

        withdrawRequests[uniqueId_] = WithdrawRequest(msg.sender, amount_);
    }
}

abstract contract AvoDepositManagerOwnerActions is AvoDepositManagerCore {
    /// @notice                 Sets new withdraw limit. Only callable by owner.
    /// @param withdrawLimit_   new value
    function setWithdrawLimit(uint96 withdrawLimit_) external onlyOwner {
        withdrawLimit = withdrawLimit_;
        emit SetWithdrawLimit(withdrawLimit_);
    }

    /// @notice                 Sets new withdraw fee (in absolute amount). Only callable by owner.
    /// @param withdrawFee_     new value
    function setWithdrawFee(uint96 withdrawFee_) external onlyOwner {
        // minWithdrawAmount must cover the withdrawFee at all times
        if (minWithdrawAmount < withdrawFee_) {
            revert AvoDepositManager__InvalidParams();
        }
        withdrawFee = withdrawFee_;
        emit SetWithdrawFee(withdrawFee_);
    }

    /// @notice                     Sets new min withdraw amount. Only callable by owner.
    /// @param minWithdrawAmount_   new value
    function setMinWithdrawAmount(uint96 minWithdrawAmount_) external onlyOwner {
        // minWithdrawAmount must cover the withdrawFee at all times
        if (minWithdrawAmount_ < withdrawFee) {
            revert AvoDepositManager__InvalidParams();
        }
        minWithdrawAmount = minWithdrawAmount_;
        emit SetMinWithdrawAmount(minWithdrawAmount_);
    }

    /// @notice                   Sets new withdraw address. Only callable by owner.
    /// @param withdrawAddress_   new value
    function setWithdrawAddress(address withdrawAddress_) external onlyOwner validAddress(withdrawAddress_) {
        withdrawAddress = withdrawAddress_;
        emit SetWithdrawAddress(withdrawAddress_);
    }

    /// @notice                   Sets an address as allowed auth or not. Only callable by owner.
    /// @param auth_              address to set auth value for
    /// @param allowed_           bool flag for whether address is allowed as auth or not
    function setAuth(address auth_, bool allowed_) external onlyOwner validAddress(auth_) {
        auths[auth_] = allowed_ ? 1 : 0;
        emit SetAuth(auth_, allowed_);
    }

    /// @notice unpauses the contract, re-enabling withdraw requests and processing. Only callable by owner.
    function unpause() external onlyOwner {
        _unpause();
    }
}

abstract contract AvoDepositManagerAuthsActions is AvoDepositManagerCore {
    using SafeERC20 for IERC20;

    /// @notice             Authorizes and processes a withdraw request. Only callable by auths & owner.
    /// @param withdrawId_  unique withdraw request id as created in `requestWithdraw()`
    function processWithdraw(bytes32 withdrawId_) external onlyAuths whenNotPaused {
        WithdrawRequest memory withdrawRequest_ = withdrawRequests[withdrawId_];

        if (withdrawRequest_.amount == 0) {
            revert AvoDepositManager__RequestNotExist();
        }

        uint256 withdrawFee_ = withdrawFee;

        if (withdrawRequest_.amount < withdrawFee_) {
            // withdrawRequest_.amount could be < withdrawFee if config value was modified after request was created
            revert AvoDepositManager__FeeNotCovered();
        }

        uint256 withdrawAmount_;
        unchecked {
            // because of if statement above we know this can not underflow
            withdrawAmount_ = withdrawRequest_.amount - withdrawFee_;
        }
        delete withdrawRequests[withdrawId_];

        depositToken.safeTransfer(withdrawRequest_.to, withdrawAmount_);

        emit WithdrawProcessed(withdrawId_, withdrawRequest_.to, withdrawAmount_, withdrawFee_);
    }

    /// @notice pauses the contract, temporarily blocking withdraw requests and processing.
    ///         Only callable by auths & owner. Unpausing can only be triggered by owner.
    function pause() external onlyAuths {
        _pause();
    }
}

contract AvoDepositManager is AvoDepositManagerCore, AvoDepositManagerOwnerActions, AvoDepositManagerAuthsActions {
    using SafeERC20 for IERC20;

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    constructor(IERC20 depositToken_, IAvoFactory avoFactory_) AvoDepositManagerCore(depositToken_, avoFactory_) {}

    /// @notice         initializes the contract for `owner_` as owner, and various config values regarding withdrawals.
    ///                 Starts the contract in paused state.
    /// @param owner_              address of owner authorized to withdraw funds and set config values, auths etc.
    /// @param withdrawAddress_    address to which funds can be withdrawn to
    /// @param withdrawLimit_      minimum amount which must stay in contract and can not be withdrawn
    /// @param minWithdrawAmount_  static withdraw fee charged when a withdrawRequest is processed
    /// @param withdrawFee_        minimum withdraw amount that a user must request to withdraw
    function initialize(
        address owner_,
        address withdrawAddress_,
        uint96 withdrawLimit_,
        uint96 minWithdrawAmount_,
        uint96 withdrawFee_
    ) public initializer validAddress(owner_) validAddress(withdrawAddress_) {
        // minWithdrawAmount must cover the withdrawFee at all times
        if (minWithdrawAmount_ < withdrawFee_) {
            revert AvoDepositManager__InvalidParams();
        }

        _transferOwnership(owner_);

        // contract will be paused at start, must be manually unpaused
        _pause();

        withdrawAddress = withdrawAddress_;
        withdrawLimit = withdrawLimit_;
        minWithdrawAmount = minWithdrawAmount_;
        withdrawFee = withdrawFee_;
    }

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    /// @notice checks if a certain address `auth_` is an allowed auth
    function isAuth(address auth_) external view returns (bool) {
        return auths[auth_] == 1 || auth_ == owner();
    }

    /// @notice           Deposits `amount_` of deposit token to this contract and emits the `Deposit` event,
    ///                   with `receiver_` address used for off-chain tracking
    /// @param receiver_  address receiving funds via indirect off-chain tracking
    /// @param amount_    amount to deposit
    function depositOnBehalf(address receiver_, uint256 amount_) external validAddress(receiver_) {
        // @dev we can't use onlyAvoSafe modifier here because it would only work for an already deployed AvoSafe
        depositToken.safeTransferFrom(msg.sender, address(this), amount_);

        emit Deposit(msg.sender, receiver_, amount_);
    }

    /// @notice             removes a withdraw request, essentially denying it or retracting it.
    ///                     Only callable by auths or withdraw request receiver.
    /// @param withdrawId_  unique withdraw request id as created in `requestWithdraw()`
    function removeWithdrawRequest(bytes32 withdrawId_) external {
        WithdrawRequest memory withdrawRequest_ = withdrawRequests[withdrawId_];

        if (withdrawRequest_.amount == 0) {
            revert AvoDepositManager__RequestNotExist();
        }

        // only auths (& owner) or withdraw request receiver can remove a withdraw request
        // using inverted positive case to save gas
        if (!(auths[msg.sender] == 1 || msg.sender == owner() || msg.sender == withdrawRequest_.to)) {
            revert AvoDepositManager__Unauthorized();
        }

        delete withdrawRequests[withdrawId_];

        emit WithdrawRemoved(withdrawId_);
    }

    /// @notice Withdraws balance of deposit token down to `withdrawLimit` to the configured `withdrawAddress`
    function withdraw() external {
        IERC20 depositToken_ = depositToken;
        uint256 withdrawLimit_ = withdrawLimit;

        uint256 balance_ = depositToken_.balanceOf(address(this));
        if (balance_ > withdrawLimit_) {
            uint256 withdrawAmount_;
            unchecked {
                // can not underflow because of if statement just above
                withdrawAmount_ = balance_ - withdrawLimit_;
            }

            depositToken_.safeTransfer(withdrawAddress, withdrawAmount_);
        }
    }

    /// @notice         Requests withdrawal of `amount_`  of gas balance. Only callable by Avocado smart wallets.
    /// @param amount_  amount to withdraw
    /// @return         uniqueId_ the unique withdraw request id used to trigger processing
    function requestWithdraw(
        uint256 amount_
    ) external whenNotPaused onlyAvoSafe(msg.sender) returns (bytes32 uniqueId_) {
        uniqueId_ = _handleRequestWithdraw(amount_);
        emit WithdrawRequested(uniqueId_, msg.sender, amount_);
    }

    /// @notice         same as `requestWithdraw()` but anyone can request withdrawal of funds, not just
    ///                 Avocado smart wallets. Used for the Revenue sharing program.
    /// @param amount_  amount to withdraw
    /// @return         uniqueId_ the unique withdraw request id used to trigger processing
    function requestSourceWithdraw(uint256 amount_) external whenNotPaused returns (bytes32 uniqueId_) {
        uniqueId_ = _handleRequestWithdraw(amount_);
        emit SourceWithdrawRequested(uniqueId_, msg.sender, amount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/// @title    AvoDepositManagerProxy
/// @notice   Default ERC1967Proxy for AvoDepositManager
contract AvoDepositManagerProxy is TransparentUpgradeableProxy {
    constructor(
        address logic_,
        address admin_,
        bytes memory data_
    ) payable TransparentUpgradeableProxy(logic_, admin_, data_) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { AvoMultiSafe } from "./AvoMultiSafe.sol";
import { IAvoWalletV3 } from "./interfaces/IAvoWalletV3.sol";
import { IAvoMultisigV3 } from "./interfaces/IAvoMultisigV3.sol";
import { IAvoVersionsRegistry } from "./interfaces/IAvoVersionsRegistry.sol";
import { IAvoFactory } from "./interfaces/IAvoFactory.sol";
import { IAvoForwarder } from "./interfaces/IAvoForwarder.sol";

// --------------------------- DEVELOPER NOTES -----------------------------------------
// @dev To deploy a new version of AvoSafe (proxy), the new factory contract must be deployed
// and AvoFactoryProxy upgraded to that new contract (to update the cached bytecode).
// -------------------------------------------------------------------------------------

// empty interface used for Natspec docs for nice layout in automatically generated docs:
//
/// @title  AvoFactory v3.0.0
/// @notice Deploys Avocado smart wallet contracts at deterministic addresses using Create2.
///
/// Upgradeable through AvoFactoryProxy
interface AvoFactory_V3 {

}

abstract contract AvoFactoryErrors {
    /// @notice thrown when trying to deploy an AvoSafe for a smart contract
    error AvoFactory__NotEOA();

    /// @notice thrown when a caller is not authorized to execute a certain action
    error AvoFactory__Unauthorized();

    /// @notice thrown when a method is called with invalid params (e.g. zero address)
    error AvoFactory__InvalidParams();
}

abstract contract AvoFactoryConstants is AvoFactoryErrors, IAvoFactory {
    /// @notice hardcoded AvoSafe creation code.
    //
    // Hardcoding this allows us to enable the optimizer without affecting the bytecode of the AvoSafe proxy,
    // which would break the deterministic address of previous versions.
    // in next version, also hardcode the creation code for the avoMultiSafe
    bytes public constant avoSafeCreationCode =
        hex"608060405234801561001057600080fd5b506000803373ffffffffffffffffffffffffffffffffffffffff166040518060400160405280600481526020017f8e7daf690000000000000000000000000000000000000000000000000000000081525060405161006e91906101a5565b6000604051808303816000865af19150503d80600081146100ab576040519150601f19603f3d011682016040523d82523d6000602084013e6100b0565b606091505b50915091506000602082015190508215806100e2575060008173ffffffffffffffffffffffffffffffffffffffff163b145b156100ec57600080fd5b806000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505050506101bc565b600081519050919050565b600081905092915050565b60005b8381101561016857808201518184015260208101905061014d565b60008484015250505050565b600061017f82610134565b610189818561013f565b935061019981856020860161014a565b80840191505092915050565b60006101b18284610174565b915081905092915050565b60aa806101ca6000396000f3fe608060405273ffffffffffffffffffffffffffffffffffffffff600054167f87e9052a0000000000000000000000000000000000000000000000000000000060003503604f578060005260206000f35b3660008037600080366000845af43d6000803e8060008114606f573d6000f35b3d6000fdfea26469706673582212206b87e9571aaea9ed523b568c544f1e27605a9e60767f9b6c9efbab3ad8293ea864736f6c63430008110033";

    /// @notice cached AvoSafe bytecode hash to optimize gas usage
    bytes32 public constant avoSafeBytecode = keccak256(abi.encodePacked(avoSafeCreationCode));

    /// @notice cached AvoSafeMultsig bytecode hash to optimize gas usage
    bytes32 public constant avoMultiSafeBytecode = keccak256(abi.encodePacked(type(AvoMultiSafe).creationCode));

    /// @notice  registry holding the valid versions (addresses) for Avocado smart wallet implementation contracts.
    ///          The registry is used to verify a valid version before setting a new `avoWalletImpl` / `avoMultisigImpl`
    ///          as default for new deployments.
    IAvoVersionsRegistry public immutable avoVersionsRegistry;

    constructor(IAvoVersionsRegistry avoVersionsRegistry_) {
        avoVersionsRegistry = avoVersionsRegistry_;

        if (avoSafeBytecode != 0x9aa119706de4bc0b1d341ea3b741a89ce1da096034c271d93473502675bb2c11) {
            revert AvoFactory__InvalidParams();
        }
        // @dev in next version, add the same check for (hardcoded) avoMultiSafeBytecode
    }
}

abstract contract AvoFactoryVariables is AvoFactoryConstants, Initializable {
    // @dev Before variables here are vars from Initializable:
    // uint8 private _initialized;
    // bool private _initializing;

    /// @notice Avo wallet logic contract address that new AvoSafe deployments point to.
    ///         Modifiable only by `avoVersionsRegistry`.
    address public avoWalletImpl;

    // 10 bytes empty

    // ----------------------- slot 1 ---------------------------

    /// @notice AvoMultisig logic contract address that new AvoMultiSafe deployments point to.
    ///         Modifiable only by `avoVersionsRegistry`.
    address public avoMultisigImpl;
}

abstract contract AvoFactoryEvents {
    /// @notice Emitted when a new AvoSafe has been deployed
    event AvoSafeDeployed(address indexed owner, address indexed avoSafe);

    /// @notice Emitted when a new AvoSafe has been deployed with a non-default version
    event AvoSafeDeployedWithVersion(address indexed owner, address indexed avoSafe, address indexed version);

    /// @notice Emitted when a new AvoMultiSafe has been deployed
    event AvoMultiSafeDeployed(address indexed owner, address indexed avoMultiSafe);

    /// @notice Emitted when a new AvoMultiSafe has been deployed with a non-default version
    event AvoMultiSafeDeployedWithVersion(address indexed owner, address indexed avoMultiSafe, address indexed version);
}

abstract contract AvoForwarderCore is AvoFactoryErrors, AvoFactoryConstants, AvoFactoryVariables, AvoFactoryEvents {
    constructor(IAvoVersionsRegistry avoVersionsRegistry_) AvoFactoryConstants(avoVersionsRegistry_) {
        if (address(avoVersionsRegistry_) == address(0)) {
            revert AvoFactory__InvalidParams();
        }

        // Ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }
}

contract AvoFactory is AvoForwarderCore {
    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/

    /// @dev reverts if `owner_` is a contract
    modifier onlyEOA(address owner_) {
        if (Address.isContract(owner_)) {
            revert AvoFactory__NotEOA();
        }
        _;
    }

    /// @dev reverts if `msg.sender` is not `avoVersionsRegistry`
    modifier onlyRegistry() {
        if (msg.sender != address(avoVersionsRegistry)) {
            revert AvoFactory__Unauthorized();
        }
        _;
    }

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    /// @notice constructor sets the immutable `avoVersionsRegistry` address
    constructor(IAvoVersionsRegistry avoVersionsRegistry_) AvoForwarderCore(avoVersionsRegistry_) {}

    /// @notice initializes the contract
    function initialize() public initializer {}

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    /// @inheritdoc IAvoFactory
    function isAvoSafe(address avoSafe_) external view returns (bool) {
        if (avoSafe_ == address(0)) {
            return false;
        }
        if (Address.isContract(avoSafe_) == false) {
            // can not recognize isAvoSafe when not yet deployed
            return false;
        }

        // get the owner from the Avocado smart wallet
        try IAvoWalletV3(avoSafe_).owner() returns (address owner_) {
            // compute the AvoSafe address for that owner
            address computedAddress_ = computeAddress(owner_);
            if (computedAddress_ == avoSafe_) {
                // computed address for owner is an avoSafe because it matches a computed address,
                // which includes the address of this contract itself so it also guarantees the AvoSafe
                // was deployed by the AvoFactory.
                return true;
            } else {
                // if it is not a computed address match for the AvoSafe, try for the Multisig too
                computedAddress_ = computeAddressMultisig(owner_);
                return computedAddress_ == avoSafe_;
            }
        } catch {
            // if fetching owner doesn't work, it can not be an Avocado smart wallet
            return false;
        }
    }

    /// @inheritdoc IAvoFactory
    function deploy(address owner_) external onlyEOA(owner_) returns (address deployedAvoSafe_) {
        // deploy AvoSafe deterministically using low level CREATE2 opcode to use hardcoded AvoSafe bytecode
        bytes32 salt_ = _getSalt(owner_);
        bytes memory byteCode_ = avoSafeCreationCode;
        assembly {
            deployedAvoSafe_ := create2(0, add(byteCode_, 0x20), mload(byteCode_), salt_)
        }

        // initialize AvoWallet through proxy with IAvoWallet interface
        IAvoWalletV3(deployedAvoSafe_).initialize(owner_);

        emit AvoSafeDeployed(owner_, deployedAvoSafe_);
    }

    /// @inheritdoc IAvoFactory
    function deployWithVersion(
        address owner_,
        address avoWalletVersion_
    ) external onlyEOA(owner_) returns (address deployedAvoSafe_) {
        avoVersionsRegistry.requireValidAvoWalletVersion(avoWalletVersion_);

        // deploy AvoSafe deterministically using low level CREATE2 opcode to use hardcoded AvoSafe bytecode
        bytes32 salt_ = _getSalt(owner_);
        bytes memory byteCode_ = avoSafeCreationCode;
        assembly {
            deployedAvoSafe_ := create2(0, add(byteCode_, 0x20), mload(byteCode_), salt_)
        }

        // initialize AvoWallet through proxy with IAvoWallet interface
        IAvoWalletV3(deployedAvoSafe_).initializeWithVersion(owner_, avoWalletVersion_);

        emit AvoSafeDeployedWithVersion(owner_, deployedAvoSafe_, avoWalletVersion_);
    }

    /// @inheritdoc IAvoFactory
    function deployMultisig(address owner_) external onlyEOA(owner_) returns (address deployedAvoMultiSafe_) {
        // deploy AvoMultiSafe deterministically using CREATE2 opcode (through specifying salt)
        // Note: because `AvoMultiSafe` bytecode differs from `AvoSafe` bytecode, the deterministic address
        // will be different from the deployed AvoSafes through `deploy` / `deployWithVersion`
        deployedAvoMultiSafe_ = address(new AvoMultiSafe{ salt: _getSaltMultisig(owner_) }());

        // initialize AvoMultisig through proxy with IAvoMultisig interface
        IAvoMultisigV3(deployedAvoMultiSafe_).initialize(owner_);

        emit AvoMultiSafeDeployed(owner_, deployedAvoMultiSafe_);
    }

    /// @inheritdoc IAvoFactory
    function deployMultisigWithVersion(
        address owner_,
        address avoMultisigVersion_
    ) external onlyEOA(owner_) returns (address deployedAvoMultiSafe_) {
        avoVersionsRegistry.requireValidAvoMultisigVersion(avoMultisigVersion_);

        // deploy AvoMultiSafe deterministically using CREATE2 opcode (through specifying salt)
        // Note: because `AvoMultiSafe` bytecode differs from `AvoSafe` bytecode, the deterministic address
        // will be different from the deployed AvoSafes through `deploy()` / `deployWithVersion`
        deployedAvoMultiSafe_ = address(new AvoMultiSafe{ salt: _getSaltMultisig(owner_) }());

        // initialize AvoMultisig through proxy with IAvoMultisig interface
        IAvoMultisigV3(deployedAvoMultiSafe_).initializeWithVersion(owner_, avoMultisigVersion_);

        emit AvoMultiSafeDeployedWithVersion(owner_, deployedAvoMultiSafe_, avoMultisigVersion_);
    }

    /// @inheritdoc IAvoFactory
    function computeAddress(address owner_) public view returns (address computedAddress_) {
        if (Address.isContract(owner_)) {
            // owner of a AvoSafe must be an EOA, if it's a contract return zero address
            return address(0);
        }

        // replicate Create2 address determination logic
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _getSalt(owner_), avoSafeBytecode));

        // cast last 20 bytes of hash to address via low level assembly
        assembly {
            computedAddress_ := and(hash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @inheritdoc IAvoFactory
    function computeAddressMultisig(address owner_) public view returns (address computedAddress_) {
        if (Address.isContract(owner_)) {
            // owner of a AvoMultiSafe must be an EOA, if it's a contract return zero address
            return address(0);
        }

        // replicate Create2 address determination logic
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _getSaltMultisig(owner_), avoMultiSafeBytecode)
        );

        // cast last 20 bytes of hash to address via low level assembly
        assembly {
            computedAddress_ := and(hash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /***********************************|
    |            ONLY  REGISTRY         |
    |__________________________________*/

    /// @inheritdoc IAvoFactory
    function setAvoWalletImpl(address avoWalletImpl_) external onlyRegistry {
        // do not use `registry.requireValidAvoWalletVersion()` because sender is registry anyway
        avoWalletImpl = avoWalletImpl_;
    }

    /// @inheritdoc IAvoFactory
    function setAvoMultisigImpl(address avoMultisigImpl_) external onlyRegistry {
        // do not `registry.requireValidAvoMultisigVersion()` because sender is registry anyway
        avoMultisigImpl = avoMultisigImpl_;
    }

    /***********************************|
    |              INTERNAL             |
    |__________________________________*/

    /// @dev            gets the salt used for deterministic deployment for `owner_`
    /// @param owner_   AvoSafe owner
    /// @return         the bytes32 (keccak256) salt
    function _getSalt(address owner_) internal pure returns (bytes32) {
        // only owner is used as salt
        // no extra salt is needed because even if another version of AvoFactory would be deployed,
        // deterministic deployments take into account the deployers address (i.e. the factory address)
        return keccak256(abi.encode(owner_));
    }

    /// @dev            gets the salt used for deterministic Multisig deployment for `owner_`
    /// @param owner_   AvoMultiSafe owner
    /// @return         the bytes32 (keccak256) salt
    function _getSaltMultisig(address owner_) internal pure returns (bytes32) {
        // only owner is used as salt
        // no extra salt is needed because even if another version of AvoFactory would be deployed,
        // deterministic deployments take into account the deployers address (i.e. the factory address)
        return keccak256(abi.encode(owner_));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/// @title    AvoFactoryProxy
/// @notice   Default ERC1967Proxy for AvoFactory
contract AvoFactoryProxy is TransparentUpgradeableProxy {
    constructor(
        address logic_,
        address admin_,
        bytes memory data_
    ) payable TransparentUpgradeableProxy(logic_, admin_, data_) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { IAvoFactory } from "./interfaces/IAvoFactory.sol";
import { IAvoForwarder } from "./interfaces/IAvoForwarder.sol";
import { IAvoWalletV1 } from "./interfaces/IAvoWalletV1.sol";
import { IAvoWalletV2 } from "./interfaces/IAvoWalletV2.sol";
import { IAvoWalletV3 } from "./interfaces/IAvoWalletV3.sol";
import { IAvoMultisigV3 } from "./interfaces/IAvoMultisigV3.sol";
import { IAvoSafe } from "./AvoSafe.sol";

// empty interface used for Natspec docs for nice layout in automatically generated docs:
//
/// @title  AvoForwarder v3.0.0
/// @notice Only compatible with forwarding `cast` calls to Avocado smart wallet contracts.
/// This is not a generic forwarder.
/// This is NOT a "TrustedForwarder" as proposed in EIP-2770, see info in Avocado smart wallet contracts.
///
/// Does not validate the EIP712 signature (instead this is done in the smart wallet itself).
///
/// Upgradeable through AvoForwarderProxy
interface AvoForwarder_V3 {

}

abstract contract AvoForwarderConstants is IAvoForwarder {
    /// @notice AvoFactory (proxy) used to deploy new Avocado smart wallets.
    //
    // @dev     If this changes then the deployment addresses for Avocado smart wallets change too. A more complex
    //          system with versioning would have to be implemented then for most methods.
    IAvoFactory public immutable avoFactory;

    /// @notice cached AvoSafe Bytecode to optimize gas usage.
    //
    // @dev If this changes because of an AvoSafe change (and AvoFactory upgrade),
    // then this variable must be updated through an upgrade deploying a new AvoForwarder!
    bytes32 public immutable avoSafeBytecode;

    /// @notice cached AvoMultiSafe Bytecode to optimize gas usage.
    //
    // @dev If this changes because of an AvoMultiSafe change (and AvoFactory upgrade),
    // then this variable must be updated through an upgrade deploying a new AvoForwarder!
    bytes32 public immutable avoMultiSafeBytecode;

    constructor(IAvoFactory avoFactory_) {
        avoFactory = avoFactory_;

        // get AvoSafe & AvoMultiSafe bytecode from factory.
        // @dev Note if a new AvoFactory is deployed (upgraded), a new AvoForwarder must be deployed
        // to update these bytecodes. See README for more info.
        avoSafeBytecode = avoFactory.avoSafeBytecode();
        avoMultiSafeBytecode = avoFactory.avoMultiSafeBytecode();
    }
}

abstract contract AvoForwarderVariables is AvoForwarderConstants, Initializable, OwnableUpgradeable {
    // @dev variables here start at storage slot 101, before is:
    // - Initializable with storage slot 0:
    // uint8 private _initialized;
    // bool private _initializing;
    // - OwnableUpgradeable with slots 1 to 100:
    // uint256[50] private __gap; (from ContextUpgradeable, slot 1 until slot 50)
    // address private _owner; (at slot 51)
    // uint256[49] private __gap; (slot 52 until slot 100)

    // ---------------- slot 101 -----------------

    /// @notice allowed broadcasters that can call `execute()` methods. allowed if set to `1`
    mapping(address => uint256) public broadcasters;

    // ---------------- slot 102 -----------------

    /// @notice allowed auths. allowed if set to `1`
    mapping(address => uint256) public auths;
}

abstract contract AvoForwarderErrors {
    /// @notice thrown when a method is called with invalid params (e.g. zero address)
    error AvoForwarder__InvalidParams();

    /// @notice thrown when a caller is not authorized to execute a certain action
    error AvoForwarder__Unauthorized();

    /// @notice thrown when trying to execute legacy methods for a not yet deployed Avocado smart wallet
    error AvoForwarder__LegacyVersionNotDeployed();
}

abstract contract AvoForwarderStructs {
    /// @notice struct mapping an address value to a boolean flag.
    //
    // @dev when used as input param, removes need to make sure two input arrays are of same length etc.
    struct AddressBool {
        address addr;
        bool value;
    }
}

abstract contract AvoForwarderEvents is AvoForwarderStructs {
    /// @notice emitted when all actions for `cast()` in an `execute()` method are executed successfully
    event Executed(
        address indexed avoSafeOwner,
        address indexed avoSafeAddress,
        address indexed source,
        bytes metadata
    );

    /// @notice emitted if one of the actions for `cast()` in an `execute()` method fails
    event ExecuteFailed(
        address indexed avoSafeOwner,
        address indexed avoSafeAddress,
        address indexed source,
        bytes metadata,
        string reason
    );

    /// @notice emitted if a broadcaster's allowed status is updated
    event BroadcasterUpdated(address indexed broadcaster, bool indexed status);

    /// @notice emitted if an auth's allowed status is updated
    event AuthUpdated(address indexed auth, bool indexed status);
}

abstract contract AvoForwarderCore is
    AvoForwarderConstants,
    AvoForwarderVariables,
    AvoForwarderStructs,
    AvoForwarderEvents,
    AvoForwarderErrors
{
    /***********************************|
    |             MODIFIERS             |
    |__________________________________*/

    /// @dev checks if `msg.sender` is an allowed broadcaster
    modifier onlyBroadcaster() {
        if (broadcasters[msg.sender] != 1) {
            revert AvoForwarder__Unauthorized();
        }
        _;
    }

    /// @dev checks if an address is not the zero address
    modifier validAddress(address _address) {
        if (_address == address(0)) {
            revert AvoForwarder__InvalidParams();
        }
        _;
    }

    /***********************************|
    |            CONSTRUCTOR            |
    |__________________________________*/

    constructor(IAvoFactory avoFactory_) validAddress(address(avoFactory_)) AvoForwarderConstants(avoFactory_) {
        // Ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /***********************************|
    |              INTERNAL             |
    |__________________________________*/

    /// @dev gets or if necessary deploys an AvoSafe for owner `from_` and returns the address
    function _getDeployedAvoWallet(address from_) internal returns (address) {
        address computedAvoSafeAddress_ = _computeAvoSafeAddress(from_);
        if (Address.isContract(computedAvoSafeAddress_)) {
            return computedAvoSafeAddress_;
        } else {
            return avoFactory.deploy(from_);
        }
    }

    /// @dev gets or if necessary deploys an AvoMultiSafe for owner `from_` and returns the address
    function _getDeployedAvoMultisig(address from_) internal returns (address) {
        address computedAvoSafeAddress_ = _computeAvoSafeAddressMultisig(from_);
        if (Address.isContract(computedAvoSafeAddress_)) {
            return computedAvoSafeAddress_;
        } else {
            return avoFactory.deployMultisig(from_);
        }
    }

    /// @dev computes the deterministic contract address `computedAddress_` for an AvoSafe deployment for `owner_`
    function _computeAvoSafeAddress(address owner_) internal view returns (address computedAddress_) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(avoFactory), _getSalt(owner_), avoSafeBytecode)
        );

        // cast last 20 bytes of hash to address via low level assembly
        assembly {
            computedAddress_ := and(hash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @dev computes the deterministic contract address `computedAddress_` for an AvoMultiSafe deployment for `owner_`
    function _computeAvoSafeAddressMultisig(address owner_) internal view returns (address computedAddress_) {
        // replicate Create2 address determination logic
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(avoFactory), _getSaltMultisig(owner_), avoMultiSafeBytecode)
        );

        // cast last 20 bytes of hash to address via low level assembly
        assembly {
            computedAddress_ := and(hash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @dev gets the bytes32 salt used for deterministic deployment for `owner_`
    function _getSalt(address owner_) internal pure returns (bytes32) {
        // only owner is used as salt
        // no extra salt is needed because even if another version of AvoFactory would be deployed,
        // deterministic deployments take into account the deployers address (i.e. the factory address)
        return keccak256(abi.encode(owner_));
    }

    /// @dev gets the bytes32 salt used for deterministic Multisig deployment for `owner_`
    function _getSaltMultisig(address owner_) internal pure returns (bytes32) {
        // only owner is used as salt
        // no extra salt is needed because even if another version of AvoFactory would be deployed,
        // deterministic deployments take into account the deployers address (i.e. the factory address)
        return keccak256(abi.encode(owner_));
    }

    /// @dev gets the *already*  deployed AvoWallet (not Multisig) for legacy versions.
    ///      reverts with `AvoForwarder__LegacyVersionNotDeployed()` it wallet is not yet deployed
    function _getDeployedLegacyAvoWallet(address from_) internal view returns (address) {
        // For legacy versions, AvoWallet must already be deployed
        address computedAvoSafeAddress_ = _computeAvoSafeAddress(from_);
        if (!Address.isContract(computedAvoSafeAddress_)) {
            revert AvoForwarder__LegacyVersionNotDeployed();
        }

        return computedAvoSafeAddress_;
    }
}

abstract contract AvoForwarderViews is AvoForwarderCore {
    /// @notice checks if a `broadcaster_` address is an allowed broadcaster
    function isBroadcaster(address broadcaster_) external view returns (bool) {
        return broadcasters[broadcaster_] == 1;
    }

    /// @notice checks if an `auth_` address is an allowed auth
    function isAuth(address auth_) external view returns (bool) {
        return auths[auth_] == 1;
    }

    /// @notice        Retrieves the current avoSafeNonce of an AvoSafe for `owner_` address.
    ///                Needed for signatures.
    /// @param owner_  AvoSafe owner to retrieve the nonce for.
    /// @return        returns the avoSafeNonce for the owner necessary to sign a meta transaction
    function avoSafeNonce(address owner_) external view returns (uint88) {
        address avoAddress_ = _computeAvoSafeAddress(owner_);
        if (Address.isContract(avoAddress_)) {
            return IAvoWalletV3(avoAddress_).avoSafeNonce();
        }

        // defaults to 0 if not yet deployed
        return 0;
    }

    /// @notice        Retrieves the current AvoWallet implementation name for `owner_` address.
    ///                Needed for signatures.
    /// @param owner_  AvoSafe owner to retrieve the name for.
    /// @return        returns the domain separator name for the `owner_` necessary to sign a meta transaction
    function avoWalletVersionName(address owner_) external view returns (string memory) {
        address avoAddress_ = _computeAvoSafeAddress(owner_);
        if (Address.isContract(avoAddress_)) {
            // if AvoWallet is deployed, return value from deployed contract
            return IAvoWalletV3(avoAddress_).DOMAIN_SEPARATOR_NAME();
        }

        // otherwise return default value for current implementation that will be deployed
        return IAvoWalletV3(avoFactory.avoWalletImpl()).DOMAIN_SEPARATOR_NAME();
    }

    /// @notice       Retrieves the current AvoWallet implementation version for `owner_` address.
    ///               Needed for signatures.
    /// @param owner_ AvoSafe owner to retrieve the version for.
    /// @return       returns the domain separator version for the `owner_` necessary to sign a meta transaction
    function avoWalletVersion(address owner_) external view returns (string memory) {
        address avoAddress_ = _computeAvoSafeAddress(owner_);
        if (Address.isContract(avoAddress_)) {
            // if AvoWallet is deployed, return value from deployed contract
            return IAvoWalletV3(avoAddress_).DOMAIN_SEPARATOR_VERSION();
        }

        // otherwise return default value for current implementation that will be deployed
        return IAvoWalletV3(avoFactory.avoWalletImpl()).DOMAIN_SEPARATOR_VERSION();
    }

    /// @notice Computes the deterministic AvoSafe address for `owner_` based on Create2
    function computeAddress(address owner_) external view returns (address) {
        if (Address.isContract(owner_)) {
            // owner of a AvoSafe must be an EOA, if it's a contract return zero address
            return address(0);
        }
        return _computeAvoSafeAddress(owner_);
    }
}

abstract contract AvoForwarderViewsMultisig is AvoForwarderCore {
    /// @notice        Retrieves the current avoSafeNonce of AvoMultisig for `owner_` address.
    ///                Needed for signatures.
    /// @param owner_  AvoMultisig owner to retrieve the nonce for.
    /// @return        returns the avoSafeNonce for the `owner_` necessary to sign a meta transaction
    function avoSafeNonceMultisig(address owner_) external view returns (uint88) {
        address avoAddress_ = _computeAvoSafeAddressMultisig(owner_);
        if (Address.isContract(avoAddress_)) {
            return IAvoMultisigV3(avoAddress_).avoSafeNonce();
        }

        return 0;
    }

    /// @notice        Retrieves the current AvoMultisig implementation name for `owner_` address.
    ///                Needed for signatures.
    /// @param owner_  AvoMultisig owner to retrieve the name for.
    /// @return        returns the domain separator name for the `owner_` necessary to sign a meta transaction
    function avoMultisigVersionName(address owner_) external view returns (string memory) {
        address avoAddress_ = _computeAvoSafeAddressMultisig(owner_);
        if (Address.isContract(avoAddress_)) {
            // if AvoMultisig is deployed, return value from deployed contract
            return IAvoMultisigV3(avoAddress_).DOMAIN_SEPARATOR_NAME();
        }

        // otherwise return default value for current implementation that will be deployed
        return IAvoMultisigV3(avoFactory.avoMultisigImpl()).DOMAIN_SEPARATOR_NAME();
    }

    /// @notice        Retrieves the current AvoMultisig implementation version for `owner_` address.
    ///                Needed for signatures.
    /// @param owner_  AvoMultisig owner to retrieve the version for.
    /// @return        returns the domain separator version for the `owner_` necessary to sign a meta transaction
    function avoMultisigVersion(address owner_) external view returns (string memory) {
        address avoAddress_ = _computeAvoSafeAddressMultisig(owner_);
        if (Address.isContract(avoAddress_)) {
            // if AvoMultisig is deployed, return value from deployed contract
            return IAvoMultisigV3(avoAddress_).DOMAIN_SEPARATOR_VERSION();
        }

        // otherwise return default value for current implementation that will be deployed
        return IAvoMultisigV3(avoFactory.avoMultisigImpl()).DOMAIN_SEPARATOR_VERSION();
    }

    /// @notice Computes the deterministic AvoMultiSafe address for `owner_` based on Create2
    function computeAddressMultisig(address owner_) external view returns (address) {
        if (Address.isContract(owner_)) {
            // owner of a AvoSafe must be an EOA, if it's a contract return zero address
            return address(0);
        }
        return _computeAvoSafeAddressMultisig(owner_);
    }
}

abstract contract AvoForwarderV1 is AvoForwarderCore {
    /// @notice            Calls `cast` on an already deployed AvoWallet. For AvoWallet version 1.0.0.
    ///                    Only callable by allowed broadcasters.
    /// @param from_       AvoSafe owner who signed the transaction
    /// @param actions_    the actions to execute (target, data, value)
    /// @param validUntil_ As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                    Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                    have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas_        As EIP-2770: an amount of gas limit to set for the execution
    ///                    Protects against potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                    See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @param source_     Source like e.g. referral for this tx
    /// @param metadata_   Optional metadata for future flexibility
    /// @param signature_  the EIP712 signature, see verifySig method
    function executeV1(
        address from_,
        IAvoWalletV1.Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) public payable onlyBroadcaster {
        IAvoWalletV1 avoWallet_ = IAvoWalletV1(_getDeployedLegacyAvoWallet(from_));

        (bool success_, string memory revertReason_) = avoWallet_.cast{ value: msg.value }(
            actions_,
            validUntil_,
            gas_,
            source_,
            metadata_,
            signature_
        );

        if (success_ == true) {
            emit Executed(from_, address(avoWallet_), source_, metadata_);
        } else {
            emit ExecuteFailed(from_, address(avoWallet_), source_, metadata_, revertReason_);
        }
    }

    /// @notice            Verify the transaction is valid and can be executed. For AvoWallet version 1.0.0
    ///                    IMPORTANT: Expected to be called via callStatic
    ///                    Does not revert and returns successfully if the input is valid.
    ///                    Reverts if any validation has failed. For instance, if params or either signature or avoSafeNonce are incorrect.
    /// @param from_       AvoSafe owner who signed the transaction
    /// @param actions_    the actions to execute (target, data, value)
    /// @param validUntil_ As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                    Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                    have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas_        As EIP-2770: an amount of gas limit to set for the execution
    ///                    Protects against potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                    See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @param source_     Source like e.g. referral for this tx
    /// @param metadata_   Optional metadata for future flexibility
    /// @param signature_  the EIP712 signature, see verifySig method
    //
    /// @return            returns true if everything is valid, otherwise reverts
    // @dev                 not marked as view because it did potentially state by deploying the AvoWallet for `from_`
    //                      if it does not exist yet. Keeping things as was for legacy version methods.
    function verifyV1(
        address from_,
        IAvoWalletV1.Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) public returns (bool) {
        IAvoWalletV1 avoWallet_ = IAvoWalletV1(_getDeployedLegacyAvoWallet(from_));

        return avoWallet_.verify(actions_, validUntil_, gas_, source_, metadata_, signature_);
    }

    /***********************************|
    |      LEGACY DEPRECATED FOR V1     |
    |__________________________________*/

    /// @dev    DEPRECATED: Use executeV1() instead. Will be removed in the next version
    /// @notice             see executeV1() for details
    function execute(
        address from_,
        IAvoWalletV1.Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external payable onlyBroadcaster {
        return executeV1(from_, actions_, validUntil_, gas_, source_, metadata_, signature_);
    }

    /// @dev    DEPRECATED: Use executeV1() instead. Will be removed in the next version
    /// @notice             see verifyV1() for details
    function verify(
        address from_,
        IAvoWalletV1.Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external returns (bool) {
        return verifyV1(from_, actions_, validUntil_, gas_, source_, metadata_, signature_);
    }
}

abstract contract AvoForwarderV2 is AvoForwarderCore {
    /// @notice             Calls `cast` on an already deployed AvoWallet. For AvoWallet version ~2.
    ///                     Only callable by allowed broadcasters.
    /// @param from_        AvoSafe owner who signed the transaction
    /// @param actions_     the actions to execute (target, data, value, operation)
    /// @param params_      Cast params: validUntil, gas, source, id and metadata
    /// @param signature_   the EIP712 signature, see verifySig method
    function executeV2(
        address from_,
        IAvoWalletV2.Action[] calldata actions_,
        IAvoWalletV2.CastParams calldata params_,
        bytes calldata signature_
    ) external payable onlyBroadcaster {
        IAvoWalletV2 avoWallet_ = IAvoWalletV2(_getDeployedLegacyAvoWallet(from_));

        (bool success_, string memory revertReason_) = avoWallet_.cast{ value: msg.value }(
            actions_,
            params_,
            signature_
        );

        if (success_ == true) {
            emit Executed(from_, address(avoWallet_), params_.source, params_.metadata);
        } else {
            (address(avoWallet_)).call(abi.encodeWithSelector(bytes4(0xb92e87fa), new IAvoWalletV2.Action[](0), 0));

            emit ExecuteFailed(from_, address(avoWallet_), params_.source, params_.metadata, revertReason_);
        }
    }

    /// @notice             Verify the transaction is valid and can be executed. For deployed AvoWallet version ~2
    ///                     IMPORTANT: Expected to be called via callStatic
    ///                     Returns true if valid, reverts otherwise:
    ///                     e.g. if input params, signature or avoSafeNonce etc. are invalid.
    /// @param from_        AvoSafe owner who signed the transaction
    /// @param actions_     the actions to execute (target, data, value, operation)
    /// @param params_      Cast params: validUntil, gas, source, id and metadata
    /// @param signature_   the EIP712 signature, see verifySig method
    /// @return             returns true if everything is valid, otherwise reverts
    //
    // @dev                 not marked as view because it did potentially state by deploying the AvoWallet for `from_`
    //                      if it does not exist yet. Keeping things as was for legacy version methods.
    function verifyV2(
        address from_,
        IAvoWalletV2.Action[] calldata actions_,
        IAvoWalletV2.CastParams calldata params_,
        bytes calldata signature_
    ) external returns (bool) {
        IAvoWalletV2 avoWallet_ = IAvoWalletV2(_getDeployedLegacyAvoWallet(from_));

        return avoWallet_.verify(actions_, params_, signature_);
    }
}

abstract contract AvoForwarderV3 is AvoForwarderCore {
    /// @notice                 Deploys AvoSafe for owner if necessary and calls `cast()` on it. For AvoWallet version ~3.
    ///                         Only callable by allowed broadcasters.
    /// @param from_            AvoSafe owner. Not the one who signed the signature, but rather the owner of the AvoSafe
    ///                         (signature might also be from an authority).
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_   Cast params related to validity of forwarding as instructed and signed
    /// @param signatureParams_ struct for signature and signer:
    ///                         - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                         - signer: address of the signature signer.
    ///                           Must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    function executeV3(
        address from_,
        IAvoWalletV3.CastParams calldata params_,
        IAvoWalletV3.CastForwardParams calldata forwardParams_,
        IAvoWalletV3.SignatureParams calldata signatureParams_
    ) external payable onlyBroadcaster {
        // `_getDeployedAvoWallet()` automatically checks if AvoSafe has to be deployed
        // or if it already exists and simply returns the address in that case
        IAvoWalletV3 avoWallet_ = IAvoWalletV3(_getDeployedAvoWallet(from_));

        (bool success_, string memory revertReason_) = avoWallet_.cast{ value: msg.value }(
            params_,
            forwardParams_,
            signatureParams_
        );

        if (success_ == true) {
            emit Executed(from_, address(avoWallet_), params_.source, params_.metadata);
        } else {
            emit ExecuteFailed(from_, address(avoWallet_), params_.source, params_.metadata, revertReason_);
        }
    }

    /// @notice                 Verify the transaction is valid and can be executed. For AvoWallet version ~3.
    ///                         IMPORTANT: Expected to be called via callStatic.
    ///
    ///                         Returns true if valid, reverts otherwise:
    ///                         e.g. if input params, signature or avoSafeNonce etc. are invalid.
    /// @param from_            AvoSafe owner. Not the one who signed the signature, but rather the owner of the AvoSafe
    ///                         (signature might also be from an authority).
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_   Cast params related to validity of forwarding as instructed and signed
    /// @param signatureParams_ struct for signature and signer:
    ///                         - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                         - signer: address of the signature signer.
    ///                           Must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return                 returns true if everything is valid, otherwise reverts
    //
    // @dev can not be marked as view because it does potentially modify state by deploying the
    //      AvoWallet for `from_` if it does not exist yet. Thus expected to be called via callStatic.
    function verifyV3(
        address from_,
        IAvoWalletV3.CastParams calldata params_,
        IAvoWalletV3.CastForwardParams calldata forwardParams_,
        IAvoWalletV3.SignatureParams calldata signatureParams_
    ) external returns (bool) {
        // `_getDeployedAvoWallet()` automatically checks if AvoSafe has to be deployed
        // or if it already exists and simply returns the address
        IAvoWalletV3 avoWallet_ = IAvoWalletV3(_getDeployedAvoWallet(from_));

        return avoWallet_.verify(params_, forwardParams_, signatureParams_);
    }
}

abstract contract AvoForwarderMultisig is AvoForwarderCore {
    /// @notice                  Deploys AvoMultiSafe for owner if necessary and calls `cast()` on it.
    ///                          For AvoMultisig version ~3.
    ///                          Only callable by allowed broadcasters.
    /// @param from_             AvoMultisig owner
    /// @param params_           Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_    Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_ SignatureParams structs array for signature and signer:
    ///                          - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                            For smart contract signatures it must fulfill the requirements for the relevant
    ///                            smart contract `.isValidSignature()` EIP1271 logic
    ///                          - signer: address of the signature signer.
    ///                            Must match the actual signature signer or refer to the smart contract
    ///                            that must be an allowed signer and validates signature via EIP1271
    function executeMultisigV3(
        address from_,
        IAvoMultisigV3.CastParams calldata params_,
        IAvoMultisigV3.CastForwardParams calldata forwardParams_,
        IAvoMultisigV3.SignatureParams[] calldata signaturesParams_
    ) external payable onlyBroadcaster {
        // `_getDeployedAvoMultisig()` automatically checks if AvoMultiSafe has to be deployed
        // or if it already exists and simply returns the address in that case
        IAvoMultisigV3 avoMultisig_ = IAvoMultisigV3(_getDeployedAvoMultisig(from_));

        (bool success_, string memory revertReason_) = avoMultisig_.cast{ value: msg.value }(
            params_,
            forwardParams_,
            signaturesParams_
        );

        if (success_ == true) {
            emit Executed(from_, address(avoMultisig_), params_.source, params_.metadata);
        } else {
            emit ExecuteFailed(from_, address(avoMultisig_), params_.source, params_.metadata, revertReason_);
        }
    }

    /// @notice                  Verify the transaction is valid and can be executed.
    ///                          IMPORTANT: Expected to be called via callStatic.
    ///
    ///                          Returns true if valid, reverts otherwise:
    ///                          e.g. if input params, signature or avoSafeNonce etc. are invalid.
    /// @param from_             AvoMultiSafe owner
    /// @param params_           Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_    Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_ SignatureParams structs array for signature and signer:
    ///                          - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                            For smart contract signatures it must fulfill the requirements for the relevant
    ///                            smart contract `.isValidSignature()` EIP1271 logic
    ///                          - signer: address of the signature signer.
    ///                            Must match the actual signature signer or refer to the smart contract
    ///                            that must be an allowed signer and validates signature via EIP1271
    /// @return                  returns true if everything is valid, otherwise reverts.
    //
    // @dev can not be marked as view because it does potentially modify state by deploying the
    //      AvoMultisig for `from_` if it does not exist yet. Thus expected to be called via callStatic
    function verifyMultisigV3(
        address from_,
        IAvoMultisigV3.CastParams calldata params_,
        IAvoMultisigV3.CastForwardParams calldata forwardParams_,
        IAvoMultisigV3.SignatureParams[] calldata signaturesParams_
    ) external returns (bool) {
        // `_getDeployedAvoMultisig()` automatically checks if AvoMultiSafe has to be deployed
        // or if it already exists and simply returns the address in that case
        IAvoMultisigV3 avoMultisig_ = IAvoMultisigV3(_getDeployedAvoMultisig(from_));

        return avoMultisig_.verify(params_, forwardParams_, signaturesParams_);
    }
}

abstract contract AvoForwarderOwnerActions is AvoForwarderCore {
    /// @dev modifier checks if `msg.sender` is either owner or allowed auth, reverts if not.
    modifier onlyAuthOrOwner() {
        if (!(msg.sender == owner() || auths[msg.sender] == 1)) {
            revert AvoForwarder__Unauthorized();
        }

        _;
    }

    /// @notice updates allowed status for broadcasters based on `broadcastersStatus_` and emits `BroadcastersUpdated`.
    /// Executable by allowed auths or owner only.
    function updateBroadcasters(AddressBool[] calldata broadcastersStatus_) external onlyAuthOrOwner {
        uint256 length_ = broadcastersStatus_.length;
        for (uint256 i; i < length_; ) {
            if (broadcastersStatus_[i].addr == address(0)) {
                revert AvoForwarder__InvalidParams();
            }

            broadcasters[broadcastersStatus_[i].addr] = broadcastersStatus_[i].value ? 1 : 0;

            emit BroadcasterUpdated(broadcastersStatus_[i].addr, broadcastersStatus_[i].value);

            unchecked {
                i++;
            }
        }
    }

    /// @notice updates allowed status for a auths based on `authsStatus_` and emits `AuthsUpdated`.
    /// Executable by allowed auths or owner only (auths can only remove themselves).
    function updateAuths(AddressBool[] calldata authsStatus_) external onlyAuthOrOwner {
        uint256 length_ = authsStatus_.length;

        bool isMsgSenderOwner = msg.sender == owner();

        for (uint256 i; i < length_; ) {
            if (authsStatus_[i].addr == address(0)) {
                revert AvoForwarder__InvalidParams();
            }

            uint256 setStatus_ = authsStatus_[i].value ? 1 : 0;

            // if `msg.sender` is auth, then operation must be remove and address to be removed must be auth itself
            if (!(isMsgSenderOwner || (setStatus_ == 0 && msg.sender == authsStatus_[i].addr))) {
                revert AvoForwarder__Unauthorized();
            }

            auths[authsStatus_[i].addr] = setStatus_;

            emit AuthUpdated(authsStatus_[i].addr, authsStatus_[i].value);

            unchecked {
                i++;
            }
        }
    }
}

contract AvoForwarder is
    AvoForwarderCore,
    AvoForwarderViews,
    AvoForwarderViewsMultisig,
    AvoForwarderV1,
    AvoForwarderV2,
    AvoForwarderV3,
    AvoForwarderMultisig,
    AvoForwarderOwnerActions
{
    /// @notice constructor sets the immutable `avoFactory` (proxy) address and cached bytecodes derived from it
    constructor(IAvoFactory avoFactory_) AvoForwarderCore(avoFactory_) {}

    /// @notice initializes the contract, setting `owner_` as owner
    function initialize(address owner_) public validAddress(owner_) initializer {
        _transferOwnership(owner_);
    }

    /// @notice reinitiliaze to set `owner`, configuring OwnableUpgradeable added in version 3.0.0.
    ///         Also sets initial allowed broadcasters to `allowedBroadcasters_`.
    ///         Skips setting `owner` if it is already set.
    ///         for fresh deployments, `owner` set in initialize() could not be overwritten
    /// @param owner_                address of owner_ allowed to executed auth limited methods
    /// @param allowedBroadcasters_  initial list of allowed broadcasters to be enabled right away
    function reinitialize(
        address owner_,
        address[] calldata allowedBroadcasters_
    ) public validAddress(owner_) reinitializer(2) {
        if (owner() == address(0)) {
            // only set owner if it's not already set but do not revert so initializer storage var is set to `2` always
            _transferOwnership(owner_);
        }

        // set initial allowed broadcasters
        uint256 length_ = allowedBroadcasters_.length;
        for (uint256 i; i < length_; ) {
            if (allowedBroadcasters_[i] == address(0)) {
                revert AvoForwarder__InvalidParams();
            }

            broadcasters[allowedBroadcasters_[i]] = 1;

            emit BroadcasterUpdated(allowedBroadcasters_[i], true);

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/// @title    AvoForwarderProxy
/// @notice   Default ERC1967Proxy for AvoForwarder
contract AvoForwarderProxy is TransparentUpgradeableProxy {
    constructor(
        address logic_,
        address admin_,
        bytes memory data_
    ) payable TransparentUpgradeableProxy(logic_, admin_, data_) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title   IAvoSafe
/// @notice  interface to access _avoMultisigImpl on-chain
interface IAvoMultiSafe {
    function _avoMultisigImpl() external view returns (address);
}

/// @title      AvoMultiSafe
/// @notice     Proxy for AvoMultisigs as deployed by the AvoFactory.
///             Basic Proxy with fallback to delegate and address for implementation contract at storage 0x0
/// @dev        If this contract changes then the deployment addresses for new AvoSafes through factory change too!!
///             Relayers might want to pass in version as new param then to forward to the correct factory
contract AvoMultiSafe {
    /// @notice address of the AvoMultisig logic / implementation contract. IMPORTANT: SAME STORAGE SLOT AS FOR PROXY
    /// @dev    _avoMultisigImpl MUST ALWAYS be the first declared variable here in the proxy and in the logic contract
    ///         when upgrading, the storage at memory address 0x0 is upgraded (first slot).
    ///         To reduce deployment costs this variable is internal but can still be retrieved with
    ///         _avoMultisigImpl(), see code and comments in fallback below
    address internal _avoMultisigImpl;

    /// @notice   sets _avoMultisigImpl address, fetching it from msg.sender via avoMultisigImpl()
    /// @dev      avoMultisigImpl_ is not an input param to not influence the deterministic Create2 address!
    constructor() {
        // "\x6d\x9b\x93\x8f" is hardcoded bytes of function selector for avoMultisigImpl()
        (bool success_, bytes memory data_) = msg.sender.call(bytes("\x6d\x9b\x93\x8f"));

        address avoMultisigImpl_;
        assembly {
            // cast last 20 bytes of hash to address
            avoMultisigImpl_ := mload(add(data_, 32))
        }

        if (!success_ || avoMultisigImpl_.code.length == 0) {
            revert();
        }

        _avoMultisigImpl = avoMultisigImpl_;
    }

    /// @notice Delegates the current call to `_avoMultisigImpl` unless _avoMultisigImpl() is called
    ///         if _avoMultisigImpl() is called then the address for _avoMultisigImpl is returned
    /// @dev    Mostly based on OpenZeppelin Proxy.sol
    fallback() external payable {
        assembly {
            // load address avoMultisigImpl_ from storage
            let avoMultisigImpl_ := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)

            // first 4 bytes of calldata specify which function to call.
            // if those first 4 bytes == f3b1cd21 (function selector for _avoMultisigImpl()) then we return the _avoMultisigImpl address
            // The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xf3b1cd2100000000000000000000000000000000000000000000000000000000) {
                mstore(0, avoMultisigImpl_) // store address avoMultisigImpl_ at memory address 0x0
                return(0, 0x20) // send first 20 bytes of address at memory address 0x0
            }

            // @dev code below is taken from OpenZeppelin Proxy.sol _delegate function

            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), avoMultisigImpl_, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

abstract contract AvoMultisigErrors {
    /// @notice thrown when a method is called with invalid params (e.g. a zero address as input param)
    error AvoMultisig__InvalidParams();

    /// @notice thrown when a signature is not valid (e.g. not signed by enough allowed signers)
    error AvoMultisig__InvalidSignature();

    /// @notice thrown when someone is trying to execute a in some way auth protected logic
    error AvoMultisig__Unauthorized();

    /// @notice thrown when forwarder/relayer does not send enough gas as the user has defined.
    ///         this error should not be blamed on the user but rather on the relayer
    error AvoMultisig__InsufficientGasSent();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

abstract contract AvoMultisigEvents {
    /// @notice emitted when all actions are executed successfully.
    /// caller = owner / AvoForwarder address. signers = addresses that triggered this execution
    event CastExecuted(address indexed source, address indexed caller, address[] signers, bytes metadata);

    /// @notice emitted if one of the executed actions fails. The reason will be prefixed with the index of the action.
    /// e.g. if action 1 fails, then the reason will be 1_reason
    /// if an action in the flashloan callback fails, it will be prefixed with with two numbers:
    /// e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails, the reason will be 1_2_reason.
    /// caller = owner / AvoForwarder address. signers = addresses that triggered this execution
    /// Note If the signature was invalid, the `signers` array last set element is the signer that is not allowed
    event CastFailed(address indexed source, address indexed caller, address[] signers, string reason, bytes metadata);

    /// @notice emitted when a signer is added as Multisig signer
    event SignerAdded(address indexed signer);

    /// @notice emitted when a signer is removed as Multisig signer
    event SignerRemoved(address indexed signer);

    /// @notice emitted when the required signers count is updated
    event RequiredSignersSet(uint8 indexed requiredSigners);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { SSTORE2 } from "solmate/src/utils/SSTORE2.sol";

import { IAvoVersionsRegistry } from "../interfaces/IAvoVersionsRegistry.sol";
import { IAvoSignersList } from "../interfaces/IAvoSignersList.sol";
import { AvoMultisigErrors } from "./AvoMultisigErrors.sol";
import { AvoCoreConstants, AvoCoreConstantsOverride, AvoCoreVariablesSlot0, AvoCoreVariablesSlot1, AvoCoreVariablesSlot2, AvoCoreVariablesSlot3, AvoCoreSlotGaps } from "../AvoCore/AvoCoreVariables.sol";

abstract contract AvoMultisigConstants is AvoCoreConstants, AvoCoreConstantsOverride, AvoMultisigErrors {
    // constants for EIP712 values (can't be overriden as immutables as other AvoCore constants, strings not supported)
    string public constant DOMAIN_SEPARATOR_NAME = "Avocado-Multisig";
    string public constant DOMAIN_SEPARATOR_VERSION = "3.0.0";

    /************************************|
    |            CUSTOM CONSTANTS        |
    |___________________________________*/

    /// @notice Signers <> AvoMultiSafes mapping list contract for easy on-chain tracking
    IAvoSignersList public immutable avoSignersList;

    /// @notice defines the max signers count for the Multisig. This is chosen deliberately very high, as there shouldn't
    /// really be a limit on signers count in practice. It is extremely unlikely that anyone runs into this very high
    /// limit but it helps to implement test coverage within this given limit
    uint256 public constant MAX_SIGNERS_COUNT = 90;

    /// @dev each additional signer costs ~358 gas to emit in the CastFailed / CastExecuted event. this amount must be
    /// factored in dynamically depending on the number of signers (PER_SIGNER_RESERVE_GAS * number of signers)
    uint256 internal constant PER_SIGNER_RESERVE_GAS = 370;

    /***********************************|
    |            CONSTRUCTOR            |
    |__________________________________*/

    // @dev use 52_000 as reserve gas for `castAuthorized()`. Usually it will cost less but 52_000 is the maximum amount
    // pay fee logic etc. could cost on maximum logic execution
    constructor(
        IAvoVersionsRegistry avoVersionsRegistry_,
        address avoForwarder_,
        IAvoSignersList avoSignersList_,
        uint256 authorizedMinFee_,
        uint256 authorizedMaxFee_,
        address authorizedFeeCollector_
    )
        AvoCoreConstants(avoVersionsRegistry_, avoForwarder_)
        AvoCoreConstantsOverride(
            DOMAIN_SEPARATOR_NAME,
            DOMAIN_SEPARATOR_VERSION,
            52_000,
            12_000,
            authorizedMinFee_,
            authorizedMaxFee_,
            authorizedFeeCollector_,
            true
        )
    {
        if (address(avoSignersList_) == address(0)) {
            revert AvoMultisig__InvalidParams();
        }
        avoSignersList = avoSignersList_;
    }
}

/// @notice Defines storage variables for AvoMultisig
abstract contract AvoMultisigVariables is
    AvoMultisigConstants,
    AvoCoreVariablesSlot0,
    AvoCoreVariablesSlot1,
    AvoCoreVariablesSlot2,
    AvoCoreVariablesSlot3,
    AvoCoreSlotGaps
{
    // ----------- storage slot 0 to 53 through inheritance, see respective contracts -----------

    /***********************************|
    |        CUSTOM STORAGE VARS        |
    |__________________________________*/

    // ----------- storage slot 54 -----------

    /// @dev signers are stored with SSTORE2 to save gas, especially for storage checks at delegateCalls.
    /// getter and setter is implemented below
    address internal _signersPointer;

    /// @notice signers count required to reach quorom and be able to execute actions
    uint8 public requiredSigners;

    /// @notice number of signers currently listed as allowed signers
    //
    // @dev should be updated directly via `_setSigners()`
    uint8 public signersCount;

    /***********************************|
    |            CONSTRUCTOR            |
    |__________________________________*/

    constructor(
        IAvoVersionsRegistry avoVersionsRegistry_,
        address avoForwarder_,
        IAvoSignersList avoSignersList_,
        uint256 authorizedMinFee_,
        uint256 authorizedMaxFee_,
        address authorizedFeeCollector_
    )
        AvoMultisigConstants(
            avoVersionsRegistry_,
            avoForwarder_,
            avoSignersList_,
            authorizedMinFee_,
            authorizedMaxFee_,
            authorizedFeeCollector_
        )
    {}

    /***********************************|
    |      SIGNERS GETTER / SETTER      |
    |__________________________________*/

    /// @dev writes `signers_` to storage with SSTORE2 and updates `signersCount`
    function _setSigners(address[] memory signers_) internal {
        signersCount = uint8(signers_.length);

        _signersPointer = SSTORE2.write(abi.encode(signers_));
    }

    /// @dev reads signers from storage with SSTORE2
    function _getSigners() internal view returns (address[] memory) {
        address pointer_ = _signersPointer;
        if (pointer_ == address(0)) {
            return new address[](0);
        }

        return abi.decode(SSTORE2.read(_signersPointer), (address[]));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title   IAvoSafe
/// @notice  interface to access _avoWalletImpl on-chain
interface IAvoSafe {
    function _avoWalletImpl() external view returns (address);
}

/// @title      AvoSafe
/// @notice     Proxy for AvoWallets as deployed by the AvoFactory.
///             Basic Proxy with fallback to delegate and address for implementation contract at storage 0x0
/// @dev        If this contract changes then the deployment addresses for new AvoSafes through factory change too!!
///             Relayers might want to pass in version as new param then to forward to the correct factory
contract AvoSafe {
    /// @notice address of the Avo wallet logic / implementation contract. IMPORTANT: SAME STORAGE SLOT AS FOR PROXY
    /// @dev    _avoWalletImpl MUST ALWAYS be the first declared variable here in the proxy and in the logic contract
    ///         when upgrading, the storage at memory address 0x0 is upgraded (first slot).
    ///         To reduce deployment costs this variable is internal but can still be retrieved with
    ///         _avoWalletImpl(), see code and comments in fallback below
    address internal _avoWalletImpl;

    /// @notice   sets _avoWalletImpl address, fetching it from msg.sender via avoWalletImpl()
    /// @dev      avoWalletImpl_ is not an input param to not influence the deterministic Create2 address!
    constructor() {
        // "\x8e\x7d\xaf\x69" is hardcoded bytes of function selector for avoWalletImpl()
        (bool success_, bytes memory data_) = msg.sender.call(bytes("\x8e\x7d\xaf\x69"));

        address avoWalletImpl_;
        assembly {
            // cast last 20 bytes of hash to address
            avoWalletImpl_ := mload(add(data_, 32))
        }

        if (!success_ || avoWalletImpl_.code.length == 0) {
            revert();
        }

        _avoWalletImpl = avoWalletImpl_;
    }

    /// @notice Delegates the current call to `_avoWalletImpl` unless _avoWalletImpl() is called
    ///         if _avoWalletImpl() is called then the address for _avoWalletImpl is returned
    /// @dev    Mostly based on OpenZeppelin Proxy.sol
    fallback() external payable {
        assembly {
            // load address avoWalletImpl_ from storage
            let avoWalletImpl_ := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)

            // first 4 bytes of calldata specify which function to call.
            // if those first 4 bytes == 87e9052a (function selector for _avoWalletImpl()) then we return the _avoWalletImpl address
            // The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0x87e9052a00000000000000000000000000000000000000000000000000000000) {
                mstore(0, avoWalletImpl_) // store address avoWalletImpl_ at memory address 0x0
                return(0, 0x20) // send first 20 bytes of address at memory address 0x0
            }

            // @dev code below is taken from OpenZeppelin Proxy.sol _delegate function

            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), avoWalletImpl_, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IAvoMultisigV3 } from "./interfaces/IAvoMultisigV3.sol";
import { IAvoFactory } from "./interfaces/IAvoFactory.sol";
import { IAvoSignersList } from "./interfaces/IAvoSignersList.sol";

// empty interface used for Natspec docs for nice layout in automatically generated docs:
//
/// @title  AvoSignersList v3.0.0
/// @notice Tracks allowed signers for AvoMultiSafes, making available a list of all signers
/// linked to an AvoMultiSafe or all AvoMultiSafes for a certain signer address.
///
/// If `trackInStorage` flag is set to false, then only an event will be emitted for off-chain tracking.
/// The contract itself will not track avoMultiSafes per signer!
///
/// Upgradeable through AvoSignersListProxy
///
/// [email protected] Notes:_
/// In off-chain tracking, make sure to check for duplicates (i.e. mapping already exists).
/// This should not happen but when not tracking the data on-chain there is no way to be sure.
interface AvoSignersList_V3 {

}

abstract contract AvoSignersListErrors {
    /// @notice thrown when a method is called with invalid params (e.g. zero address)
    error AvoSignersList__InvalidParams();

    /// @notice thrown when a view method is called that would require storage mapping data,
    /// but the flag `trackInStorage` is set to false and thus data is not available.
    error AvoSignersList__NotTracked();
}

abstract contract AvoSignersListConstants is AvoSignersListErrors {
    /// @notice AvoFactory used to confirm that an address is an Avocado smart wallet
    IAvoFactory public immutable avoFactory;

    /// @notice flag to signal if tracking should happen in storage or only events should be emitted (for off-chain).
    /// This can be set to false to reduce gas cost on expensive chains
    bool public immutable trackInStorage;

    /// @notice constructor sets the immutable `avoFactory` (proxy) address and the `trackInStorage` flag
    constructor(IAvoFactory avoFactory_, bool trackInStorage_) {
        if (address(avoFactory_) == address(0)) {
            revert AvoSignersList__InvalidParams();
        }
        avoFactory = avoFactory_;

        trackInStorage = trackInStorage_;
    }
}

abstract contract AvoSignersListVariables is AvoSignersListConstants {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev add a gap for slot 0 to 100 to easily inherit Initializable / OwnableUpgradeable etc. later on
    uint256[101] private __gap;

    // ---------------- slot 101 -----------------

    /// @notice tracks all AvoMultiSafes mapped to a signer: signer => EnumerableSet AvoMultiSafes list
    /// @dev mappings to a struct with a mapping can not be public because the getter function that Solidity automatically
    /// generates for public variables cannot handle the potentially infinite size caused by mappings within the structs.
    mapping(address => EnumerableSet.AddressSet) internal _safesPerSigner;
}

abstract contract AvoSignersListEvents {
    /// @notice emitted when a new signer <> AvoMultiSafe mapping is added
    event SignerMappingAdded(address signer, address avoMultiSafe);

    /// @notice emitted when a signer <> AvoMultiSafe mapping is removed
    event SignerMappingRemoved(address signer, address avoMultiSafe);
}

abstract contract AvoSignersListViews is AvoSignersListVariables {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice returns true if `signer_` is an allowed signer of `avoMultiSafe_`
    function isSignerOf(address avoMultiSafe_, address signer_) public view returns (bool) {
        if (trackInStorage) {
            return _safesPerSigner[signer_].contains(avoMultiSafe_);
        } else {
            return IAvoMultisigV3(avoMultiSafe_).isSigner(signer_);
        }
    }

    /// @notice returns all signers for a certain `avoMultiSafe_`
    function signers(address avoMultiSafe_) public view returns (address[] memory) {
        if (Address.isContract(avoMultiSafe_)) {
            return IAvoMultisigV3(avoMultiSafe_).signers();
        } else {
            return new address[](0);
        }
    }

    /// @notice returns all AvoMultiSafes for a certain `signer_'.
    /// reverts with `AvoSignersList__NotTracked()` if `trackInStorage` is set to false (data not available)
    function avoMultiSafes(address signer_) public view returns (address[] memory) {
        if (trackInStorage) {
            return _safesPerSigner[signer_].values();
        } else {
            revert AvoSignersList__NotTracked();
        }
    }

    /// @notice returns the number of mapped signers for a certain `avoMultiSafe_'
    function signersCount(address avoMultiSafe_) public view returns (uint256) {
        if (Address.isContract(avoMultiSafe_)) {
            return IAvoMultisigV3(avoMultiSafe_).signersCount();
        } else {
            return 0;
        }
    }

    /// @notice returns the number of mapped avoMultiSafes for a certain `signer_'
    /// reverts with `AvoSignersList__NotTracked()` if `trackInStorage` is set to false (data not available)
    function avoMultiSafesCount(address signer_) public view returns (uint256) {
        if (trackInStorage) {
            return _safesPerSigner[signer_].length();
        } else {
            revert AvoSignersList__NotTracked();
        }
    }
}

contract AvoSignersList is
    AvoSignersListErrors,
    AvoSignersListConstants,
    AvoSignersListVariables,
    AvoSignersListEvents,
    AvoSignersListViews,
    IAvoSignersList
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice constructor sets the immutable `avoFactory` (proxy) address and the `trackInStorage` flag
    constructor(IAvoFactory avoFactory_, bool trackInStorage_) AvoSignersListConstants(avoFactory_, trackInStorage_) {}

    /// @inheritdoc IAvoSignersList
    function syncAddAvoSignerMappings(address avoMultiSafe_, address[] calldata addSigners_) external {
        // make sure avoMultiSafe_ is an actual AvoMultiSafe
        if (avoFactory.isAvoSafe(avoMultiSafe_) == false) {
            revert AvoSignersList__InvalidParams();
        }

        uint256 addSignersLength_ = addSigners_.length;
        if (addSignersLength_ == 1) {
            // if adding just one signer, using `isSigner()` is cheaper than looping through allowed signers here
            if (IAvoMultisigV3(avoMultiSafe_).isSigner(addSigners_[0])) {
                if (trackInStorage) {
                    // `.add()` method also checks if signer is already mapped to the address
                    if (_safesPerSigner[addSigners_[0]].add(avoMultiSafe_) == true) {
                        emit SignerMappingAdded(addSigners_[0], avoMultiSafe_);
                    }
                    // else ignore silently if mapping is already present
                } else {
                    emit SignerMappingAdded(addSigners_[0], avoMultiSafe_);
                }
            } else {
                revert AvoSignersList__InvalidParams();
            }
        } else {
            // get actual signers present at AvoMultisig to make sure data here will be correct
            address[] memory allowedSigners_ = IAvoMultisigV3(avoMultiSafe_).signers();
            uint256 allowedSignersLength_ = allowedSigners_.length;
            // track last allowed signer index for loop performance improvements
            uint256 lastAllowedSignerIndex_;

            // keeping `isAllowedSigner_` outside the loop so it is not re-initialized in each loop -> cheaper
            bool isAllowedSigner_;
            for (uint256 i; i < addSignersLength_; ) {
                // because allowedSigners_ and addSigners_ must be ordered ascending, the for loop can be optimized
                // each new cycle to start from the position where the last signer has been found
                for (uint256 j = lastAllowedSignerIndex_; j < allowedSignersLength_; ) {
                    if (allowedSigners_[j] == addSigners_[i]) {
                        isAllowedSigner_ = true;
                        lastAllowedSignerIndex_ = j + 1; // set to j+1 so that next cycle starts at next array position
                        break;
                    }

                    // could be optimized by checking if allowedSigners_[j] > recoveredSigners_[i]
                    // and immediately skipping with a `break;` if so. Because that implies that the recoveredSigners_[i]
                    // can not be present in allowedSigners_ due to ascending sort.
                    // But that would optimize the failing invalid case and increase cost for the default case where
                    // the input data is valid -> skip.

                    unchecked {
                        ++j;
                    }
                }

                // validate signer trying to add mapping for is really allowed at AvoMultisig
                if (!isAllowedSigner_) {
                    revert AvoSignersList__InvalidParams();
                }

                // reset `isAllowedSigner_` for next loop
                isAllowedSigner_ = false;

                if (trackInStorage) {
                    // `.add()` method also checks if signer is already mapped to the address
                    if (_safesPerSigner[addSigners_[i]].add(avoMultiSafe_) == true) {
                        emit SignerMappingAdded(addSigners_[i], avoMultiSafe_);
                    }
                    // else ignore silently if mapping is already present
                } else {
                    emit SignerMappingAdded(addSigners_[i], avoMultiSafe_);
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @inheritdoc IAvoSignersList
    function syncRemoveAvoSignerMappings(address avoMultiSafe_, address[] calldata removeSigners_) external {
        // make sure avoMultiSafe_ is an actual AvoMultiSafe
        if (avoFactory.isAvoSafe(avoMultiSafe_) == false) {
            revert AvoSignersList__InvalidParams();
        }

        uint256 removeSignersLength_ = removeSigners_.length;

        if (removeSignersLength_ == 1) {
            // if removing just one signer, using `isSigner()` is cheaper than looping through allowed signers here
            if (IAvoMultisigV3(avoMultiSafe_).isSigner(removeSigners_[0])) {
                revert AvoSignersList__InvalidParams();
            } else {
                if (trackInStorage) {
                    // `.remove()` method also checks if signer is not mapped to the address
                    if (_safesPerSigner[removeSigners_[0]].remove(avoMultiSafe_) == true) {
                        emit SignerMappingRemoved(removeSigners_[0], avoMultiSafe_);
                    }
                    // else ignore silently if mapping is not present
                } else {
                    emit SignerMappingRemoved(removeSigners_[0], avoMultiSafe_);
                }
            }
        } else {
            // get actual signers present at AvoMultisig to make sure data here will be correct
            address[] memory allowedSigners_ = IAvoMultisigV3(avoMultiSafe_).signers();
            uint256 allowedSignersLength_ = allowedSigners_.length;
            // track last signer index where signer to be removed was > allowedSigners for loop performance improvements
            uint256 lastSkipSignerIndex_;

            for (uint256 i; i < removeSignersLength_; ) {
                for (uint256 j = lastSkipSignerIndex_; j < allowedSignersLength_; ) {
                    if (allowedSigners_[j] == removeSigners_[i]) {
                        // validate signer trying to remove mapping for is really not present at AvoMultisig
                        revert AvoSignersList__InvalidParams();
                    }

                    if (allowedSigners_[j] > removeSigners_[i]) {
                        // because allowedSigners_ and removeSigners_ must be ordered ascending the for loop can be optimized:
                        // there is no need to search further once the signer to be removed is < than the allowed signer.
                        // and the next cycle can start from that position
                        lastSkipSignerIndex_ = j;
                        break;
                    }

                    unchecked {
                        ++j;
                    }
                }

                if (trackInStorage) {
                    // `.remove()` method also checks if signer is not mapped to the address
                    if (_safesPerSigner[removeSigners_[i]].remove(avoMultiSafe_) == true) {
                        emit SignerMappingRemoved(removeSigners_[i], avoMultiSafe_);
                    }
                    // else ignore silently if mapping is not present
                } else {
                    emit SignerMappingRemoved(removeSigners_[i], avoMultiSafe_);
                }

                unchecked {
                    ++i;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/// @title    AvoSignersListProxy
/// @notice   Default ERC1967Proxy for AvoSignersList
contract AvoSignersListProxy is TransparentUpgradeableProxy {
    constructor(
        address logic_,
        address admin_,
        bytes memory data_
    ) payable TransparentUpgradeableProxy(logic_, admin_, data_) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { IAvoFactory } from "./interfaces/IAvoFactory.sol";
import { IAvoVersionsRegistry, IAvoFeeCollector } from "./interfaces/IAvoVersionsRegistry.sol";

// empty interface used for Natspec docs for nice layout in automatically generated docs:
//
/// @title  AvoVersionsRegistry v3.0.0
/// @notice Registry for various config data and general actions for Avocado contracts:
/// - holds lists of valid versions for AvoWallet, AvoMultisig & AvoForwarder
/// - handles fees for `castAuthorized()` calls
///
/// Upgradeable through AvoVersionsRegistryProxy
interface AvoVersionsRegistry_V3 {

}

abstract contract AvoVersionsRegistryConstants is IAvoVersionsRegistry {
    /// @notice AvoFactory where new versions get registered automatically as default version on `registerAvoVersion()`
    IAvoFactory public immutable avoFactory;

    constructor(IAvoFactory avoFactory_) {
        avoFactory = avoFactory_;
    }
}

abstract contract AvoVersionsRegistryVariables is IAvoVersionsRegistry, Initializable, OwnableUpgradeable {
    // @dev variables here start at storage slot 101, before is:
    // - Initializable with storage slot 0:
    // uint8 private _initialized;
    // bool private _initializing;
    // - OwnableUpgradeable with slots 1 to 100:
    // uint256[50] private __gap; (from ContextUpgradeable, slot 1 until slot 50)
    // address private _owner; (at slot 51)
    // uint256[49] private __gap; (slot 52 until slot 100)

    // ---------------- slot 101 -----------------

    /// @notice fee config for `calcFee()`. Configurable by owner.
    //
    // @dev address avoFactory used to be at this storage slot until incl. v2.0. Storage slot repurposed with upgrade v3.0
    FeeConfig public feeConfig;

    // ---------------- slot 102 -----------------

    /// @notice mapping to store allowed AvoWallet versions. Modifiable by owner.
    mapping(address => bool) public avoWalletVersions;

    // ---------------- slot 103 -----------------

    /// @notice mapping to store allowed AvoForwarder versions. Modifiable by owner.
    mapping(address => bool) public avoForwarderVersions;

    // ---------------- slot 104 -----------------

    /// @notice mapping to store allowed AvoMultisig versions. Modifiable by owner.
    mapping(address => bool) public avoMultisigVersions;
}

abstract contract AvoVersionsRegistryErrors {
    /// @notice thrown for `requireVersion()` methods
    error AvoVersionsRegistry__InvalidVersion();

    /// @notice thrown when a requested fee mode is not implemented
    error AvoVersionsRegistry__FeeModeNotImplemented(uint8 mode);

    /// @notice thrown when a method is called with invalid params, e.g. the zero address
    error AvoVersionsRegistry__InvalidParams();
}

abstract contract AvoVersionsRegistryEvents is IAvoVersionsRegistry {
    /// @notice emitted when the status for a certain AvoWallet version is updated
    event SetAvoWalletVersion(address indexed avoWalletVersion, bool indexed allowed, bool indexed setDefault);

    /// @notice emitted when the status for a certain AvoMultsig version is updated
    event SetAvoMultisigVersion(address indexed avoMultisigVersion, bool indexed allowed, bool indexed setDefault);

    /// @notice emitted when the status for a certain AvoForwarder version is updated
    event SetAvoForwarderVersion(address indexed avoForwarderVersion, bool indexed allowed);

    /// @notice emitted when the fee config is updated
    event FeeConfigUpdated(address indexed feeCollector, uint8 indexed mode, uint88 indexed fee);
}

abstract contract AvoVersionsRegistryCore is
    AvoVersionsRegistryConstants,
    AvoVersionsRegistryVariables,
    AvoVersionsRegistryErrors,
    AvoVersionsRegistryEvents
{
    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/

    /// @dev checks if an address is not the zero address
    modifier validAddress(address _address) {
        if (_address == address(0)) {
            revert AvoVersionsRegistry__InvalidParams();
        }
        _;
    }

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    constructor(IAvoFactory avoFactory_) validAddress(address(avoFactory_)) AvoVersionsRegistryConstants(avoFactory_) {
        // ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }
}

abstract contract AvoFeeCollector is AvoVersionsRegistryCore {
    /// @inheritdoc IAvoFeeCollector
    function calcFee(uint256 gasUsed_) public view returns (uint256 feeAmount_, address payable feeCollector_) {
        FeeConfig memory feeConfig_ = feeConfig;

        if (feeConfig_.fee > 0) {
            if (feeConfig_.mode == 0) {
                // percentage of `gasUsed_` fee amount mode
                if (gasUsed_ == 0) {
                    revert AvoVersionsRegistry__InvalidParams();
                }

                // fee amount = gasUsed * gasPrice * fee percentage. (tx.gasprice is in wei)
                feeAmount_ = (gasUsed_ * tx.gasprice * feeConfig_.fee) / 1e8; // 1e8 = 100%
            } else if (feeConfig_.mode == 1) {
                // absolute fee amount mode
                feeAmount_ = feeConfig_.fee;
            } else {
                // theoretically not reachable because of check in `updateFeeConfig` but doesn't hurt to have this here
                revert AvoVersionsRegistry__FeeModeNotImplemented(feeConfig_.mode);
            }
        }

        return (feeAmount_, feeConfig_.feeCollector);
    }

    /***********************************|
    |            ONLY OWNER             |
    |__________________________________*/

    /// @notice sets `feeConfig_` as the new fee config in storage. Only callable by owner.
    function updateFeeConfig(FeeConfig calldata feeConfig_) external onlyOwner validAddress(feeConfig_.feeCollector) {
        if (feeConfig_.mode > 1) {
            revert AvoVersionsRegistry__FeeModeNotImplemented(feeConfig_.mode);
        }

        feeConfig = feeConfig_;

        emit FeeConfigUpdated(feeConfig_.feeCollector, feeConfig_.mode, feeConfig_.fee);
    }
}

contract AvoVersionsRegistry is AvoVersionsRegistryCore, AvoFeeCollector {
    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    constructor(IAvoFactory avoFactory_) AvoVersionsRegistryCore(avoFactory_) {}

    /// @notice initializes the contract with `owner_` as owner
    function initialize(address owner_) public initializer validAddress(owner_) {
        _transferOwnership(owner_);
    }

    /// @notice clears storage slot 101. up to v3.0.0 `avoFactory` address was at that slot, since v3.0.0 feeConfig
    function reinitialize() public reinitializer(2) {
        assembly {
            sstore(0x65, 0) // overwrite storage slot 101 completely
        }
    }

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    /// @inheritdoc IAvoVersionsRegistry
    function requireValidAvoWalletVersion(address avoWalletVersion_) external view {
        if (avoWalletVersions[avoWalletVersion_] != true) {
            revert AvoVersionsRegistry__InvalidVersion();
        }
    }

    /// @inheritdoc IAvoVersionsRegistry
    function requireValidAvoMultisigVersion(address avoMultisigVersion_) external view {
        if (avoMultisigVersions[avoMultisigVersion_] != true) {
            revert AvoVersionsRegistry__InvalidVersion();
        }
    }

    /// @inheritdoc IAvoVersionsRegistry
    function requireValidAvoForwarderVersion(address avoForwarderVersion_) public view {
        if (avoForwarderVersions[avoForwarderVersion_] != true) {
            revert AvoVersionsRegistry__InvalidVersion();
        }
    }

    /***********************************|
    |            ONLY OWNER             |
    |__________________________________*/

    /// @notice             sets the status for a certain address as allowed / default AvoWallet version.
    ///                     Only callable by owner.
    /// @param avoWallet_   the address of the contract to treat as AvoWallet version
    /// @param allowed_     flag to set this address as valid version (true) or not (false)
    /// @param setDefault_  flag to indicate whether this version should automatically be set as new
    ///                     default version for new deployments at the linked `avoFactory`
    function setAvoWalletVersion(
        address avoWallet_,
        bool allowed_,
        bool setDefault_
    ) external onlyOwner validAddress(avoWallet_) {
        if (!allowed_ && setDefault_) {
            // can't be not allowed but supposed to be set as default
            revert AvoVersionsRegistry__InvalidParams();
        }

        avoWalletVersions[avoWallet_] = allowed_;

        if (setDefault_) {
            // register the new version as default version at the linked AvoFactory
            avoFactory.setAvoWalletImpl(avoWallet_);
        }

        emit SetAvoWalletVersion(avoWallet_, allowed_, setDefault_);
    }

    /// @notice              sets the status for a certain address as allowed AvoForwarder version.
    ///                      Only callable by owner.
    /// @param avoForwarder_ the address of the contract to treat as AvoForwarder version
    /// @param allowed_      flag to set this address as valid version (true) or not (false)
    function setAvoForwarderVersion(
        address avoForwarder_,
        bool allowed_
    ) external onlyOwner validAddress(avoForwarder_) {
        avoForwarderVersions[avoForwarder_] = allowed_;

        emit SetAvoForwarderVersion(avoForwarder_, allowed_);
    }

    /// @notice             sets the status for a certain address as allowed / default AvoMultisig version.
    ///                     Only callable by owner.
    /// @param avoMultisig_ the address of the contract to treat as AvoMultisig version
    /// @param allowed_     flag to set this address as valid version (true) or not (false)
    /// @param setDefault_  flag to indicate whether this version should automatically be set as new
    ///                     default version for new deployments at the linked `avoFactory`
    function setAvoMultisigVersion(
        address avoMultisig_,
        bool allowed_,
        bool setDefault_
    ) external onlyOwner validAddress(avoMultisig_) {
        if (!allowed_ && setDefault_) {
            // can't be not allowed but supposed to be set as default
            revert AvoVersionsRegistry__InvalidParams();
        }

        avoMultisigVersions[avoMultisig_] = allowed_;

        if (setDefault_) {
            // register the new version as default version at the linked AvoFactory
            avoFactory.setAvoMultisigImpl(avoMultisig_);
        }

        emit SetAvoMultisigVersion(avoMultisig_, allowed_, setDefault_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/// @title    AvoVersionsRegistryProxy
/// @notice   Default ERC1967Proxy for AvoVersionsRegistryProxy
contract AvoVersionsRegistryProxy is TransparentUpgradeableProxy {
    constructor(
        address logic_,
        address admin_,
        bytes memory data_
    ) payable TransparentUpgradeableProxy(logic_, admin_, data_) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";

import { IAvoVersionsRegistry } from "../interfaces/IAvoVersionsRegistry.sol";
import { AvoCore, AvoCoreEIP1271, AvoCoreSelfUpgradeable, AvoCoreProtected } from "../AvoCore/AvoCore.sol";
import { IAvoAuthoritiesList } from "../interfaces/IAvoAuthoritiesList.sol";
import { IAvoWalletV3Base } from "../interfaces/IAvoWalletV3.sol";
import { AvoWalletVariables } from "./AvoWalletVariables.sol";
import { AvoWalletEvents } from "./AvoWalletEvents.sol";
import { AvoWalletErrors } from "./AvoWalletErrors.sol";

// --------------------------- DEVELOPER NOTES -----------------------------------------
// @dev IMPORTANT: all storage variables go into AvoWalletVariables.sol
// -------------------------------------------------------------------------------------

// empty interface used for Natspec docs for nice layout in automatically generated docs:
//
/// @title  AvoWallet v3.0.0
/// @notice Smart wallet enabling meta transactions through a EIP712 signature.
///
/// Supports:
/// - Executing arbitrary actions
/// - Receiving NFTs (ERC721)
/// - Receiving ERC1155 tokens
/// - ERC1271 smart contract signatures
/// - Instadapp Flashloan callbacks
///
/// The `cast` method allows the AvoForwarder (relayer) to execute multiple arbitrary actions authorized by signature.
/// Broadcasters are expected to call the AvoForwarder contract `execute()` method, which also automatically
/// deploys an Avocado smart wallet if necessary first.
///
/// Upgradeable by calling `upgradeTo` (or `upgradeToAndCall`) through a `cast` / `castAuthorized` call.
///
/// The `castAuthorized` method allows the owner of the wallet to execute multiple arbitrary actions directly
/// without the AvoForwarder in between, to guarantee the smart wallet is truly non-custodial.
///
/// [email protected] Notes:_
/// - This contract implements parts of EIP-2770 in a minimized form. E.g. domainSeparator is immutable etc.
/// - This contract does not implement ERC2771, because trusting an upgradeable "forwarder" bears a security
/// risk for this non-custodial wallet.
/// - Signature related logic is based off of OpenZeppelin EIP712Upgradeable.
/// - All signatures are validated for defaultChainId of `63400` instead of `block.chainid` from opcode (EIP-1344).
/// - For replay protection, the current `block.chainid` instead is used in the EIP-712 salt.
interface AvoWallet_V3 {

}

abstract contract AvoWalletCore is AvoWalletErrors, AvoWalletVariables, AvoCore, AvoWalletEvents, IAvoWalletV3Base {
    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    constructor(
        IAvoVersionsRegistry avoVersionsRegistry_,
        address avoForwarder_,
        IAvoAuthoritiesList avoAuthoritiesList_,
        uint256 authorizedMinFee_,
        uint256 authorizedMaxFee_,
        address authorizedFeeCollector_
    )
        AvoWalletVariables(
            avoVersionsRegistry_,
            avoForwarder_,
            avoAuthoritiesList_,
            authorizedMinFee_,
            authorizedMaxFee_,
            authorizedFeeCollector_
        )
    {
        // Ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /***********************************|
    |               INTERNAL            |
    |__________________________________*/

    /// @dev                          Verifies a EIP712 signature, returning valid status in `isValid_` or reverting
    ///                               in case the params for the signature / digest are wrong
    /// @param digest_                the EIP712 digest for the signature
    /// @param signatureParams_       struct for signature and signer:
    ///                               - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                                 For smart contract signatures it must fulfill the requirements for the relevant
    ///                                 smart contract `.isValidSignature()` EIP1271 logic
    ///                               - signer: address of the signature signer.
    ///                                 Must match the actual signature signer or refer to the smart contract
    ///                                 that must be an allowed signer and validates signature via EIP1271
    /// @param  isNonSequentialNonce_ flag to sginal verify with non sequential nonce or not
    /// @param  recoveredSigner_      optional recovered signer from signature for gas optimization
    /// @return isValid_              true if the signature is valid, false otherwise
    /// @return recoveredSigner_      recovered signer address of the `signatureParams_.signature`
    function _verifySig(
        bytes32 digest_,
        SignatureParams memory signatureParams_,
        bool isNonSequentialNonce_,
        address recoveredSigner_
    ) internal view returns (bool isValid_, address) {
        // for non sequential nonce, if nonce is already used, the signature has already been used and is invalid
        if (isNonSequentialNonce_ && nonSequentialNonces[digest_] == 1) {
            revert AvoWallet__InvalidParams();
        }

        if (Address.isContract(signatureParams_.signer)) {
            recoveredSigner_ = signatureParams_.signer;

            // recovered signer must be owner or allowed authority
            // but no need to check for owner as owner can only be EOA
            if (authorities[recoveredSigner_] == 1) {
                // signer is an allowed contract authority -> validate via EIP1271
                return (
                    IERC1271(signatureParams_.signer).isValidSignature(digest_, signatureParams_.signature) ==
                        EIP1271_MAGIC_VALUE,
                    signatureParams_.signer
                );
            } else {
                // signature is for different digest (params) or by an unauthorized signer
                return (false, signatureParams_.signer);
            }
        } else {
            // if signer is not a contract, then it must match the recovered signer from signature
            if (recoveredSigner_ == address(0)) {
                // only recover signer if it is not passed in already
                recoveredSigner_ = ECDSA.recover(digest_, signatureParams_.signature);
            }

            if (signatureParams_.signer != recoveredSigner_) {
                // signer does not match recovered signer. Either signer param is wrong or params used to
                // build digest are not the same as for the signature
                revert AvoWallet__InvalidParams();
            }
        }

        return (
            // recovered signer must be owner or allowed authority
            recoveredSigner_ == owner || authorities[recoveredSigner_] == 1,
            recoveredSigner_
        );
    }
}

abstract contract AvoWalletEIP1271 is AvoCoreEIP1271, AvoWalletCore {
    /// @inheritdoc IERC1271
    /// @param signature This can be one of the following:
    ///         - empty: `hash` must be a previously signed message in storage then.
    ///         - one signature of length 65 bytes (ECDSA), only works for EOA.
    ///         - 85 bytes combination of 65 bytes signature + 20 bytes signer address.
    ///         - the `abi.encode` result for `SignatureParams` struct.
    /// @dev It is better for gas usage to pass 85 bytes with signature + signer instead of 65 bytes signature only.
    /// @dev reverts with `AvoCore__InvalidEIP1271Signature` or `AvoWallet__InvalidParams` if signature is invalid.
    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    ) external view override(AvoCoreEIP1271, IERC1271) returns (bytes4 magicValue) {
        // @dev function params without _ for inheritdoc
        if (signature.length == 0) {
            // must be pre-allow-listed via `signMessage` method
            if (_signedMessages[hash] != 1) {
                revert AvoCore__InvalidEIP1271Signature();
            }
        } else {
            // validate via normal signature verification. retrieve SignatureParams:
            SignatureParams memory signatureParams_;
            // recoveredSigner is ONLY set when ECDSA.recover is used, optimization skips that step then in verifySig
            address recoveredSigner_;
            if (signature.length == 65) {
                // only ECDSA signature is given -> recover signer from signature (only EOA supported)
                signatureParams_ = SignatureParams({ signature: signature, signer: ECDSA.recover(hash, signature) });
                recoveredSigner_ = signatureParams_.signer;
            } else if (signature.length == 85) {
                // signature is 65 bytes signature and 20 bytes signer address
                bytes memory signerBytes_ = signature[65:65 + 20];
                address signer_;
                // cast bytes to address in the easiest way via assembly
                assembly {
                    signer_ := shr(96, mload(add(signerBytes_, 0x20)))
                }

                signatureParams_ = SignatureParams({ signature: signature[0:65], signer: signer_ });
            } else {
                // signature is present that should form `SignatureParams` through abi.decode.
                // Note that even for the extreme case of signature = "0x" and a signer encode result, length is > 128
                // @dev this will fail and revert if invalid typed data is passed in
                signatureParams_ = abi.decode(signature, (SignatureParams));
            }

            (bool validSignature_, ) = _verifySig(
                hash,
                signatureParams_,
                // we have no way to know nonce type, so make sure validity test covers everything.
                // setting this flag true will check that the digest is not a used non-sequential nonce.
                // unfortunately, for sequential nonces it adds unneeded verification and gas cost,
                // because the check will always pass, but there is no way around it.
                true,
                recoveredSigner_
            );

            if (!validSignature_) {
                revert AvoCore__InvalidEIP1271Signature();
            }
        }

        return EIP1271_MAGIC_VALUE;
    }
}

abstract contract AvoWalletAuthorities is AvoWalletCore {
    /// @inheritdoc IAvoWalletV3Base
    function isAuthority(address authority_) public view returns (bool) {
        return authorities[authority_] == 1;
    }

    /// @notice adds `authorities_` to allowed authorities
    function addAuthorities(address[] calldata authorities_) external onlySelf {
        uint256 authoritiesLength_ = authorities_.length;

        for (uint256 i; i < authoritiesLength_; ) {
            if (authorities_[i] == address(0)) {
                revert AvoWallet__InvalidParams();
            }

            if (authorities[authorities_[i]] != 1) {
                authorities[authorities_[i]] = 1;

                emit AuthorityAdded(authorities_[i]);
            }

            unchecked {
                ++i;
            }
        }

        // sync mappings at AvoAuthoritiesList
        avoAuthoritiesList.syncAvoAuthorityMappings(address(this), authorities_);
    }

    /// @notice removes `authorities_` from allowed authorities.
    function removeAuthorities(address[] calldata authorities_) external onlySelf {
        uint256 authoritiesLength_ = authorities_.length;

        for (uint256 i; i < authoritiesLength_; ) {
            if (authorities[authorities_[i]] != 0) {
                authorities[authorities_[i]] = 0;

                emit AuthorityRemoved(authorities_[i]);
            }

            unchecked {
                ++i;
            }
        }

        // sync mappings at AvoAuthoritiesList
        avoAuthoritiesList.syncAvoAuthorityMappings(address(this), authorities_);
    }
}

/// @dev See contract AvoCoreSelfUpgradeable
abstract contract AvoWalletSelfUpgradeable is AvoCoreSelfUpgradeable {
    /// @inheritdoc AvoCoreSelfUpgradeable
    function upgradeTo(address avoImplementation_) public override onlySelf {
        avoVersionsRegistry.requireValidAvoWalletVersion(avoImplementation_);

        _avoImplementation = avoImplementation_;
        emit Upgraded(avoImplementation_);
    }
}

abstract contract AvoWalletProtected is AvoCoreProtected {}

abstract contract AvoWalletCast is AvoWalletCore {
    /// @inheritdoc IAvoWalletV3Base
    function getSigDigest(
        CastParams memory params_,
        CastForwardParams memory forwardParams_
    ) public view returns (bytes32) {
        return
            _getSigDigest(
                params_,
                CAST_TYPE_HASH,
                // CastForwardParams hash
                keccak256(
                    abi.encode(
                        CAST_FORWARD_PARAMS_TYPE_HASH,
                        forwardParams_.gas,
                        forwardParams_.gasPrice,
                        forwardParams_.validAfter,
                        forwardParams_.validUntil
                    )
                )
            );
    }

    /// @inheritdoc IAvoWalletV3Base
    function verify(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams calldata signatureParams_
    ) external view returns (bool) {
        _validateParams(
            params_.actions.length,
            params_.avoSafeNonce,
            forwardParams_.validAfter,
            forwardParams_.validUntil
        );

        (bool validSignature_, ) = _verifySig(
            getSigDigest(params_, forwardParams_),
            signatureParams_,
            params_.avoSafeNonce == -1,
            address(0)
        );

        // signature must be valid
        if (!validSignature_) {
            revert AvoWallet__InvalidSignature();
        }

        return true;
    }

    /// @inheritdoc IAvoWalletV3Base
    function cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams memory signatureParams_
    ) external payable returns (bool success_, string memory revertReason_) {
        {
            if (msg.sender != avoForwarder) {
                // sender must be allowed forwarder
                revert AvoWallet__Unauthorized();
            }

            // compare actual sent gas to user instructed gas, adding 500 to `gasleft()` for approx. already used gas
            if ((gasleft() + 500) < forwardParams_.gas) {
                // relayer has not sent enough gas to cover gas limit as user instructed
                revert AvoWallet__InsufficientGasSent();
            }

            _validateParams(
                params_.actions.length,
                params_.avoSafeNonce,
                forwardParams_.validAfter,
                forwardParams_.validUntil
            );
        }

        bytes32 digest_ = getSigDigest(params_, forwardParams_);
        {
            bool validSignature_;
            (validSignature_, signatureParams_.signer) = _verifySig(
                digest_,
                signatureParams_,
                params_.avoSafeNonce == -1,
                address(0)
            );

            // signature must be valid
            if (!validSignature_) {
                revert AvoWallet__InvalidSignature();
            }
        }

        (success_, revertReason_) = _executeCast(
            params_,
            CAST_EVENTS_RESERVE_GAS,
            params_.avoSafeNonce == -1 ? digest_ : bytes32(0)
        );

        // @dev on changes in the code below this point, measure the needed reserve gas via gasleft() anew
        // and update reserve gas constant amounts
        if (success_ == true) {
            emit CastExecuted(params_.source, msg.sender, signatureParams_.signer, params_.metadata);
        } else {
            emit CastFailed(params_.source, msg.sender, signatureParams_.signer, revertReason_, params_.metadata);
        }
        // @dev ending point for measuring reserve gas should be here. Also see comment in `AvoCore._executeCast()`
    }
}

abstract contract AvoWalletCastAuthorized is AvoWalletCore {
    /// @inheritdoc IAvoWalletV3Base
    function nonSequentialNonceAuthorized(
        CastParams memory params_,
        CastAuthorizedParams memory authorizedParams_
    ) public view returns (bytes32) {
        return
            _getSigDigest(
                params_,
                CAST_AUTHORIZED_TYPE_HASH,
                // CastAuthorizedParams hash
                keccak256(
                    abi.encode(
                        CAST_AUTHORIZED_PARAMS_TYPE_HASH,
                        authorizedParams_.maxFee,
                        authorizedParams_.gasPrice,
                        authorizedParams_.validAfter,
                        authorizedParams_.validUntil
                    )
                )
            );
    }

    /// @inheritdoc IAvoWalletV3Base
    function castAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external payable returns (bool success_, string memory revertReason_) {
        uint256 gasSnapshot_ = gasleft();

        address owner_ = owner;
        {
            if (msg.sender != owner_) {
                // sender must be owner
                revert AvoWallet__Unauthorized();
            }

            // make sure actions are defined and nonce is valid:
            // must be -1 to use a non-sequential nonce or otherwise it must match the avoSafeNonce
            if (
                !(params_.actions.length > 0 &&
                    (params_.avoSafeNonce == -1 || uint256(params_.avoSafeNonce) == avoSafeNonce))
            ) {
                revert AvoWallet__InvalidParams();
            }
        }

        {
            bytes32 nonSequentialNonce_;
            if (params_.avoSafeNonce == -1) {
                // create a non-sequential nonce based on input params
                nonSequentialNonce_ = nonSequentialNonceAuthorized(params_, authorizedParams_);

                // for non sequential nonce, if nonce is already used, the signature has already been used and is invalid
                if (nonSequentialNonces[nonSequentialNonce_] == 1) {
                    revert AvoWallet__InvalidParams();
                }
            }

            (success_, revertReason_) = _executeCast(params_, CAST_AUTHORIZED_RESERVE_GAS, nonSequentialNonce_);

            // @dev on changes in the code below this point, measure the needed reserve gas via gasleft() anew
            // and update reserve gas constant amounts
            if (success_ == true) {
                emit CastExecuted(params_.source, msg.sender, owner_, params_.metadata);
            } else {
                emit CastFailed(params_.source, msg.sender, owner_, revertReason_, params_.metadata);
            }
        }

        // @dev `_payAuthorizedFee()` costs ~24k gas for if a fee is configured and maxFee is set
        _payAuthorizedFee(gasSnapshot_, authorizedParams_.maxFee);

        // @dev ending point for measuring reserve gas should be here. Also see comment in `AvoCore._executeCast()`
    }
}

contract AvoWallet is
    AvoWalletCore,
    AvoWalletSelfUpgradeable,
    AvoWalletProtected,
    AvoWalletEIP1271,
    AvoWalletAuthorities,
    AvoWalletCast,
    AvoWalletCastAuthorized
{
    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    /// @notice                        constructor sets multiple immutable values for contracts and payFee fallback logic.
    /// @param avoVersionsRegistry_    address of the avoVersionsRegistry (proxy) contract
    /// @param avoForwarder_           address of the avoForwarder (proxy) contract
    ///                                to forward tx with valid signatures. must be valid version in AvoVersionsRegistry.
    /// @param avoAuthoritiesList_     address of the AvoAuthoritiesList (proxy) contract
    /// @param authorizedMinFee_       minimum for fee charged via `castAuthorized()` to charge if
    ///                                `AvoVersionsRegistry.calcFee()` would fail.
    /// @param authorizedMaxFee_       maximum for fee charged via `castAuthorized()`. If AvoVersionsRegistry
    ///                                returns a fee higher than this, then `authorizedMaxFee_` is charged as fee instead.
    /// @param authorizedFeeCollector_ address that the fee charged via `castAuthorized()` is sent to in the fallback case.
    constructor(
        IAvoVersionsRegistry avoVersionsRegistry_,
        address avoForwarder_,
        IAvoAuthoritiesList avoAuthoritiesList_,
        uint256 authorizedMinFee_,
        uint256 authorizedMaxFee_,
        address authorizedFeeCollector_
    )
        AvoWalletCore(
            avoVersionsRegistry_,
            avoForwarder_,
            avoAuthoritiesList_,
            authorizedMinFee_,
            authorizedMaxFee_,
            authorizedFeeCollector_
        )
    {}

    /// @inheritdoc IAvoWalletV3Base
    function initialize(address owner_) public initializer {
        _initializeOwner(owner_);
    }

    /// @inheritdoc IAvoWalletV3Base
    function initializeWithVersion(address owner_, address avoWalletVersion_) public initializer {
        _initializeOwner(owner_);

        // set current avo implementation logic address
        _avoImplementation = avoWalletVersion_;
    }

    /// @notice storage cleanup from earlier AvoWallet Versions that filled storage slots for deprecated uses
    function reinitialize() public reinitializer(2) {
        // clean up storage slot 2 and 3, which included EIP712Upgradeable hashes in earlier versions. See Variables files
        assembly {
            // load content from storage slot 1, except for last 80 bits. Loading: 176 bit (42 * 8)
            let slot1Data_ := and(sload(0x1), 0xffffffffffffffffffffffffffffffffffffffffffff)
            sstore(0x1, slot1Data_) // overwrite last 80 bit in storage slot 1 with 0
            sstore(0x2, 0) // overwrite storage slot 2 completely
            sstore(0x3, 0) // overwrite storage slot 3 completely
        }
    }

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    receive() external payable {}

    /// @inheritdoc IAvoWalletV3Base
    function domainSeparatorV4() public view returns (bytes32) {
        return _domainSeparatorV4();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

abstract contract AvoWalletErrors {
    /// @notice thrown when a method is called with invalid params (e.g. a zero address as input param)
    error AvoWallet__InvalidParams();

    /// @notice thrown when a signature is not valid (e.g. not by owner or authority)
    error AvoWallet__InvalidSignature();

    /// @notice thrown when someone is trying to execute a in some way auth protected logic
    error AvoWallet__Unauthorized();

    /// @notice thrown when forwarder/relayer does not send enough gas as the user has defined.
    ///         this error should not be blamed on the user but rather on the relayer
    error AvoWallet__InsufficientGasSent();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

abstract contract AvoWalletEvents {
    /// @notice emitted when all actions are executed successfully
    /// caller = owner / AvoForwarder address. signer = address that triggered this execution (authority or owner)
    event CastExecuted(address indexed source, address indexed caller, address indexed signer, bytes metadata);

    /// @notice emitted if one of the executed actions fails. The reason will be prefixed with the index of the action.
    /// e.g. if action 1 fails, then the reason will be 1_reason
    /// if an action in the flashloan callback fails, it will be prefixed with two numbers:
    /// e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails, the reason will be 1_2_reason.
    /// caller = owner / AvoForwarder address. signer = address that triggered this execution (authority or owner)
    event CastFailed(
        address indexed source,
        address indexed caller,
        address indexed signer,
        string reason,
        bytes metadata
    );

    /// @notice emitted when an allowed authority is added
    event AuthorityAdded(address indexed authority);

    /// @notice emitted when an allowed authority is removed
    event AuthorityRemoved(address indexed authority);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { IAvoVersionsRegistry } from "../interfaces/IAvoVersionsRegistry.sol";
import { IAvoAuthoritiesList } from "../interfaces/IAvoAuthoritiesList.sol";
import { AvoWalletErrors } from "./AvoWalletErrors.sol";
import { AvoCoreConstants, AvoCoreConstantsOverride, AvoCoreVariablesSlot0, AvoCoreVariablesSlot1, AvoCoreVariablesSlot2, AvoCoreVariablesSlot3, AvoCoreSlotGaps } from "../AvoCore/AvoCoreVariables.sol";

abstract contract AvoWalletConstants is AvoCoreConstants, AvoCoreConstantsOverride, AvoWalletErrors {
    // constants for EIP712 values (can't be overriden as immutables as other AvoCore constants, strings not supported)
    string public constant DOMAIN_SEPARATOR_NAME = "Avocado-Safe";
    string public constant DOMAIN_SEPARATOR_VERSION = "3.0.0";

    /************************************|
    |            CUSTOM CONSTANTS        |
    |___________________________________*/

    /// @notice Authorities <> AvoSafes mapping list contract for easy on-chain tracking
    IAvoAuthoritiesList public immutable avoAuthoritiesList;

    /***********************************|
    |            CONSTRUCTOR            |
    |__________________________________*/

    // @dev use 52_000 as reserve gas for `castAuthorized()`. Usually it will cost less but 52_000 is the maximum amount
    // pay fee logic etc. could cost on maximum logic execution
    constructor(
        IAvoVersionsRegistry avoVersionsRegistry_,
        address avoForwarder_,
        IAvoAuthoritiesList avoAuthoritiesList_,
        uint256 authorizedMinFee_,
        uint256 authorizedMaxFee_,
        address authorizedFeeCollector_
    )
        AvoCoreConstants(avoVersionsRegistry_, avoForwarder_)
        AvoCoreConstantsOverride(
            DOMAIN_SEPARATOR_NAME,
            DOMAIN_SEPARATOR_VERSION,
            52_000,
            12_000,
            authorizedMinFee_,
            authorizedMaxFee_,
            authorizedFeeCollector_,
            false
        )
    {
        if (address(avoAuthoritiesList_) == address(0)) {
            revert AvoWallet__InvalidParams();
        }
        avoAuthoritiesList = avoAuthoritiesList_;
    }
}

/// @notice Defines storage variables for AvoWallet
abstract contract AvoWalletVariables is
    AvoWalletConstants,
    AvoCoreVariablesSlot0,
    AvoCoreVariablesSlot1,
    AvoCoreVariablesSlot2,
    AvoCoreVariablesSlot3,
    AvoCoreSlotGaps
{
    // ----------- storage slot 0 to 53 through inheritance, see respective contracts -----------

    /***********************************|
    |        CUSTOM STORAGE VARS        |
    |__________________________________*/

    // ----------- storage slot 54 -----------

    /// @notice mapping for allowed authorities. Authorities can trigger actions through signature & AvoForwarder
    ///         just like the owner
    mapping(address => uint256) public authorities;

    /***********************************|
    |            CONSTRUCTOR            |
    |__________________________________*/

    constructor(
        IAvoVersionsRegistry avoVersionsRegistry_,
        address avoForwarder_,
        IAvoAuthoritiesList avoAuthoritiesList_,
        uint256 authorizedMinFee_,
        uint256 authorizedMaxFee_,
        address authorizedFeeCollector_
    )
        AvoWalletConstants(
            avoVersionsRegistry_,
            avoForwarder_,
            avoAuthoritiesList_,
            authorizedMinFee_,
            authorizedMaxFee_,
            authorizedFeeCollector_
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface ICREATE3Factory {
    /// @notice Deploys a contract using CREATE3
    /// @param salt The deployer-specific salt for determining the deployed contract's address
    /// @param creationCode The creation code of the contract to deploy
    /// @return deployed The address of the deployed contract
    function deploy(bytes32 salt, bytes memory creationCode) external payable returns (address deployed);

    /// @notice Predicts the address of a deployed contract
    /// @param salt The deployer-specific salt for determining the deployed contract's address
    /// @return deployed The address of the contract that will be deployed
    function getDeployed(bytes32 salt) external view returns (address deployed);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface InstaFlashAggregatorInterface {
    event LogFlashloan(address indexed account, uint256 indexed route, address[] tokens, uint256[] amounts);

    function flashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256 route,
        bytes calldata data,
        bytes calldata instaData
    ) external;

    function getRoutes() external pure returns (uint16[] memory routes);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface InstaFlashReceiverInterface {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata _data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IWETH9 {
    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IAvoFactory } from "../interfaces/IAvoFactory.sol";
import { IAvoWalletV3 } from "../interfaces/IAvoWalletV3.sol";
import { IAvoMultisigV3 } from "../interfaces/IAvoMultisigV3.sol";

// empty interface used for Natspec docs for nice layout in automatically generated docs:
//
/// @title  AvoGasEstimationsHelper v3.0.0
/// @notice Helps to estimate gas costs for execution of arbitrary actions in an Avocado smart wallet,
/// especially when the smart wallet is not deployed yet.
/// ATTENTION: Only supports AvoWallet version > 2.0.0
interface AvoGasEstimationsHelper_V3 {

}

interface IAvoWalletWithCallTargets is IAvoWalletV3 {
    function _callTargets(Action[] calldata actions_, uint256 id_) external payable;
}

interface IAvoMultisigWithCallTargets is IAvoMultisigV3 {
    function _callTargets(Action[] calldata actions_, uint256 id_) external payable;
}

contract AvoGasEstimationsHelper {
    using Address for address;

    error AvoGasEstimationsHelper__InvalidParams();

    /***********************************|
    |           STATE VARIABLES         |
    |__________________________________*/

    /// @notice AvoFactory that this contract uses to find or create Avocado smart wallet deployments
    IAvoFactory public immutable avoFactory;

    /// @notice cached AvoSafe bytecode to optimize gas usage
    //
    // @dev If this changes because of a AvoFactory (and AvoSafe change) upgrade,
    // then this variable must be updated through an upgrade deploying a new AvoGasEstimationsHelper!
    bytes32 public immutable avoSafeBytecode;

    /// @notice cached AvoMultiSafe bytecode to optimize gas usage
    //
    // @dev If this changes because of an AvoFactory (and AvoMultiSafe change) upgrade,
    // then this variable must be updated through an upgrade deploying a new AvoGasEstimationsHelper!
    bytes32 public immutable avoMultiSafeBytecode;

    /// @notice constructor sets the immutable `avoFactory` address
    /// @param avoFactory_ address of AvoFactory (proxy)
    constructor(IAvoFactory avoFactory_) {
        if (address(avoFactory_) == address(0)) {
            revert AvoGasEstimationsHelper__InvalidParams();
        }
        avoFactory = avoFactory_;

        // get AvoSafe & AvoSafeMultsig bytecode from factory.
        // @dev if a new AvoFactory is deployed (upgraded), a new AvoGasEstimationsHelper must be deployed
        // to update these bytecodes. See README for more info.
        avoSafeBytecode = avoFactory.avoSafeBytecode();
        avoMultiSafeBytecode = avoFactory.avoMultiSafeBytecode();
    }

    /// @notice estimate gas usage of `actions_` via smart wallet `._callTargets()`.
    ///         Deploys the Avocado smart wallet if necessary.
    ///         Can be used for versions > 2.0.0.
    ///         Note this gas estimation will not include the gas consumed in `.cast()` or in AvoForwarder itself
    /// @param  owner_         Avocado smart wallet owner
    /// @param  actions_       the actions to execute (target, data, value, operation)
    /// @param  id_            id for actions, e.g.
    ///                        0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
    /// @return totalGasUsed_       total amount of gas used
    /// @return deploymentGasUsed_  amount of gas used for deployment (or for getting the contract if already deployed)
    /// @return isAvoSafeDeployed_  boolean flag indicating if AvoSafe is already deployed
    /// @return success_            boolean flag indicating whether executing actions reverts or not
    function estimateCallTargetsGas(
        address owner_,
        IAvoWalletV3.Action[] calldata actions_,
        uint256 id_
    )
        external
        payable
        returns (uint256 totalGasUsed_, uint256 deploymentGasUsed_, bool isAvoSafeDeployed_, bool success_)
    {
        uint256 gasSnapshotBefore_ = gasleft();

        IAvoWalletWithCallTargets avoWallet_;
        // `_getDeployedAvoWallet()` automatically checks if AvoSafe has to be deployed
        // or if it already exists and simply returns the address
        (avoWallet_, isAvoSafeDeployed_) = _getDeployedAvoWallet(owner_, address(0));

        deploymentGasUsed_ = gasSnapshotBefore_ - gasleft();

        (success_, ) = address(avoWallet_).call{ value: msg.value }(
            abi.encodeCall(avoWallet_._callTargets, (actions_, id_))
        );

        totalGasUsed_ = gasSnapshotBefore_ - gasleft();
    }

    /// @notice estimate gas usage of `actions_` via smart wallet `._callTargets()` for a certain `avoWalletVersion_`.
    ///         Deploys the Avocado smart wallet if necessary.
    ///         Can be used for versions > 2.0.0.
    ///         Note this gas estimation will not include the gas consumed in `.cast()` or in AvoForwarder itself
    /// @param  owner_         Avocado smart wallet owner
    /// @param  actions_       the actions to execute (target, data, value, operation)
    /// @param  id_            id for actions, e.g.
    ///                        0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
    /// @param  avoWalletVersion_   Version of AvoWallet to deploy
    ///                             Note that this param has no effect if the wallet is already deployed
    /// @return totalGasUsed_       total amount of gas used
    /// @return deploymentGasUsed_  amount of gas used for deployment (or for getting the contract if already deployed)
    /// @return isAvoSafeDeployed_  boolean flag indicating if AvoSafe is already deployed
    /// @return success_            boolean flag indicating whether executing actions reverts or not
    function estimateCallTargetsGasWithVersion(
        address owner_,
        IAvoWalletV3.Action[] calldata actions_,
        uint256 id_,
        address avoWalletVersion_
    )
        external
        payable
        returns (uint256 totalGasUsed_, uint256 deploymentGasUsed_, bool isAvoSafeDeployed_, bool success_)
    {
        uint256 gasSnapshotBefore_ = gasleft();

        IAvoWalletWithCallTargets avoWallet_;
        // `_getDeployedAvoWallet()` automatically checks if AvoSafe has to be deployed
        // or if it already exists and simply returns the address
        (avoWallet_, isAvoSafeDeployed_) = _getDeployedAvoWallet(owner_, avoWalletVersion_);

        deploymentGasUsed_ = gasSnapshotBefore_ - gasleft();

        (success_, ) = address(avoWallet_).call{ value: msg.value }(
            abi.encodeCall(avoWallet_._callTargets, (actions_, id_))
        );

        totalGasUsed_ = gasSnapshotBefore_ - gasleft();
    }

    /// @notice estimate gas usage of `actions_` via smart wallet `._callTargets()`.
    ///         Deploys the Avocado smart wallet if necessary.
    ///         Note this gas estimation will not include the gas consumed in `.cast()` or in AvoForwarder itself
    /// @param  owner_         Avocado smart wallet owner
    /// @param  actions_       the actions to execute (target, data, value, operation)
    /// @param  id_            id for actions, e.g.
    ///                        0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
    /// @return totalGasUsed_       total amount of gas used
    /// @return deploymentGasUsed_  amount of gas used for deployment (or for getting the contract if already deployed)
    /// @return isDeployed_         boolean flag indicating if AvoMultiSafe is already deployed
    /// @return success_            boolean flag indicating whether executing actions reverts or not
    function estimateCallTargetsGasMultisig(
        address owner_,
        IAvoMultisigV3.Action[] calldata actions_,
        uint256 id_
    ) external payable returns (uint256 totalGasUsed_, uint256 deploymentGasUsed_, bool isDeployed_, bool success_) {
        uint256 gasSnapshotBefore_ = gasleft();

        IAvoMultisigWithCallTargets avoMultisig_;
        // `_getDeployedAvoMultisig()` automatically checks if AvoMultiSafe has to be deployed
        // or if it already exists and simply returns the address
        (avoMultisig_, isDeployed_) = _getDeployedAvoMultisig(owner_, address(0));

        deploymentGasUsed_ = gasSnapshotBefore_ - gasleft();

        (success_, ) = address(avoMultisig_).call{ value: msg.value }(
            abi.encodeCall(avoMultisig_._callTargets, (actions_, id_))
        );

        totalGasUsed_ = gasSnapshotBefore_ - gasleft();
    }

    /// @notice estimate gas usage of `actions_` via smart wallet `._callTargets()` for a certain `avoMultisigVersion_`.
    ///         Deploys the Avocado smart wallet if necessary.
    ///         Note this gas estimation will not include the gas consumed in `.cast()` or in AvoForwarder itself
    /// @param  owner_         Avocado smart wallet owner
    /// @param  actions_       the actions to execute (target, data, value, operation)
    /// @param  id_            id for actions, e.g.
    ///                        0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
    /// @param avoMultisigVersion_  Version of AvoMultisig to deploy
    ///                             Note that this param has no effect if the wallet is already deployed
    /// @return totalGasUsed_       total amount of gas used
    /// @return deploymentGasUsed_  amount of gas used for deployment (or for getting the contract if already deployed)
    /// @return isDeployed_         boolean flag indicating if AvoMultiSafe is already deployed
    /// @return success_            boolean flag indicating whether executing actions reverts or not
    function estimateCallTargetsGasWithVersionMultisig(
        address owner_,
        IAvoMultisigV3.Action[] calldata actions_,
        uint256 id_,
        address avoMultisigVersion_
    ) external payable returns (uint256 totalGasUsed_, uint256 deploymentGasUsed_, bool isDeployed_, bool success_) {
        uint256 gasSnapshotBefore_ = gasleft();

        IAvoMultisigWithCallTargets avoMultisig_;
        // `_getDeployedAvoMultisig()` automatically checks if AvoMultiSafe has to be deployed
        // or if it already exists and simply returns the address
        (avoMultisig_, isDeployed_) = _getDeployedAvoMultisig(owner_, avoMultisigVersion_);

        deploymentGasUsed_ = gasSnapshotBefore_ - gasleft();

        (success_, ) = address(avoMultisig_).call{ value: msg.value }(
            abi.encodeCall(avoMultisig_._callTargets, (actions_, id_))
        );

        totalGasUsed_ = gasSnapshotBefore_ - gasleft();
    }

    /***********************************|
    |              INTERNAL             |
    |__________________________________*/

    /// @dev gets, or if necessary deploys an AvoSafe for owner `from_` and returns the address
    /// @param from_                AvoSafe Owner
    /// @param avoWalletVersion_    Optional param to define a specific AvoWallet version to deploy
    /// @return                     the AvoSafe for the owner & boolean flag for if it was already deployed or not
    function _getDeployedAvoWallet(
        address from_,
        address avoWalletVersion_
    ) internal returns (IAvoWalletWithCallTargets, bool) {
        address computedAvoSafeAddress_ = _computeAvoSafeAddress(from_);
        if (Address.isContract(computedAvoSafeAddress_)) {
            return (IAvoWalletWithCallTargets(computedAvoSafeAddress_), true);
        } else {
            if (avoWalletVersion_ == address(0)) {
                return (IAvoWalletWithCallTargets(avoFactory.deploy(from_)), false);
            } else {
                return (IAvoWalletWithCallTargets(avoFactory.deployWithVersion(from_, avoWalletVersion_)), false);
            }
        }
    }

    /// @dev gets, or if necessary deploys, an AvoMultiSafe for owner `from_` and returns the address
    /// @param from_                AvoMultiSafe Owner
    /// @param avoMultisigVersion_  Optional param to define a specific AvoMultisig version to deploy
    /// @return                     the AvoMultiSafe for the owner & boolean flag for if it was already deployed or not
    function _getDeployedAvoMultisig(
        address from_,
        address avoMultisigVersion_
    ) internal returns (IAvoMultisigWithCallTargets, bool) {
        address computedAvoSafeAddress_ = _computeAvoSafeAddressMultisig(from_);
        if (Address.isContract(computedAvoSafeAddress_)) {
            return (IAvoMultisigWithCallTargets(computedAvoSafeAddress_), true);
        } else {
            if (avoMultisigVersion_ == address(0)) {
                return (IAvoMultisigWithCallTargets(avoFactory.deployMultisig(from_)), false);
            } else {
                return (
                    IAvoMultisigWithCallTargets(avoFactory.deployMultisigWithVersion(from_, avoMultisigVersion_)),
                    false
                );
            }
        }
    }

    /// @dev computes the deterministic contract address `computedAddress_` for a AvoSafe deployment for `owner_`
    function _computeAvoSafeAddress(address owner_) internal view returns (address computedAddress_) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(avoFactory), _getSalt(owner_), avoSafeBytecode)
        );

        // cast last 20 bytes of hash to address via low level assembly
        assembly {
            computedAddress_ := and(hash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @dev computes the deterministic contract address `computedAddress_` for a AvoSafeMultsig deployment for `owner_`
    function _computeAvoSafeAddressMultisig(address owner_) internal view returns (address computedAddress_) {
        // replicate Create2 address determination logic
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(avoFactory), _getSaltMultisig(owner_), avoMultiSafeBytecode)
        );

        // cast last 20 bytes of hash to address via low level assembly
        assembly {
            computedAddress_ := and(hash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @dev gets the bytes32 salt used for deterministic deployment for `owner_`
    function _getSalt(address owner_) internal pure returns (bytes32) {
        // only owner is used as salt
        // no extra salt is needed because even if another version of AvoFactory would be deployed,
        // deterministic deployments take into account the deployers address (i.e. the factory address)
        // and the bytecode (-> difference between AvoSafe and AvoMultisig)
        return keccak256(abi.encode(owner_));
    }

    /// @dev gets the bytes32 salt used for deterministic Multisig deployment for `owner_`
    function _getSaltMultisig(address owner_) internal pure returns (bytes32) {
        // only owner is used as salt
        // no extra salt is needed because even if another version of AvoFactory would be deployed,
        // deterministic deployments take into account the deployers address (i.e. the factory address)
        // and the bytecode (-> difference between AvoSafe and AvoMultisig)
        return keccak256(abi.encode(owner_));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoAuthoritiesList {
    /// @notice syncs mappings of `authorities_` to an AvoSafe `avoSafe_` based on the data present at the wallet.
    /// If `trackInStorage` flag is set to false, then only an event will be emitted for off-chain tracking.
    /// The contract itself will not track avoSafes per authority on-chain!
    ///
    /// Silently ignores `authorities_` that are already mapped correctly.
    ///
    /// There is expectedly no need for this method to be called by anyone other than the AvoSafe itself.
    ///
    /// @dev Note that in off-chain tracking make sure to check for duplicates (i.e. mapping already exists).
    /// This should not happen but when not tracking the data on-chain there is no way to be sure.
    function syncAvoAuthorityMappings(address avoSafe_, address[] calldata authorities_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { IAvoVersionsRegistry } from "./IAvoVersionsRegistry.sol";

interface IAvoFactory {
    /// @notice returns AvoVersionsRegistry (proxy) address
    function avoVersionsRegistry() external view returns (IAvoVersionsRegistry);

    /// @notice returns Avo wallet logic contract address that new AvoSafe deployments point to
    function avoWalletImpl() external view returns (address);

    /// @notice returns AvoMultisig logic contract address that new AvoMultiSafe deployments point to
    function avoMultisigImpl() external view returns (address);

    /// @notice           Checks if a certain address is an Avocado smart wallet (AvoSafe or AvoMultisig).
    ///                   Only works for already deployed wallets.
    /// @param avoSafe_   address to check
    /// @return           true if address is an avoSafe
    function isAvoSafe(address avoSafe_) external view returns (bool);

    /// @notice                    Computes the deterministic address for `owner_` based on Create2
    /// @param owner_              AvoSafe owner
    /// @return computedAddress_   computed address for the contract (AvoSafe)
    function computeAddress(address owner_) external view returns (address computedAddress_);

    /// @notice                     Computes the deterministic Multisig address for `owner_` based on Create2
    /// @param owner_               AvoMultiSafe owner
    /// @return computedAddress_    computed address for the contract (AvoSafe)
    function computeAddressMultisig(address owner_) external view returns (address computedAddress_);

    /// @notice         Deploys an AvoSafe for a certain owner deterministcally using Create2.
    ///                 Does not check if contract at address already exists (AvoForwarder does that)
    /// @param owner_   AvoSafe owner
    /// @return         deployed address for the contract (AvoSafe)
    function deploy(address owner_) external returns (address);

    /// @notice                  Deploys a non-default version AvoSafe for an `owner_` deterministcally using Create2.
    ///                          ATTENTION: Only supports AvoWallet version > 2.0.0
    ///                          Does not check if contract at address already exists (AvoForwarder does that)
    /// @param owner_            AvoSafe owner
    /// @param avoWalletVersion_ Version of AvoWallet logic contract to deploy
    /// @return                  deployed address for the contract (AvoSafe)
    function deployWithVersion(address owner_, address avoWalletVersion_) external returns (address);

    /// @notice         Deploys an Avocado Multisig for a certain `owner_` deterministcally using Create2.
    ///                 Does not check if contract at address already exists (AvoForwarder does that)
    /// @param owner_   AvoMultiSafe owner
    /// @return         deployed address for the contract (AvoMultiSafe)
    function deployMultisig(address owner_) external returns (address);

    /// @notice                    Deploys an Avocado Multisig with non-default version for an `owner_`
    ///                            deterministcally using Create2.
    ///                            Does not check if contract at address already exists (AvoForwarder does that)
    /// @param owner_              AvoMultiSafe owner
    /// @param avoMultisigVersion_ Version of AvoMultisig logic contract to deploy
    /// @return                    deployed address for the contract (AvoMultiSafe)
    function deployMultisigWithVersion(address owner_, address avoMultisigVersion_) external returns (address);

    /// @notice                registry can update the current AvoWallet implementation contract set as default
    ///                        `_avoWalletImpl` logic contract address for new deployments
    /// @param avoWalletImpl_  the new avoWalletImpl address
    function setAvoWalletImpl(address avoWalletImpl_) external;

    /// @notice                 registry can update the current AvoMultisig implementation contract set as default
    ///                         `_avoMultisigImpl` logic contract address for new deployments
    /// @param avoMultisigImpl_ the new avoWalletImpl address
    function setAvoMultisigImpl(address avoMultisigImpl_) external;

    /// @notice returns the byteCode for the AvoSafe contract used for Create2 address computation
    function avoSafeBytecode() external view returns (bytes32);

    /// @notice returns the byteCode for the AvoMultiSafe contract used for Create2 address computation
    function avoMultiSafeBytecode() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { IAvoFactory } from "./IAvoFactory.sol";

interface IAvoForwarder {
    /// @notice returns the AvoFactory (proxy) address
    function avoFactory() external view returns (IAvoFactory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { AvoCoreStructs } from "../AvoCore/AvoCoreStructs.sol";

// @dev base interface without getters for storage variables (to avoid overloads issues)
interface IAvoMultisigV3Base is AvoCoreStructs {
    /// @notice        initializer called by AvoFactory after deployment, sets the `owner_` as owner and as only signer
    /// @param owner_  the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice                     initialize contract same as `initialize()` but also sets a different
    ///                             logic contract implementation address `avoMultisigVersion_`
    /// @param owner_               the owner (immutable) of this smart wallet
    /// @param avoMultisigVersion_  version of AvoMultisig logic contract to initialize
    function initializeWithVersion(address owner_, address avoMultisigVersion_) external;

    /// @notice returns the domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice               gets the digest (hash) used to verify an EIP712 signature for `cast()`.
    ///
    ///                       This is also used as the non-sequential nonce that will be marked as used when the
    ///                       request with the matching `params_` and `forwardParams_` is executed via `cast()`.
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_ Cast params related to validity of forwarding as instructed and signed
    /// @return               bytes32 digest to verify signature (or used as non-sequential nonce)
    function getSigDigest(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_
    ) external view returns (bytes32);

    /// @notice                   gets the digest (hash) used to verify an EIP712 signature for `castAuthorized()`.
    ///
    ///                           This is also the non-sequential nonce that will be marked as used when the request
    ///                           with the matching `params_` and `authorizedParams_` is executed via `castAuthorized()`.
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @return                   bytes32 digest to verify signature (or used as non-sequential nonce)
    function getSigDigestAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external view returns (bytes32);

    /// @notice                   Verify the signatures for a `cast()' call are valid and can be executed.
    ///                           This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                           Does not revert and returns successfully if the input is valid.
    ///                           Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_     Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_  SignatureParams structs array for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                             For smart contract signatures it must fulfill the requirements for the relevant
    ///                             smart contract `.isValidSignature()` EIP1271 logic
    ///                           - signer: address of the signature signer.
    ///                             Must match the actual signature signer or refer to the smart contract
    ///                             that must be an allowed signer and validates signature via EIP1271
    /// @return                   returns true if everything is valid, otherwise reverts
    function verify(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool);

    /// @notice                   Verify the signatures for a `castAuthorized()' call are valid and can be executed.
    ///                           This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                           Does not revert and returns successfully if the input is valid.
    ///                           Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @param signaturesParams_  SignatureParams structs array for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                             For smart contract signatures it must fulfill the requirements for the relevant
    ///                             smart contract `.isValidSignature()` EIP1271 logic
    ///                           - signer: address of the signature signer.
    ///                             Must match the actual signature signer or refer to the smart contract
    ///                             that must be an allowed signer and validates signature via EIP1271
    /// @return                   returns true if everything is valid, otherwise reverts
    function verifyAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool);

    /// @notice                   Executes arbitrary `actions_` with valid signatures. Only executable by AvoForwarder.
    ///                           If one action fails, the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           In that case, all previous actions are reverted.
    ///                           On success, emits CastExecuted event.
    /// @dev                      validates EIP712 signature then executes each action via .call or .delegatecall
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_     Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_  SignatureParams structs array for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                             For smart contract signatures it must fulfill the requirements for the relevant
    ///                             smart contract `.isValidSignature()` EIP1271 logic
    ///                           - signer: address of the signature signer.
    ///                             Must match the actual signature signer or refer to the smart contract
    ///                             that must be an allowed signer and validates signature via EIP1271
    /// @return success           true if all actions were executed succesfully, false otherwise.
    /// @return revertReason      revert reason if one of the actions fails in the following format:
    ///                           The revert reason will be prefixed with the index of the action.
    ///                           e.g. if action 1 fails, then the reason will be "1_reason".
    ///                           if an action in the flashloan callback fails (or an otherwise nested action),
    ///                           it will be prefixed with with two numbers: "1_2_reason".
    ///                           e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails,
    ///                           the reason will be 1_2_reason.
    function cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice                   Executes arbitrary `actions_` through authorized transaction sent with valid signatures.
    ///                           Includes a fee in native network gas token, amount depends on registry `calcFee()`.
    ///                           If one action fails, the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           In that case, all previous actions are reverted.
    ///                           On success, emits CastExecuted event.
    /// @dev                      executes a .call or .delegateCall for every action (depending on params)
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @param signaturesParams_  SignatureParams structs array for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                             For smart contract signatures it must fulfill the requirements for the relevant
    ///                             smart contract `.isValidSignature()` EIP1271 logic
    ///                           - signer: address of the signature signer.
    ///                             Must match the actual signature signer or refer to the smart contract
    ///                             that must be an allowed signer and validates signature via EIP1271
    /// @return success           true if all actions were executed succesfully, false otherwise.
    /// @return revertReason      revert reason if one of the actions fails in the following format:
    ///                           The revert reason will be prefixed with the index of the action.
    ///                           e.g. if action 1 fails, then the reason will be "1_reason".
    ///                           if an action in the flashloan callback fails (or an otherwise nested action),
    ///                           it will be prefixed with with two numbers: "1_2_reason".
    ///                           e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails,
    ///                           the reason will be 1_2_reason.
    function castAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice checks if an address `signer_` is an allowed signer (returns true if allowed)
    function isSigner(address signer_) external view returns (bool);

    /// @notice returns allowed signers on AvoMultisig wich can trigger actions if reaching quorum `requiredSigners`.
    ///         signers automatically include owner.
    function signers() external view returns (address[] memory signers);
}

// @dev full interface with some getters for storage variables
interface IAvoMultisigV3 is IAvoMultisigV3Base {
    /// @notice AvoMultisig Owner
    function owner() external view returns (address);

    /// @notice Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice incrementing nonce for each valid tx executed (to ensure uniqueness)
    function avoSafeNonce() external view returns (uint88);

    /// @notice returns the number of allowed signers
    function signersCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoSignersList {
    /// @notice adds mappings of `addSigners_` to an AvoMultiSafe `avoMultiSafe_`.
    ///         checks the data present at the AvoMultisig to validate input data.
    ///
    /// If `trackInStorage` flag is set to false, then only an event will be emitted for off-chain tracking.
    /// The contract itself will not track avoMultiSafes per signer on-chain!
    ///
    /// Silently ignores `addSigners_` that are already added
    ///
    /// There is expectedly no need for this method to be called by anyone other than the AvoMultisig itself.
    function syncAddAvoSignerMappings(address avoMultiSafe_, address[] calldata addSigners_) external;

    /// @notice removes mappings of `removeSigners_` from an AvoMultiSafe `avoMultiSafe_`.
    ///         checks the data present at the AvoMultisig to validate input data.
    ///
    /// If `trackInStorage` flag is set to false, then only an event will be emitted for off-chain tracking.
    /// The contract itself will not track avoMultiSafes per signer on-chain!
    ///
    /// Silently ignores `addSigners_` that are already removed
    ///
    /// There is expectedly no need for this method to be called by anyone other than the AvoMultisig itself.
    function syncRemoveAvoSignerMappings(address avoMultiSafe_, address[] calldata removeSigners_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoFeeCollector {
    /// @notice fee config params used to determine the fee for Avocado smart wallet `castAuthorized()` calls
    struct FeeConfig {
        /// @param feeCollector address that the fee should be paid to
        address payable feeCollector;
        /// @param mode current fee mode: 0 = percentage fee (gas cost markup); 1 = static fee (better for L2)
        uint8 mode;
        /// @param fee current fee amount:
        /// - for mode percentage: fee in 1e6 percentage (1e8 = 100%, 1e6 = 1%)
        /// - for static mode: absolute amount in native gas token to charge
        ///                    (max value 30_9485_009,821345068724781055 in 1e18)
        uint88 fee;
    }

    /// @notice calculates the `feeAmount_` for an AvoSafe (`msg.sender`) transaction `gasUsed_` based on
    ///         fee configuration present on the contract
    /// @param gasUsed_       amount of gas used, required if mode is percentage. not used if mode is static fee.
    /// @return feeAmount_    calculate fee amount to be paid
    /// @return feeCollector_ address to send the fee to
    function calcFee(uint256 gasUsed_) external view returns (uint256 feeAmount_, address payable feeCollector_);
}

interface IAvoVersionsRegistry is IAvoFeeCollector {
    /// @notice                   checks if an address is listed as allowed AvoWallet version, reverts if not.
    /// @param avoWalletVersion_  address of the Avo wallet logic contract to check
    function requireValidAvoWalletVersion(address avoWalletVersion_) external view;

    /// @notice                      checks if an address is listed as allowed AvoForwarder version, reverts if not.
    /// @param avoForwarderVersion_  address of the AvoForwarder logic contract to check
    function requireValidAvoForwarderVersion(address avoForwarderVersion_) external view;

    /// @notice                     checks if an address is listed as allowed AvoMultisig version, reverts if not.
    /// @param avoMultisigVersion_  address of the AvoMultisig logic contract to check
    function requireValidAvoMultisigVersion(address avoMultisigVersion_) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoWalletV1 {
    /// @notice an executable action via low-level call, including target, data and value
    struct Action {
        address target; // the targets to execute the actions on
        bytes data; // the data to be passed to the .call for each target
        uint256 value; // the msg.value to be passed to the .call for each target. set to 0 if none
    }

    /// @notice             AvoSafe Owner
    function owner() external view returns (address);

    /// @notice             Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice             Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice             incrementing nonce for each valid tx executed (to ensure unique)
    function avoSafeNonce() external view returns (uint96);

    /// @notice             initializer called by AvoFactory after deployment
    /// @param owner_       the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice             returns the domainSeparator for EIP712 signature
    /// @return             the bytes32 domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice             Verify the transaction is valid and can be executed.
    ///                     Does not revert and returns successfully if the input is valid.
    ///                     Reverts if any validation has failed. For instance, if params or either signature or avoSafeNonce are incorrect.
    /// @param actions_     the actions to execute (target, data, value)
    /// @param validUntil_  As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                     Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                     have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas_         As EIP-2770: an amount of gas limit to set for the execution
    ///                     Protects against potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                     See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @param source_      Source like e.g. referral for this tx
    /// @param metadata_    Optional metadata for future flexibility
    /// @param signature_   the EIP712 signature, see verifySig method
    /// @return             returns true if everything is valid, otherwise reverts
    function verify(
        Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external view returns (bool);

    /// @notice               executes arbitrary actions according to datas on targets
    ///                       if one action fails, the transaction doesn't revert. Instead the CastFailed event is emitted
    ///                       and all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                  validates EIP712 signature then executes a .call for every action.
    /// @param actions_       the actions to execute (target, data, value)
    /// @param validUntil_    As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                       Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                       have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas_           As EIP-2770: an amount of gas limit to set for the execution
    ///                       Protects against potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @param source_        Source like e.g. referral for this tx
    /// @param metadata_      Optional metadata for future flexibility
    /// @param signature_     the EIP712 signature, see verifySig method
    /// @return success       true if all actions were executed succesfully, false otherwise.
    /// @return revertReason  revert reason if one of the actions fail
    function cast(
        Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external payable returns (bool success, string memory revertReason);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoWalletV2 {
    /// @notice an executable action via low-level call, including operation (call or delegateCall), target, data and value
    struct Action {
        /// @param target the target to execute the actions on
        address target;
        /// @param data the data to be passed to the call for each target
        bytes data;
        /// @param value the msg.value to be passed to the call for each target. set to 0 if none
        uint256 value;
        /// @param operation type of operation to execute:
        /// 0 -> .call; 1 -> .delegateCall, 2 -> flashloan (via .call), id must be 0 or 2
        uint256 operation;
    }

    /// @notice `cast()` and `castAuthorized()` input params
    struct CastParams {
        /// @param validUntil     Similar to EIP-2770: the highest block timestamp (instead of block number)
        ///                       that the request can be forwarded in, or 0 if request validity is not time-limited.
        ///                       Protects against relayers executing a certain transaction at a later moment
        ///                       not intended by the user, where it might have a completely different effect.
        ///                       (Given that the transaction is not executed right away for some reason)
        uint256 validUntil;
        /// @param gas            As EIP-2770: an amount of gas limit to set for the execution
        ///                       Protects against potential gas griefing attacks & ensures the relayer sends enough gas
        ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        uint256 gas;
        /// @param source         Source like e.g. referral for this tx
        address source;
        /// @param id             id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
        uint256 id;
        /// @param metadata       Optional metadata for future flexibility
        bytes metadata;
    }

    /// @notice             AvoSafe Owner
    function owner() external view returns (address);

    /// @notice             Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice             Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice             incrementing nonce for each valid tx executed (to ensure unique)
    function avoSafeNonce() external view returns (uint88);

    /// @notice             initializer called by AvoFactory after deployment
    /// @param owner_       the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice                     initialize contract and set new AvoWallet version
    /// @param owner_               the owner (immutable) of this smart wallet
    /// @param avoWalletVersion_    version of AvoWallet logic contract to deploy
    function initializeWithVersion(address owner_, address avoWalletVersion_) external;

    /// @notice             returns the domainSeparator for EIP712 signature
    /// @return             the bytes32 domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice               Verify the transaction signature is valid and can be executed.
    ///                       This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                       Does not revert and returns successfully if the input is valid.
    ///                       Reverts if any validation has failed. For instance, if params or either signature or avoSafeNonce are incorrect.
    /// @param actions_       the actions to execute (target, data, value, operation)
    /// @param params_        Cast params: validUntil, gas, source, id and metadata
    /// @param signature_     the EIP712 signature, see verifySig method
    /// @return               returns true if everything is valid, otherwise reverts
    function verify(
        Action[] calldata actions_,
        CastParams calldata params_,
        bytes calldata signature_
    ) external view returns (bool);

    /// @notice               executes arbitrary `actions_` with a valid signature
    ///                       if one action fails, the transaction doesn't revert. Instead the CastFailed event is emitted
    ///                       and all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                  validates EIP712 signature then executes a .call or .delegateCall for every action (depending on params).
    /// @param actions_       the actions to execute (target, data, value, operation)
    /// @param params_        Cast params: validUntil, gas, source, id and metadata
    /// @param signature_     the EIP712 signature, see verifySig method
    /// @return success       true if all actions were executed succesfully, false otherwise.
    /// @return revertReason  revert reason if one of the actions fails
    function cast(
        Action[] calldata actions_,
        CastParams calldata params_,
        bytes calldata signature_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice               executes arbitrary `actions_` through authorized tx sent by owner.
    ///                       Includes a fee to be paid in native network gas currency, depends on registry feeConfig
    ///                       if one action fails, the transaction doesn't revert. Instead the CastFailed event is emitted
    ///                       and all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                  executes a .call or .delegateCall for every action (depending on params)
    /// @param actions_       the actions to execute (target, data, value, operation)
    /// @param params_        Cast params: validUntil, gas, source, id and metadata
    /// @param maxFee_        the maximum acceptable fee expected to be paid (gas premium)
    /// @return success       true if all actions were executed succesfully, false otherwise.
    /// @return revertReason  revert reason if one of the actions fails
    function castAuthorized(
        Action[] calldata actions_,
        CastParams calldata params_,
        uint80 maxFee_
    ) external payable returns (bool success, string memory revertReason);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { AvoCoreStructs } from "../AvoCore/AvoCoreStructs.sol";

// @dev base interface without getters for storage variables (to avoid overloads issues)
interface IAvoWalletV3Base is AvoCoreStructs {
    /// @notice        initializer called by AvoFactory after deployment, sets the `owner_` as owner
    /// @param owner_  the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice                   initialize contract same as `initialize()` but also sets a different
    ///                           logic contract implementation address `avoWalletVersion_`
    /// @param owner_             the owner (immutable) of this smart wallet
    /// @param avoWalletVersion_  version of AvoMultisig logic contract to initialize
    function initializeWithVersion(address owner_, address avoWalletVersion_) external;

    /// @notice returns the domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice                    returns non-sequential nonce that will be marked as used when the request with the
    ///                            matching `params_` and `authorizedParams_` is executed via `castAuthorized()`.
    /// @param params_             Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_   Cast params related to execution through owner such as maxFee
    /// @return                    bytes32 non sequential nonce
    function nonSequentialNonceAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external view returns (bytes32);

    /// @notice               gets the digest (hash) used to verify an EIP712 signature
    ///
    ///                       This is also used as the non-sequential nonce that will be marked as used when the
    ///                       request with the matching `params_` and `forwardParams_` is executed via `cast()`.
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_ Cast params related to validity of forwarding as instructed and signed
    /// @return               bytes32 digest to verify signature (or used as non-sequential nonce)
    function getSigDigest(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_
    ) external view returns (bytes32);

    /// @notice                 Verify the transaction signature is valid and can be executed.
    ///                         This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                         Does not revert and returns successfully if the input is valid.
    ///                         Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_   Cast params related to validity of forwarding as instructed and signed
    /// @param signatureParams_ struct for signature and signer:
    ///                         - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                         - signer: address of the signature signer.
    ///                           Must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return                 returns true if everything is valid, otherwise reverts
    function verify(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams calldata signatureParams_
    ) external view returns (bool);

    /// @notice                 Executes arbitrary `actions_` with valid signature. Only executable by AvoForwarder.
    ///                         If one action fails, the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                         In that case, all previous actions are reverted.
    ///                         On success, emits CastExecuted event.
    /// @dev                    validates EIP712 signature then executes each action via .call or .delegatecall
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_   Cast params related to validity of forwarding as instructed and signed
    /// @param signatureParams_ struct for signature and signer:
    ///                         - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                         - signer: address of the signature signer.
    ///                           Must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return success         true if all actions were executed succesfully, false otherwise.
    /// @return revertReason    revert reason if one of the actions fails in the following format:
    ///                         The revert reason will be prefixed with the index of the action.
    ///                         e.g. if action 1 fails, then the reason will be "1_reason".
    ///                         if an action in the flashloan callback fails (or an otherwise nested action),
    ///                         it will be prefixed with with two numbers: "1_2_reason".
    ///                         e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails,
    ///                         the reason will be 1_2_reason.
    function cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams calldata signatureParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice                  Executes arbitrary `actions_` through authorized transaction sent by owner.
    ///                          Includes a fee in native network gas token, amount depends on registry `calcFee()`.
    ///                          If one action fails, the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                          In that case, all previous actions are reverted.
    ///                          On success, emits CastExecuted event.
    /// @dev                     executes a .call or .delegateCall for every action (depending on params)
    /// @param params_           Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_ Cast params related to execution through owner such as maxFee
    /// @return success          true if all actions were executed succesfully, false otherwise.
    /// @return revertReason     revert reason if one of the actions fails in the following format:
    ///                          The revert reason will be prefixed with the index of the action.
    ///                          e.g. if action 1 fails, then the reason will be "1_reason".
    ///                          if an action in the flashloan callback fails (or an otherwise nested action),
    ///                          it will be prefixed with with two numbers: "1_2_reason".
    ///                          e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails,
    ///                          the reason will be 1_2_reason.
    function castAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice checks if an address `authority_` is an allowed authority (returns true if allowed)
    function isAuthority(address authority_) external view returns (bool);
}

// @dev full interface with some getters for storage variables
interface IAvoWalletV3 is IAvoWalletV3Base {
    /// @notice AvoWallet Owner
    function owner() external view returns (address);

    /// @notice Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice incrementing nonce for each valid tx executed (to ensure uniqueness)
    function avoSafeNonce() external view returns (uint88);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract EmptyImplementation {

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract MockDelegateCallTarget {
    // same storage layout as VariablesV1.sol
    address internal _avoWalletImpl;
    uint88 internal _avoSafeNonce;
    uint8 internal _status;
    address internal _owner;
    uint8 internal _initialized;
    bool internal _initializing;
    mapping(bytes32 => uint256) internal _signedMessages;
    mapping(bytes32 => uint256) public nonSequentialNonces;
    uint256[50] private __gap;
    // storage slot 54 (Multisig):
    address internal _signersPointer;
    uint8 internal requiredSigners;
    uint8 internal signersCount;

    // custom storage for mock contract after gap
    uint256[45] private __gap2;

    uint256 public callCount;

    bytes32 public constant TAMPERED_KEY = keccak256("TESTKEY");

    event Called(address indexed sender, bytes data, uint256 indexed usedBalance, uint256 callCount);

    function emitCalled() external payable {
        callCount = callCount + 1;

        emit Called(msg.sender, msg.data, 0, callCount);
    }

    function tryModifyOwner() external {
        callCount = callCount + 1;

        _owner = address(0x01);
        emit Called(msg.sender, msg.data, 0, callCount);
    }

    function tryModifyAvoWalletImpl() external {
        callCount = callCount + 1;

        _avoWalletImpl = address(0x01);
        emit Called(msg.sender, msg.data, 0, callCount);
    }

    function tryModifyAvoSafeNonce() external {
        callCount = callCount + 1;

        _avoSafeNonce = 42375823785;
        emit Called(msg.sender, msg.data, 0, callCount);
    }

    function trySetStatus() external {
        callCount = callCount + 1;

        _status = 77;
        emit Called(msg.sender, msg.data, 0, callCount);
    }

    function trySetInitializing() external {
        callCount = callCount + 1;

        _initializing = true;
        emit Called(msg.sender, msg.data, 0, callCount);
    }

    function trySetInitialized() external {
        callCount = callCount + 1;

        _initialized = 77;
        emit Called(msg.sender, msg.data, 0, callCount);
    }

    function trySetSignersPointer() external {
        callCount = callCount + 1;

        _signersPointer = address(1);
        emit Called(msg.sender, msg.data, 0, callCount);
    }

    function trySetRequiredSigners() external {
        callCount = callCount + 1;

        requiredSigners = 77;
        emit Called(msg.sender, msg.data, 0, callCount);
    }

    function trySetSignersCount() external {
        callCount = callCount + 1;

        signersCount = 77;
        emit Called(msg.sender, msg.data, 0, callCount);
    }

    function trySetSignedMessage() external {
        callCount = callCount + 1;

        _signedMessages[TAMPERED_KEY] = 77;
        emit Called(msg.sender, msg.data, 0, callCount);
    }

    function triggerRevert() external pure {
        revert("MOCK_REVERT");
    }

    function transferAmountTo(address to, uint256 amount) external payable {
        callCount = callCount + 1;

        payable(to).transfer(amount);

        emit Called(msg.sender, msg.data, amount, callCount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockDeposit {
    using SafeERC20 for IERC20;

    event Deposit(address indexed from, uint256 indexed amount);
    event Withdraw(address indexed to, uint256 indexed amount);

    IERC20 public asset;

    constructor(IERC20 _asset) {
        asset = _asset;
    }

    function deposit(uint256 amount_) external {
        asset.safeTransferFrom(msg.sender, address(this), amount_);
        emit Deposit(msg.sender, amount_);
    }

    function withdraw(uint256 amount_) external {
        asset.safeTransfer(msg.sender, amount_);
        emit Withdraw(msg.sender, amount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MockERC1967Proxy is ERC1967Proxy {
    constructor(address _logic, bytes memory _data) payable ERC1967Proxy(_logic, _data) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20Token is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, 1e18 * 1e18);
    }

    function mint() external {
        _mint(msg.sender, 1e18 * 1e18);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721Token is ERC721 {
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        // mint 100 nfts to msg.sender
        for (uint256 i; i < 100; ++i) {
            _safeMint(msg.sender, i);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract MockFailingFeeCollector {
    receive() external payable {
        revert();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";

contract MockSigner is IERC1271 {
    /// @dev "magic value" according to EIP1271 https://eips.ethereum.org/EIPS/eip-1271#specification
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x1626ba7e;

    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    /// @dev returns valid magic value if signer is owner
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue) {
        address recoveredSigner_ = ECDSA.recover(hash, signature);

        return recoveredSigner_ == owner ? EIP1271_MAGIC_VALUE : bytes4("");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";

contract MockSignerArbitrarySigLength is IERC1271 {
    /// @dev "magic value" according to EIP1271 https://eips.ethereum.org/EIPS/eip-1271#specification
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x1626ba7e;

    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    /// @dev returns valid magic value if signer is owner, using the first 65 bytes to validate. cutting of the rest
    /// to simulate a case where a smart contract signer implements some other non ECDSA default algorithm
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue) {
        bytes memory signerBytes_ = signature[0:65];

        address recoveredSigner_ = ECDSA.recover(hash, signerBytes_);

        return recoveredSigner_ == owner ? EIP1271_MAGIC_VALUE : bytes4("");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract MockWETH {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}