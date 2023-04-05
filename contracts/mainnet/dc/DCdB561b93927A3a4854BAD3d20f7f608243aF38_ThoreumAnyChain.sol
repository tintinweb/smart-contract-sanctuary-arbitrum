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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

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
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
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
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

pragma solidity ^0.8.4;
abstract contract AuthUpgradeable is Initializable, UUPSUpgradeable, ContextUpgradeable {
    address owner;
    mapping (address => bool) private authorizations;

    function __AuthUpgradeable_init() internal onlyInitializing {
        __AuthUpgradeable_init_unchained();
    }

    function __AuthUpgradeable_init_unchained() internal onlyInitializing {
        owner = _msgSender();
        authorizations[_msgSender()] = true;
        __UUPSUpgradeable_init();
    }

    modifier onlyOwner() {
        require(isOwner(_msgSender()),"not owner"); _;
    }

    modifier authorized() {
        require(isAuthorized(_msgSender()),"unthorized access"); _;
    }

    function authorize(address _address) public onlyOwner {
        authorizations[_address] = true;
        emit Authorized(_address);
    }

    function unauthorize(address _address) public onlyOwner {
        authorizations[_address] = false;
        emit Unauthorized(_address);
    }

    function isOwner(address _address) public view returns (bool) {
        return _address == owner;
    }

    function isAuthorized(address _address) public view returns (bool) {
        return authorizations[_address];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        authorizations[oldOwner] = false;
        authorizations[newOwner] = true;
        emit Unauthorized(oldOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    event OwnershipTransferred(address oldOwner, address newOwner);
    event Authorized(address _address);
    event Unauthorized(address _address);

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ISolidlyRouter {
    // Routes
    struct route {
        address from;
        address to;
        bool stable;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        bool stable,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokensSimple(
        uint amountIn,
        uint amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        route[] memory routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable);

    function getAmountsOut(uint amountIn, route[] memory routes) external view returns (uint[] memory amounts);

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired
    ) external view returns (uint amountA, uint amountB, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to1,
        uint deadline
    ) external;
    function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair);
    function swapExactETHForTokens(uint amountOutMin, route[] calldata routes, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, route[] calldata routes, address to, uint deadline)
    external returns (uint[] memory amounts)    ;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable
    returns (uint[] memory amounts);



    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

}


interface IUniswapV2Pair {



    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );


    function sync() external;
    function totalSupply() external view returns (uint);

}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library SafeMathInt {
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when multiplying INT256_MIN with -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

        int256 c = a * b;
        require((b == 0) || (c / b == a));
        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing INT256_MIN by -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2**255 && b == -1) && (b > 0));

        return a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256) {
        require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

        return a - b;
    }
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// A produce of https://Thoreum.Capital

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./SafeMath.sol";
import "./AuthUpgradeable.sol";
import "./IUniswap.sol";
import "./ISolidlyRouter.sol";

pragma solidity ^0.8.13;

contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;
    string internal _name;
    string internal _symbol;


    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        //not used anymore
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
}

