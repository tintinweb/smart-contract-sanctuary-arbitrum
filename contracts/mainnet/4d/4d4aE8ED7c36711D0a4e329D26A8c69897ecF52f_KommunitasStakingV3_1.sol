// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            _functionDelegateCall(newImplementation, data);
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
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
library StorageSlotUpgradeable {
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

pragma solidity 0.8.13;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';

import './interface/IERC20MintableBurnableUpgradeable.sol';
import './interface/IKommunitasStakingV3.sol';
import './util/AdminProxyManager.sol';
import './util/OwnableUpgradeable.sol';

contract KommunitasStakingV3 is
  Initializable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable,
  AdminProxyManager,
  IKommunitasStakingV3
{
  using SafeERC20Upgradeable for IERC20MintableBurnableUpgradeable;

  uint256 private constant yearInSeconds = 365 * 86400;

  uint64 public minStaking;
  uint64 public minPrivatePartner;
  uint64 public minGetKomV; // min kom staked to receive komVToken

  uint16 public minLockIndexGetGiveaway; // min lock index to be choosen to join free token giveaway
  uint16 public lockNumber;
  uint32 public workerNumber;

  uint256 public giveawayStakedAmount;
  uint256 public privatePartnerStakedAmount;

  address[] public staker;

  address public komToken; // Kommunitas Token
  address public komVToken; // Kommunitas Voting Token
  address public savior; // who will wd

  enum CompoundTypes {
    NoCompound,
    RewardOnly,
    PrincipalAndReward
  }

  struct Lock {
    uint128 lockPeriodInSeconds;
    uint64 apy_d2;
    uint64 feeInPercent_d2;
    uint256 komStaked;
    uint256 pendingReward;
  }

  struct Stake {
    uint16 lockIndex;
    uint232 userStakedIndex;
    CompoundTypes compoundType;
    uint256 amount;
    uint256 reward;
    uint128 stakedAt;
    uint128 endedAt;
  }

  struct StakeData {
    uint256 stakedAmount;
    uint256 stakerPendingReward;
  }

  mapping(uint16 => Lock) private lock;
  mapping(address => uint232) private stakerIndex;
  mapping(address => Stake[]) private staked;

  mapping(address => StakeData) public stakerDetail;
  mapping(address => bool) public isWorker;
  mapping(address => bool) public isTrustedForwarder;
  mapping(address => bool) public hasKomV;

  /* ========== EVENTS ========== */

  event Staked(
    address indexed stakerAddress,
    uint128 lockPeriodInDays,
    CompoundTypes compoundType,
    uint256 amount,
    uint256 reward,
    uint128 stakedAt,
    uint128 endedAt
  );
  event Unstaked(
    address indexed stakerAddress,
    uint128 lockPeriodInDays,
    CompoundTypes compoundType,
    uint256 amount,
    uint256 reward,
    uint256 prematurePenalty,
    uint128 stakedAt,
    uint128 endedAt,
    uint128 unstakedAt,
    bool isPremature
  );

  function init(
    address _komToken,
    address _komVToken,
    uint128[] calldata _lockPeriodInDays,
    uint64[] calldata _apy_d2,
    uint64[] calldata _feeInPercent_d2,
    address _savior
  ) external initializer proxied {
    __UUPSUpgradeable_init();
    __Pausable_init();
    __Ownable_init();
    __AdminProxyManager_init(_msgSender());

    require(
      _lockPeriodInDays.length == _apy_d2.length &&
        _lockPeriodInDays.length == _feeInPercent_d2.length &&
        AddressUpgradeable.isContract(_komToken) &&
        AddressUpgradeable.isContract(_komVToken) &&
        _savior != address(0),
      'misslength'
    );

    komToken = _komToken;
    komVToken = _komVToken;
    lockNumber = uint16(_lockPeriodInDays.length);
    savior = _savior;

    uint16 i = 0;
    do {
      lock[i] = Lock({
        lockPeriodInSeconds: _lockPeriodInDays[i] * 86400,
        apy_d2: _apy_d2[i],
        feeInPercent_d2: _feeInPercent_d2[i],
        komStaked: 0,
        pendingReward: 0
      });

      ++i;
    } while (i < _lockPeriodInDays.length);

    minStaking = 100 * 1e8; // 100 komToken
    minPrivatePartner = 500000 * 1e8; // 500K komToken
    minGetKomV = 3000 * 1e8; // 3K komToken
    minLockIndexGetGiveaway = uint16(_lockPeriodInDays.length - 1); // last lock index
  }

  function _authorizeUpgrade(address newImplementation) internal virtual override proxied {}

  function onlySavior() internal view virtual {
    require(_msgSender() == savior, '!savior');
  }

  function totalPendingReward() external view virtual returns (uint256 total) {
    for (uint16 i = 0; i < lockNumber; ++i) {
      total += lock[i].pendingReward;
    }
  }

  function totalKomStaked() external view virtual returns (uint256 total) {
    for (uint16 i = 0; i < lockNumber; ++i) {
      total += lock[i].komStaked;
    }
  }

  function stakerLength() external view virtual returns (uint256 length) {
    length = staker.length;
  }

  function locked(
    uint16 _lockIndex
  )
    external
    view
    virtual
    returns (uint128 lockPeriodInDays, uint64 apy_d2, uint64 feeInPercent_d2, uint256 komStaked, uint256 pendingReward)
  {
    lockPeriodInDays = lock[_lockIndex].lockPeriodInSeconds / 86400;
    apy_d2 = lock[_lockIndex].apy_d2;
    feeInPercent_d2 = lock[_lockIndex].feeInPercent_d2;
    komStaked = lock[_lockIndex].komStaked;
    pendingReward = lock[_lockIndex].pendingReward;
  }

  function userStakedLength(address _staker) external view virtual returns (uint256 length) {
    length = staked[_staker].length;
  }

  function getStakedDetail(
    address _staker,
    uint232 _userStakedIndex
  )
    external
    view
    virtual
    returns (
      uint128 lockPeriodInDays,
      CompoundTypes compoundType,
      uint256 amount,
      uint256 reward,
      uint256 prematurePenalty,
      uint128 stakedAt,
      uint128 endedAt
    )
  {
    // get stake data
    Stake memory stakeDetail = staked[_staker][_userStakedIndex];

    lockPeriodInDays = lock[stakeDetail.lockIndex].lockPeriodInSeconds / 86400;
    compoundType = stakeDetail.compoundType;
    amount = stakeDetail.amount;
    reward = stakeDetail.reward;
    prematurePenalty = (stakeDetail.amount * lock[stakeDetail.lockIndex].feeInPercent_d2) / 10000;
    stakedAt = stakeDetail.stakedAt;
    endedAt = stakeDetail.endedAt;
  }

  function getTotalWithdrawableTokens(address _staker) external view virtual returns (uint256 withdrawableTokens) {
    for (uint232 i = 0; i < staked[_staker].length; ++i) {
      if (staked[_staker][i].endedAt < block.timestamp) {
        withdrawableTokens += staked[_staker][i].amount + staked[_staker][i].reward;
      }
    }
  }

  function getTotalLockedTokens(address _staker) external view virtual returns (uint256 lockedTokens) {
    for (uint232 i = 0; i < staked[_staker].length; ++i) {
      if (staked[_staker][i].endedAt >= block.timestamp) {
        lockedTokens += staked[_staker][i].amount + staked[_staker][i].reward;
      }
    }
  }

  function getUserNextUnlock(
    address _staker
  ) external view virtual returns (uint128 nextUnlockTime, uint256 nextUnlockRewards) {
    for (uint232 i = 0; i < staked[_staker].length; ++i) {
      Stake memory stakeDetail = staked[_staker][i];
      if (stakeDetail.endedAt >= block.timestamp) {
        if (nextUnlockTime == 0 || nextUnlockTime > stakeDetail.endedAt) {
          nextUnlockTime = stakeDetail.endedAt;
          nextUnlockRewards = stakeDetail.reward;
        }
      }
    }
  }

  function getUserStakedGiveawayEligibleBeforeDate(
    address _staker,
    uint128 _beforeAt
  ) external view virtual returns (uint256 lockedTokens) {
    for (uint232 i = 0; i < staked[_staker].length; ++i) {
      Stake memory stakeDetail = staked[_staker][i];
      if (stakeDetail.lockIndex >= minLockIndexGetGiveaway && stakeDetail.stakedAt <= _beforeAt) {
        lockedTokens += stakeDetail.amount;
      }
    }
  }

  function getUserStakedTokensBeforeDate(
    address _staker,
    uint128 _beforeAt
  ) external view virtual returns (uint256 lockedTokens) {
    for (uint232 i = 0; i < staked[_staker].length; ++i) {
      Stake memory stakeDetail = staked[_staker][i];
      if (stakeDetail.stakedAt <= _beforeAt) {
        lockedTokens += stakeDetail.amount;
      }
    }
  }

  function getTotalStakedAmountBeforeDate(uint128 _beforeAt) external view virtual returns (uint256 totalStaked) {
    for (uint256 i = 0; i < staker.length; ++i) {
      for (uint232 j = 0; j < staked[staker[i]].length; ++j) {
        if (staked[staker[i]][j].stakedAt <= _beforeAt) {
          totalStaked += staked[staker[i]][j].amount;
        }
      }
    }
  }

  function calculateReward(uint256 _amount, uint16 _lockIndex) public view virtual returns (uint256 reward) {
    Lock memory lockDetail = lock[_lockIndex];

    uint256 effectiveAPY = lockDetail.apy_d2 * lockDetail.lockPeriodInSeconds;
    reward = (_amount * effectiveAPY) / (yearInSeconds * 10000);
  }

  function stake(uint256 _amount, uint16 _lockIndex, CompoundTypes _compoundType) external virtual whenNotPaused {
    require(
      _amount >= minStaking, // validate min amount to stake
      '<min'
    );

    // fetch sender
    address sender = _msgSender();

    // push staker if eligible
    if (staked[sender].length == 0) {
      staker.push(sender);
      stakerIndex[sender] = uint232(staker.length - 1);
    }

    // stake
    _stake(sender, _amount, _lockIndex, _compoundType);

    // take out komToken
    IERC20MintableBurnableUpgradeable(komToken).safeTransferFrom(sender, address(this), _amount);
  }

  function unstake(uint232 _userStakedIndex, uint256 _amount, address _staker) public virtual {
    // worker check
    if (isWorker[_msgSender()]) {
      require(block.timestamp > staked[_staker][_userStakedIndex].endedAt, 'premature');
    } else {
      _staker = _msgSender();
    }

    // validate existance of staker stake index
    require(staked[_staker].length > _userStakedIndex, 'bad');

    // get stake data
    Stake memory stakeDetail = staked[_staker][_userStakedIndex];

    if (block.timestamp > stakeDetail.endedAt) {
      _amount = stakeDetail.amount;
      // compound
      _compound(_staker, _amount, stakeDetail.lockIndex, stakeDetail.compoundType);
    } else {
      if (stakeDetail.amount > _amount) {
        uint256 remainderAmount = stakeDetail.amount - _amount;

        // stake remainder
        _stake(_staker, remainderAmount, stakeDetail.lockIndex, stakeDetail.compoundType);

        // adjust new staking amount to be partially withdrawn
        uint256 newPartialReward = calculateReward(_amount, stakeDetail.lockIndex);
        staked[_staker][_userStakedIndex].amount = _amount;
        staked[_staker][_userStakedIndex].reward = newPartialReward;

        // subtract staked amount & pending reward to staker
        stakerDetail[_staker].stakedAmount -= remainderAmount;
        stakerDetail[_staker].stakerPendingReward -= (stakeDetail.reward - newPartialReward);

        // subtract komStaked & pending reward to lock index
        lock[stakeDetail.lockIndex].komStaked -= remainderAmount;
        lock[stakeDetail.lockIndex].pendingReward -= (stakeDetail.reward - newPartialReward);

        // subtract to private if eligible
        if (stakeDetail.amount >= minPrivatePartner) privatePartnerStakedAmount -= stakeDetail.amount;
        if (_amount >= minPrivatePartner) privatePartnerStakedAmount += _amount;

        // subtract to giveaway if eligible
        if (stakeDetail.lockIndex >= minLockIndexGetGiveaway) giveawayStakedAmount -= remainderAmount;
      }
    }

    // unstake
    _unstake(_staker, _userStakedIndex, stakeDetail.endedAt >= block.timestamp);
  }

  function changeCompoundType(uint232 _userStakedIndex, CompoundTypes _newCompoundType) external virtual {
    // owner validation
    address _staker = _msgSender();

    // get stake data
    Stake memory stakeDetail = staked[_staker][_userStakedIndex];

    require(
      staked[_staker].length > _userStakedIndex && // user staked index validation
        stakeDetail.compoundType != _newCompoundType, // compound type validation
      'bad'
    );

    // assign new compound type
    staked[_staker][_userStakedIndex].compoundType = _newCompoundType;
  }

  function _stake(address _sender, uint256 _amount, uint16 _lockIndex, CompoundTypes _compoundType) internal virtual {
    require(
      _lockIndex < lockNumber, // validate existance of lock index
      '!lockIndex'
    );

    // calculate reward
    uint256 reward = calculateReward(_amount, _lockIndex);

    // add staked amount & pending reward to sender
    stakerDetail[_sender].stakedAmount += _amount;
    stakerDetail[_sender].stakerPendingReward += reward;

    // add komStaked & pending reward to lock index
    lock[_lockIndex].komStaked += _amount;
    lock[_lockIndex].pendingReward += reward;

    // add to private if eligible
    if (_amount >= minPrivatePartner) privatePartnerStakedAmount += _amount;

    // add to giveaway if eligible
    if (_lockIndex >= minLockIndexGetGiveaway) giveawayStakedAmount += _amount;

    // push stake struct to staked mapping
    staked[_sender].push(
      Stake({
        lockIndex: _lockIndex,
        userStakedIndex: uint232(staked[_sender].length),
        compoundType: _compoundType,
        amount: _amount,
        reward: reward,
        stakedAt: uint128(block.timestamp),
        endedAt: uint128(block.timestamp) + lock[_lockIndex].lockPeriodInSeconds
      })
    );

    // mint komVToken if eligible
    if (
      stakerDetail[_sender].stakedAmount >= minGetKomV &&
      IERC20MintableBurnableUpgradeable(komVToken).balanceOf(_sender) == 0
    ) {
      IERC20MintableBurnableUpgradeable(komVToken).mint(_sender, 1);
      if (!hasKomV[_sender]) hasKomV[_sender] = true;
    }

    // emit staked event
    emit Staked(
      _sender,
      lock[_lockIndex].lockPeriodInSeconds / 86400,
      _compoundType,
      _amount,
      reward,
      uint128(block.timestamp),
      uint128(block.timestamp) + lock[_lockIndex].lockPeriodInSeconds
    );
  }

  function _compound(
    address _sender,
    uint256 _amount,
    uint16 _lockIndex,
    CompoundTypes _compoundType
  ) internal virtual {
    if (_compoundType == CompoundTypes.RewardOnly) {
      _stake(_sender, _amount, _lockIndex, _compoundType);
    } else if (_compoundType == CompoundTypes.PrincipalAndReward) {
      uint256 reward = calculateReward(_amount, _lockIndex);
      _stake(_sender, _amount + reward, _lockIndex, _compoundType);
    }
  }

  function _unstake(address _sender, uint232 _userStakedIndex, bool _isPremature) internal virtual {
    // get stake data
    Stake memory stakeDetail = staked[_sender][_userStakedIndex];

    // subtract staked amount & pending reward to sender
    stakerDetail[_sender].stakedAmount -= stakeDetail.amount;
    stakerDetail[_sender].stakerPendingReward -= stakeDetail.reward;

    // subtract komStaked & pending reward to lock index
    lock[stakeDetail.lockIndex].komStaked -= stakeDetail.amount;
    lock[stakeDetail.lockIndex].pendingReward -= stakeDetail.reward;

    // subtract to private if eligible
    if (stakeDetail.amount >= minPrivatePartner) privatePartnerStakedAmount -= stakeDetail.amount;

    // subtract to giveaway if eligible
    if (stakeDetail.lockIndex >= minLockIndexGetGiveaway) giveawayStakedAmount -= stakeDetail.amount;

    // shifts struct from lastIndex to currentIndex & pop lastIndex from staked mapping
    staked[_sender][_userStakedIndex] = staked[_sender][staked[_sender].length - 1];
    staked[_sender][_userStakedIndex].userStakedIndex = _userStakedIndex;
    staked[_sender].pop();

    // remove staker if eligible
    if (staked[_sender].length == 0 && staker[stakerIndex[_sender]] == _sender) {
      uint232 indexToDelete = stakerIndex[_sender];
      address stakerToMove = staker[staker.length - 1];

      staker[indexToDelete] = stakerToMove;
      stakerIndex[stakerToMove] = indexToDelete;

      delete stakerIndex[_sender];
      staker.pop();
    }

    // burn komVToken if eligible
    if (
      stakerDetail[_sender].stakedAmount < minGetKomV &&
      IERC20MintableBurnableUpgradeable(komVToken).balanceOf(_sender) > 0
    ) {
      IERC20MintableBurnableUpgradeable(komVToken).burn(_sender, 1);
      if (hasKomV[_sender]) hasKomV[_sender] = false;
    }

    // set withdrawable amount to transfer
    uint256 withdrawableAmount = stakeDetail.amount + stakeDetail.reward;

    if (_isPremature) {
      // calculate penalty & staked amount to withdraw
      uint256 penaltyAmount = (stakeDetail.amount * lock[stakeDetail.lockIndex].feeInPercent_d2) / 10000;
      withdrawableAmount = stakeDetail.amount - penaltyAmount;

      // burn penalty
      IERC20MintableBurnableUpgradeable(komToken).burn(penaltyAmount);
    } else {
      if (stakeDetail.compoundType == CompoundTypes.RewardOnly) {
        withdrawableAmount = stakeDetail.reward;
      } else if (stakeDetail.compoundType == CompoundTypes.PrincipalAndReward) {
        emitUnstaked(
          _sender,
          lock[stakeDetail.lockIndex].lockPeriodInSeconds / 86400,
          stakeDetail.compoundType,
          stakeDetail.amount,
          stakeDetail.reward,
          0,
          stakeDetail.stakedAt,
          stakeDetail.endedAt,
          _isPremature
        );
        return;
      }
    }

    // send staked + reward to sender
    IERC20MintableBurnableUpgradeable(komToken).safeTransfer(_sender, withdrawableAmount);

    // emit unstaked event
    emitUnstaked(
      _sender,
      lock[stakeDetail.lockIndex].lockPeriodInSeconds / 86400,
      stakeDetail.compoundType,
      stakeDetail.amount,
      stakeDetail.reward,
      _isPremature ? (stakeDetail.amount * lock[stakeDetail.lockIndex].feeInPercent_d2) / 10000 : 0,
      stakeDetail.stakedAt,
      stakeDetail.endedAt,
      _isPremature
    );
  }

  function emitUnstaked(
    address _stakerAddress,
    uint128 _lockPeriodInDays,
    CompoundTypes _compoundType,
    uint256 _amount,
    uint256 _reward,
    uint256 _penaltyPremature,
    uint128 _stakedAt,
    uint128 _endedAt,
    bool _isPremature
  ) internal virtual {
    emit Unstaked(
      _stakerAddress,
      _lockPeriodInDays,
      _compoundType,
      _amount,
      _reward,
      _penaltyPremature,
      _stakedAt,
      _endedAt,
      uint128(block.timestamp),
      _isPremature
    );
  }

  function _msgSender() internal view virtual override returns (address sender) {
    if (isTrustedForwarder[msg.sender]) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      /// @solidity memory-safe-assembly
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return super._msgSender();
    }
  }

  function _msgData() internal view virtual override returns (bytes calldata) {
    if (isTrustedForwarder[msg.sender]) {
      return msg.data[:msg.data.length - 20];
    } else {
      return super._msgData();
    }
  }

  function addWorker(address _worker) external virtual onlyOwner {
    require(_worker != address(0) && !isWorker[_worker], 'bad');
    isWorker[_worker] = true;
    ++workerNumber;
  }

  function removeWorker(address _worker) external virtual onlyOwner {
    require(_worker != address(0) && isWorker[_worker], 'bad');
    isWorker[_worker] = false;
    --workerNumber;
  }

  function changeWorker(address _oldWorker, address _newWorker) external virtual onlyOwner {
    require(
      _oldWorker != address(0) && _newWorker != address(0) && isWorker[_oldWorker] && !isWorker[_newWorker],
      'bad'
    );
    isWorker[_oldWorker] = false;
    isWorker[_newWorker] = true;
  }

  function toggleTrustedForwarder(address _forwarder) external virtual onlyOwner {
    require(_forwarder != address(0), '0x0');
    isTrustedForwarder[_forwarder] = !isTrustedForwarder[_forwarder];
  }

  function setMin(
    uint64 _minStaking,
    uint64 _minPrivatePartner,
    uint64 _minGetKomV,
    uint16 _minLockIndexGetGiveaway
  ) external virtual whenPaused onlyOwner {
    if (_minStaking > 0) minStaking = _minStaking;
    if (_minPrivatePartner > 0) {
      minPrivatePartner = _minPrivatePartner;
      privatePartnerStakedAmount = 0; // reset private partner total staked amount
    }
    if (_minGetKomV > 0) minGetKomV = _minGetKomV;
    if (_minLockIndexGetGiveaway > 0) {
      minLockIndexGetGiveaway = _minLockIndexGetGiveaway;
      giveawayStakedAmount = 0; // reset giveaway total staked amount
    }

    // unpause
    _unpause();
  }

  function setPeriodInDays(uint16 _lockIndex, uint128 _newLockPeriodInDays) external virtual onlyOwner {
    require(
      lockNumber > _lockIndex && _newLockPeriodInDays >= 86400 && _newLockPeriodInDays <= (5 * yearInSeconds),
      'bad'
    );
    lock[_lockIndex].lockPeriodInSeconds = _newLockPeriodInDays * 86400;
  }

  function setPenaltyFee(uint16 _lockIndex, uint64 _feeInPercent_d2) external virtual onlyOwner {
    require(lockNumber > _lockIndex && _feeInPercent_d2 >= 100 && _feeInPercent_d2 < 10000, 'bad');
    lock[_lockIndex].feeInPercent_d2 = _feeInPercent_d2;
  }

  function setAPY(uint16 _lockIndex, uint64 _apy_d2) external virtual onlyOwner {
    require(lockNumber > _lockIndex && _apy_d2 < 10000, 'bad');
    lock[_lockIndex].apy_d2 = _apy_d2;
  }

  function setSavior(address _savior) external virtual {
    require(_savior != address(0), '0x0');
    onlySavior();
    savior = _savior;
  }

  function togglePause() external virtual onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  function emergencyWithdraw(address _token, uint256 _amount, address _receiver) external virtual {
    onlySavior();

    // adjust amount to wd
    uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
    if (_amount > balance) _amount = balance;

    IERC20MintableBurnableUpgradeable(_token).safeTransfer(_receiver, _amount);
  }

  function getStakerIndex(address _staker) external view virtual returns (uint232) {
    return stakerIndex[_staker];
  }

  function insertIntoArray(address[] calldata _users) external virtual onlyOwner {
    // push staker if eligible
    for (uint8 i = 0; i < _users.length; ++i) {
      if (
        staker[stakerIndex[_users[i]]] == _users[i] ||
        (staker[stakerIndex[_users[i]]] != _users[i] && staked[_users[i]].length == 0)
      ) continue;

      staker.push(_users[i]);
      stakerIndex[_users[i]] = uint232(staker.length - 1);
    }
  }

  function assignNewLockDataValue(
    uint16 _lockIndex,
    uint256 _komStaked,
    uint256 _pendingReward
  ) external virtual onlyOwner {
    require(_lockIndex < lockNumber, '!index');

    lock[_lockIndex].komStaked = _komStaked;
    lock[_lockIndex].pendingReward = _pendingReward;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./KommunitasStakingV3.sol";

contract KommunitasStakingV3_1 is KommunitasStakingV3 {
  bool public isUnstakePaused;

  function unstake(
    uint232 _userStakedIndex,
    uint256 _amount,
    address _staker
  ) public virtual override{
    require(!isUnstakePaused, "paused");
    super.unstake(_userStakedIndex, _amount, _staker);
  }

  function toggleUnstakePause() external virtual onlyOwner {
    isUnstakePaused = !isUnstakePaused;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IERC20MintableBurnableUpgradeable is IERC20MetadataUpgradeable {
  function mint(address to, uint256 amount) external;
  function burn(address to, uint256 amount) external;
  function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKommunitasStakingV3 {
  function giveawayStakedAmount() external view returns(uint256);
  function getUserStakedGiveawayEligibleBeforeDate(
    address _staker,
    uint128 _beforeAt
  ) external view returns (uint256 lockedTokens);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";

contract AdminProxyManager is
  Initializable,
  Proxied
{
  address private _pendingProxyAdmin;
    
  function __AdminProxyManager_init(address _sender) internal onlyInitializing {
    __AdminProxyManager_init_unchained(_sender);
  }

  function __AdminProxyManager_init_unchained(address _sender) internal onlyInitializing {
    assembly {
      sstore(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103, _sender)
    }
  }

  function proxyAdmin() external view virtual returns(address) {
    return _proxyAdmin();
  }

  function transferProxyAdmin(address _newProxyAdmin) external virtual proxied {
    _pendingProxyAdmin = _newProxyAdmin;
  }

  function _transferProxyAdmin(address _newProxyAdmin) internal virtual {
    delete _pendingProxyAdmin;
    assembly {
      sstore(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103, _newProxyAdmin)
    }
  }

  function acceptProxyAdmin() external virtual {
    address sender = msg.sender;
    require(_pendingProxyAdmin == sender, "bad");
    _transferProxyAdmin(sender);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
pragma solidity ^0.8.0;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address ownerAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            ownerAddress := sload(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)
        }
    }
}