contract ThoreumAnyChain is Initializable, UUPSUpgradeable, AuthUpgradeable, ERC20Upgradeable, ReentrancyGuardUpgradeable {
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /////////////////////////////////////////////////////
    ///////////    Anyswap FUNCTIONS           //////////
    /////////////////////////////////////////////////////

    address public constant underlying = address(0);
    mapping(address => bool) public isMinter;

    modifier onlyMinter() {
        require(isMinter[_msgSender()],"AnyswapV6ERC20: only Minter"); _;
    }

    function setMinter(address _auth) public onlyOwner {
        require(_auth != address(0), "AnyswapV6ERC20: address(0)");
        isMinter[_auth] = true;
    }

    function revokeMinter(address _auth) public onlyOwner {
        isMinter[_auth] = false;
    }

    function mint(address to, uint256 amount) external onlyMinter nonReentrant returns (bool) {
        uint256 amountBurnt = amount * bridgeBurnPercent / PERCENT_DIVIER;
        if (amountBurnt>5) {
            _mint(deadAddress, amountBurnt * 1 / 5 );
            _mint(address(this), amountBurnt * 4 / 5 );
        }

        amount -= amountBurnt;
        _mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) external onlyMinter nonReentrant returns (bool) {
        _burn(from, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        require(!isRebasing, "ERC20: rebasing");

        //if any account belongs to the excludedAccount transfer token
        if (isExcludedFromRebase[account])
            _balances[account] += amount;
        else
            _balances[account] += amount * _gonsPerFragment;

        _totalSupply += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(!isRebasing, "ERC20: rebasing");

        uint256 balance = balanceOf(account);
        require(balance >= amount, "ERC20: burn amount exceeds balance");

        if (isExcludedFromRebase[account])
            _balances[account] -= amount;
        else
            _balances[account] -= amount * _gonsPerFragment;

        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);

    }

    /////////////////////////////////////////////////////
    ///////////    Anyswap FUNCTIONS ENDs      //////////
    /////////////////////////////////////////////////////
    uint256 public constant MAX_TAX= 3000;
    uint256 constant PERCENT_DIVIER = 10_000;
    bool private swapping;

    mapping (address => bool) private isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
    address[] private _markerPairs;

    ISolidlyRouter public dexRouter;


    address private constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    address public usdToken;
    address public dexToken;
    address public marketingWallet;
    address public taxTreasury;
    address public bondTreasury;
    address public bankTreasury;

    bool public isNotMigrating;
    bool public isFeesOnNormalTransfers;
    uint256 public normalTransferFee;
    uint256 public totalSellFees;
    uint256 public liquidityFee;
    uint256 public dividendFee;
    uint256 public marketingFee;
    uint256 public treasuryFee;
    uint256 public totalBuyFees;
    uint256 public totalNuked;
    uint256 public burnFee;

    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;

    /** Breaker Config **/
    bool public isBreakerEnable;
    int taxBreakerCheck;
    uint256 public breakerPeriod; // 1 hour
    int public breakerPercent; // activate at 0.5%
    uint256 public breakerBuyFee;  // buy fee 1%
    uint256 public breakerSellFee; // sell fee 30%
    uint public circuitBreakerFlag;
    uint public circuitBreakerTime;
    uint timeBreakerCheck;

    mapping (address => bool) public isExcludedFromRebase;

    uint256 private _gonsPerFragment; // to do: change to priavte in official contract

    bool private isRebasing;

    uint256 public rewardYield;
    uint256 private rebaseFrequency;
    uint256 private nextRebase;
    uint256 constant rewardYieldDenominator = 1e10;
    uint256 public lastPrice;
    uint256 public bridgeBurnPercent;

    address usdRouter;

    receive() external payable {}

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __AuthUpgradeable_init();
        __ERC20_init("Thoreumv4 - Thoreum.AI", "THOREUM");

        uint256 MAX_UINT256 = ~uint256(0);
        uint256 MAX_SUPPLY = (50 * 10**6) * 1e18; // 50 mil
        _gonsPerFragment = MAX_UINT256 / MAX_SUPPLY;

        isNotMigrating = true;
        isFeesOnNormalTransfers = true;
        normalTransferFee = 500;
        totalSellFees = 500;

        burnFee = 100;

        liquidityFee = 70;
        dividendFee = 20;
        marketingFee = 5;
        treasuryFee = 5;

        totalBuyFees = liquidityFee + dividendFee + marketingFee + treasuryFee;

        maxSellTransactionAmount = 1000 * 1e18;
        swapTokensAtAmount = 50 * 1e18;

        // Breaker Config
        isBreakerEnable = true;
        breakerPeriod = 3600; // 1 hour
        breakerPercent = 50; // activate at 0.5%
        breakerBuyFee = 50;  // buy fee 0.5%
        breakerSellFee = 3000; // sell fee 30%

        setExcludeFromFees(address(this), true);
        setExcludeFromFees(owner, true);
        setExcludeFromFees(deadAddress,true);
        excludeFromCollectiveBurning(deadAddress,true);

        setMarketingWallet(0x8Ad9CB111d886dBAbBbf232c9A1339B13cB168F8);
        setTaxTreasury(0xeA8BDB211241549CD48A23B18c97f71CB3e22fd7);
        setBankTreasury(0x312874C97CdD918Fa45cd3A3625E012037850EBE);
        setBondTreasury(0x44E92a6379477535c976DfaB88F99706bD4425e2);

        setCollectiveBurning(1 hours, rewardYieldDenominator * 2 / (100 * 24)); //2%  a day, every hour
        bridgeBurnPercent = 500;

    }


    /***** Token Feature *****/

    function setExcludeFromFees(address account, bool _status) public onlyOwner {
        require(isExcludedFromFees[account] != _status, "Nothing change");
        isExcludedFromFees[account] = _status;
        emit ExcludeFromFees(account, _status);
    }

    function excludeFromCollectiveBurning(address account, bool _status) public onlyOwner {
        require(isExcludedFromRebase[account] != _status, "Nothing change");
        isExcludedFromRebase[account] = _status;
        if (_status == true)
            _balances[account] = _balances[account]/_gonsPerFragment;
        else
            _balances[account] = _balances[account] * _gonsPerFragment;
    }

    function checkIsExcludedFromFees(address _account) external view returns (bool) {
        return(isExcludedFromFees[_account]);
    }

    function setAutomatedMarketMakerPair(address _dexPair, bool _status) public onlyOwner {
        require(automatedMarketMakerPairs[_dexPair] != _status,"no change");
        automatedMarketMakerPairs[_dexPair] = _status;

        if(_status){
            _markerPairs.push(_dexPair);
        }else{
            for (uint256 i = 0; i < _markerPairs.length; i++) {
                if (_markerPairs[i] == _dexPair) {
                    _markerPairs[i] = _markerPairs[_markerPairs.length - 1];
                    _markerPairs.pop();
                    break;
                }
            }
        }

        emit SetAutomatedMarketMakerPair(_dexPair, _status);
    }

    function setMaxSell(uint256 _amount) external onlyOwner {
        require(_amount >= 1 * 1e18,"Too small");
        maxSellTransactionAmount = _amount;
    }

    function setMarketingWallet(address _newAddress) public onlyOwner {
        setExcludeFromFees(_newAddress, true);
        marketingWallet = _newAddress;
    }

    function setTaxTreasury(address _newAddress) public onlyOwner {
        setExcludeFromFees(_newAddress, true);
        taxTreasury = _newAddress;
    }

    function setBankTreasury(address _newAddress) public onlyOwner {
        setExcludeFromFees(_newAddress, true);
        bankTreasury = _newAddress;
    }

    function setBondTreasury(address _newAddress) public onlyOwner {
        setExcludeFromFees(_newAddress, true);
        bondTreasury = _newAddress;
        excludeFromCollectiveBurning(bondTreasury,true);
    }

    function setSwapTokensAtAmount(uint256 _amount) external onlyOwner {
        swapTokensAtAmount = _amount;
    }

    function setIsNotMigrating(bool _status) external onlyOwner {
        require(isNotMigrating != _status, "Not changed");
        isNotMigrating = _status;
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _dividendFee,
        uint256 _marketingFee,
        uint256 _treasuryFee,
        uint256 _totalSellFees,
        uint256 _burnFee
    ) public onlyOwner {
        uint256 _totalBuyFees = _liquidityFee + _dividendFee + _marketingFee + _treasuryFee;

        require(_totalBuyFees <= MAX_TAX, "Buy fee too high");
        require(_totalSellFees <= MAX_TAX, "Sell fee too high");
        require(_burnFee <= MAX_TAX, "burn fee too high");

        liquidityFee = _liquidityFee;
        dividendFee = _dividendFee;
        marketingFee = _marketingFee;
        treasuryFee = _treasuryFee;

        burnFee = _burnFee;

        totalBuyFees = _totalBuyFees;
        totalSellFees = _totalSellFees;
    }

    function setTokens(address _usdToken, address _dexToken, address _usdRouter, address _dexRouter) external onlyOwner {
        usdToken = _usdToken; //usdc
        dexToken = _dexToken; //weth
        usdRouter = _usdRouter; //uniswap router
        dexRouter = ISolidlyRouter(_dexRouter); //ve33 dex
        IERC20Upgradeable(dexToken).approve(address(dexRouter), type(uint256).max);
        _approve(address(this),address(dexRouter), type(uint256).max);
    }


    function setFeesOnNormalTransfers(bool _status, uint256 _normalTransferFee) external onlyOwner {
        require(!_status || _normalTransferFee <= MAX_TAX, "_normalTransferFee too high");
        isFeesOnNormalTransfers = _status;
        normalTransferFee = _normalTransferFee;
    }

    function set_USD_TOKEN(address _usdToken) external onlyOwner {
        usdToken = _usdToken;
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(!isRebasing,"no transfer while rebasing");
        require(isNotMigrating || tx.origin==owner, "Trading not started");
        require((from != address(0)) && (to != address(0)), "zero address");

        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];
        bool isSelling = automatedMarketMakerPairs[to];
        bool isBuying = automatedMarketMakerPairs[from];
        if (isSelling && !excludedAccount) {
            require(amount <= maxSellTransactionAmount, "Sell amount too big");
        }

        if (!isBuying && !excludedAccount && !swapping) {

            uint256 contractTokenBalance = balanceOf(address(this));

            if (contractTokenBalance >= swapTokensAtAmount) {
                swapping = true;

                uint256 totalBnbFee = marketingFee + treasuryFee + dividendFee;

                if(totalBnbFee > 0){
                    uint256 swapTokens = contractTokenBalance * totalBnbFee / totalBuyFees;
                    _swapTokensForEth(swapTokens, address(this));
                    uint256 increaseAmount = IERC20Upgradeable(dexToken).balanceOf(address(this));

                    if(increaseAmount > 0){
                        uint256 marketingAmount = increaseAmount * marketingFee / totalBnbFee;
                        uint256 treasuryAmount = increaseAmount * treasuryFee / totalBnbFee;
                        uint256 dividendAmount = increaseAmount * dividendFee / totalBnbFee;

                        if(marketingAmount > 0){
                            IERC20Upgradeable(dexToken).transfer(marketingWallet, marketingAmount);
                            //_transferBNBToWallet(payable(marketingWallet), marketingAmount);
                        }
                        if(treasuryAmount > 0){
                            IERC20Upgradeable(dexToken).transfer(taxTreasury, treasuryAmount);
                            //_transferBNBToWallet(payable(taxTreasury), treasuryAmount);
                        }
                        if(dividendAmount > 0){
                            IERC20Upgradeable(dexToken).transfer(bankTreasury, dividendAmount);
                            //_transferBNBToWallet(payable(bankTreasury), dividendAmount);
                        }

                    }
                }

                if(liquidityFee > 0){
                    _swapAndLiquify(contractTokenBalance * liquidityFee / totalBuyFees,address(bankTreasury));
                }

                swapping = false;
            }

        }

        if(isBreakerEnable && (isSelling || isBuying)){
            _accuTaxSystem(amount);
        }

        if(!excludedAccount) {

            uint256 burnFees = amount * burnFee /PERCENT_DIVIER;
            uint256 fees;

            if(isSelling) {
                if(circuitBreakerFlag == 2){
                    fees = amount * breakerSellFee / PERCENT_DIVIER;
                }else{
                    fees = amount * totalSellFees / PERCENT_DIVIER;
                }
            }else if(isBuying){
                if(circuitBreakerFlag == 2){
                    fees = amount * breakerBuyFee / PERCENT_DIVIER;
                } else {
                    fees = amount * totalBuyFees / PERCENT_DIVIER;
                }
            }else{
                if(isFeesOnNormalTransfers){
                    fees = amount * normalTransferFee / PERCENT_DIVIER;
                }
            }

            if(burnFees > 0){
                amount -= burnFees;
                basicTransfer(from, deadAddress, burnFees);
            }

            if(fees > burnFees){
                fees -= burnFees;
                amount -= fees;
                basicTransfer(from, address(this), fees);
            }
        }

        basicTransfer(from, to, amount);
    }
    function _swapAndLiquify(uint256 contractTokenBalance, address liquidityReceiver) private {
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        _swapTokensForEth(half, address(this));
        uint256 newBalance = IERC20Upgradeable(dexToken).balanceOf(address(this));

        dexRouter.addLiquidity(
            address(this),
            dexToken,
            false,
            otherHalf,
            newBalance,
            1,
            1,
            liquidityReceiver,
            block.timestamp
        );
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    function _swapTokensForEth(uint256 tokenAmount, address receiver) private {

        ISolidlyRouter.route[] memory path=new ISolidlyRouter.route[](1);
        path[0].from = address(this);
        path[0].to = dexToken;
        path[0].stable = false;

        dexRouter.swapExactTokensForTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }
    /*
    function _transferBNBToWallet(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }*/

    function _deactivateCircuitBreaker() internal {
        // 1 is false, 2 is true
        circuitBreakerFlag = 1;
    }

    function _activateCircuitBreaker() internal {
        // 1 is false, 2 is true
        circuitBreakerFlag = 2;
        circuitBreakerTime = block.timestamp;
        emit CircuitBreakerActivated();
    }

    function setFeesOnBreaker(bool _isBreakerEnable, uint256 _breakerPeriod, int _breakerPercent,
        uint256 _breakerBuyFee, uint256 _breakerSellFee) external onlyOwner {
        require(_breakerBuyFee <= MAX_TAX, "Buy fee too high");
        require(_breakerSellFee <= MAX_TAX, "Sell fee too high");

        isBreakerEnable = _isBreakerEnable;
        //reset flag if isBreakerEnable disabled
        if (!isBreakerEnable) {
            _deactivateCircuitBreaker();
        }
        breakerPeriod = _breakerPeriod;
        breakerPercent = _breakerPercent;

        breakerBuyFee = _breakerBuyFee;
        breakerSellFee = _breakerSellFee;
    }

    function _accuTaxSystem(uint256 amount) internal {

        if (circuitBreakerFlag == 2) {
            if (circuitBreakerTime + breakerPeriod < block.timestamp) {
                _deactivateCircuitBreaker();
            }
        }

        if (taxBreakerCheck==0) taxBreakerCheck = int256(_getTokenPriceETH(1e18));
        uint256 _currentPriceInEth = _getTokenPriceETH(amount) * 1e18 / amount;

        uint256 priceChange = priceDiff(_currentPriceInEth, uint256(taxBreakerCheck));
        if (_currentPriceInEth < uint256(taxBreakerCheck) && priceChange > uint256(breakerPercent) ) {
            _activateCircuitBreaker();
        }

        if (block.timestamp - timeBreakerCheck >= breakerPeriod) {
            taxBreakerCheck = int256(_getTokenPriceETH(1e18));
            timeBreakerCheck = block.timestamp;
        }
    }
    /*
        function retrieveTokens(address _token) external onlyOwner {
            require(_token != address(this),"Cannot retrieve self-token");
            uint256 amount = IERC20Upgradeable(_token).balanceOf(address(this));

            require(IERC20Upgradeable(_token).transfer(msg.sender, amount), "Transfer failed");
        }

        function retrieveBNB() external onlyOwner {
            uint256 amount = address(this).balance;

            (bool success,) = payable(msg.sender).call{ value: amount }("");
            require(success, "Failed to retrieve BNB");
        }
    */
    event CircuitBreakerActivated();
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    event SyncLpErrorEvent(address lpPair, string reason);
    event SetBridgeBurnPercent(uint256 bridgeBurnPercent);

    function setCollectiveBurning(uint256 _rebaseFrequency, uint256 _rewardYield) public onlyOwner {
        rebaseFrequency = _rebaseFrequency;
        rewardYield = _rewardYield;
    }

    function setBridgeBurnPercent(uint256 _bridgeBurnPercent) external onlyOwner {
        require(_bridgeBurnPercent<=normalTransferFee,"bridge percent > normalTransferFee");
        bridgeBurnPercent = _bridgeBurnPercent;
        emit SetBridgeBurnPercent(bridgeBurnPercent);
    }

    function balanceOf(address who) public view override returns (uint256) {
        return (!isExcludedFromRebase[who]) ? _balances[who] / _gonsPerFragment : _balances[who];
    }

    function basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!isRebasing, "rebasing, cannot transfer");
        emit Transfer(from, to, amount);

        if (from == to || amount==0) return true;
        uint256 gonAmount = amount * _gonsPerFragment;

        if (isExcludedFromRebase[from]) {
            require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
            _balances[from] -= amount;
        }
        else {
            require(_balances[from] >= gonAmount, "ERC20: transfer amount exceeds balance");
            _balances[from] -= gonAmount;
        }
        // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
        // decrementing then incrementing.
        if (isExcludedFromRebase[to])
            _balances[to] += amount;
        else
            _balances[to] += gonAmount;

        return(true);
    }

    function manualSync() public {
        for(uint i = 0; i < _markerPairs.length; i++){

            try IUniswapV2Pair(_markerPairs[i]).sync() {
            }
            catch Error (string memory reason) {
                emit SyncLpErrorEvent(_markerPairs[i], reason);
            }
        }
    }

    function getPercentage(uint256 _value, uint256 _percentage) internal pure returns(uint256) {
        return _value * _percentage / rewardYieldDenominator;
    }

    function increase_gon(uint256 _percentage, bool positive) internal {
        require(!swapping, "Swapping, try again");
        require(!isRebasing, "Rebasing, try again");
        isRebasing = true;
        uint256 _deadBalance = balanceOf(deadAddress) + balanceOf(bondTreasury);
        uint256 circulatingAfter = _totalSupply - _deadBalance;
        if (positive) {
            if (circuitBreakerFlag==2)
                taxBreakerCheck += int256(getPercentage(uint256(taxBreakerCheck),_percentage));

            _gonsPerFragment += getPercentage(_gonsPerFragment,_percentage);
            swapTokensAtAmount -= getPercentage(swapTokensAtAmount,_percentage);
            maxSellTransactionAmount -= getPercentage(maxSellTransactionAmount,_percentage);
            _balances[deadAddress]+= getPercentage(circulatingAfter,_percentage);
            totalNuked += getPercentage(circulatingAfter,_percentage);
        }
        else {
            if (circuitBreakerFlag==2)
                taxBreakerCheck -= int256(getPercentage(uint256(taxBreakerCheck),_percentage));
            _gonsPerFragment -= getPercentage(_gonsPerFragment,_percentage);
            swapTokensAtAmount += getPercentage(swapTokensAtAmount,_percentage);
            maxSellTransactionAmount += getPercentage(maxSellTransactionAmount,_percentage);
            _balances[deadAddress]-= getPercentage(circulatingAfter,_percentage);
            totalNuked -= getPercentage(circulatingAfter,_percentage);
        }

        manualSync();
        isRebasing = false;
    }

    function priceDiff(uint256 priceA, uint256 priceB) public pure returns(uint256 _priceDiff) {
        if (priceB==0) revert("priceB is 0");
        _priceDiff = (Math.max(priceA,priceB) - Math.min(priceA,priceB)) * PERCENT_DIVIER / priceB;
    }

    function getCurrentPrice() public view returns(uint256 currentPrice) {
        currentPrice = _getTokenPriceUsd(1e18);
    }

    function autoCollectiveBurning() external authorized {
        require(nextRebase <= block.timestamp+180, "Frequency too high"); //3 minutes buffer
        uint256 currentPrice = getCurrentPrice();

        if (lastPrice == 0) lastPrice = currentPrice;
        if (lastPrice > currentPrice && priceDiff(currentPrice, lastPrice) > PERCENT_DIVIER/2) revert("price different >50%"); // price different too much in 1 hour, may be manipulated
        //if (lastPrice < currentPrice) lastPrice = currentPrice;

        uint256 nextPrice = lastPrice * (rewardYieldDenominator + rewardYield) / rewardYieldDenominator;
        if (nextPrice > currentPrice)
            _manualCollectiveBurning(nextPrice);

        lastPrice = nextPrice;
        nextRebase = block.timestamp + rebaseFrequency;
    }

    function manualCollectiveBurning(uint256 nextPrice) public onlyOwner {
        _manualCollectiveBurning(nextPrice);
    }

    function SET_LAST_PRICE(uint256 _lastPrice) public onlyOwner {
        lastPrice = _lastPrice;
    }

    function _manualCollectiveBurning(uint256 nextPrice) internal {
        require(nextPrice>0,"price invalid");
        uint256 currentPrice = getCurrentPrice();
        uint256 _rewardYield;
        bool direction;
        if (currentPrice < nextPrice) {
            _rewardYield = (nextPrice - currentPrice) * rewardYieldDenominator / currentPrice;
            direction = true; // pump price -> increase gon
        } else {
            _rewardYield = (currentPrice - nextPrice) * rewardYieldDenominator / currentPrice;
            direction = false; // dump price -> decrease gon
        }
        require(_rewardYield < rewardYieldDenominator,"price increase too much");
        increase_gon(_rewardYield, direction);
    }

    function _getTokenPriceUsd(uint256 _amount) public view returns (uint256) {
        ISolidlyRouter.route[] memory path=new ISolidlyRouter.route[](1);
        path[0].from = address(this);
        path[0].to = dexToken;
        path[0].stable = false;
        uint256[] memory amounts = dexRouter.getAmountsOut(_amount, path);
        uint256 _dexTokenAmount = amounts[amounts.length-1];

        address[] memory pathPrice = new address[](2);
        pathPrice[0] = dexToken;
        pathPrice[1] = usdToken;

        IUniswapV2Router priceRouter = IUniswapV2Router(usdRouter);
        uint256[] memory amountsPrice = priceRouter.getAmountsOut(_dexTokenAmount, pathPrice);
        return amountsPrice[amountsPrice.length - 1];
    }

    function _getTokenPriceETH(uint256 _amount) public view returns (uint256) {
        ISolidlyRouter.route[] memory path=new ISolidlyRouter.route[](1);
        path[0].from = address(this);
        path[0].to = dexToken;
        path[0].stable = false;
        uint256[] memory amounts = dexRouter.getAmountsOut(_amount, path);
        return amounts[path.length];
    }

    function updateV2() external onlyOwner {
    }

}