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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IMarket} from "../interfaces/IMarket.sol";
import {IConfigurableMarket} from "../interfaces/IConfigurableMarket.sol";
import {IMaker} from "../interfaces/IMaker.sol";
import {ITaker} from "../interfaces/ITaker.sol";
import {IPriceFeed} from "../interfaces/IPriceFeed.sol";
import {IRebalancer} from "../interfaces/IRebalancer.sol";

abstract contract BaseHelper {
    // returns current asset price scaled with 1e18
    function currentAssetPrice(address market) public view returns (uint256) {
        return _deps(market).priceFeedAssetToCapital.priceLatestValue();
    }

    // returns current BUMP price scaled with 1e18
    function currentBUMPPrice(address market) public view returns (uint256) {
        return _deps(market).priceFeedBUMPToUSD.priceLatestValue();
    }

    function getUpdatedState(
        address market
    ) public returns (IMarket.UpdatedState memory) {
        IMarket.UpdatedState memory state = IMarket(market).getUpdatedState(
            false
        );

        while (true) {
            IPriceFeed.Item memory feedLatest = _deps(market)
                .priceFeedAssetToCapital
                .priceLatest();

            if (feedLatest.priceId == state.lastVisitedPrice.priceId) {
                break;
            }

            state = _deps(market).rebalancer.getUpdatedState(
                IRebalancer.GetUpdatedStateInputParams({
                    storedState: state,
                    model: _deps(market).model,
                    priceFeedAssetToCapital: _deps(market)
                        .priceFeedAssetToCapital,
                    decimals: _decimals(market),
                    lastVisitedPriceId: state.lastVisitedPrice.priceId,
                    maxUpdatePriceIterations: 100,
                    inAction: false
                })
            );
        }

        return state;
    }

    function _deps(
        address market
    ) internal view returns (IConfigurableMarket.Dependencies memory) {
        return IConfigurableMarket(market).getDependencies();
    }

    function _decimals(
        address market
    ) internal view returns (IMarket.Decimals memory) {
        return IMarket(market).getDecimals();
    }

    function _taker(address market) internal view returns (ITaker) {
        return ITaker(payable(address(_deps(market).takerPositionNFT)));
    }

    function _maker(address market) internal view returns (IMaker) {
        return IMaker(payable(address(_deps(market).makerPositionNFT)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {PriceLib} from "../libraries/PriceLib.sol";
import {WeightedStateLib} from "../libraries/state/WeightedStateLib.sol";

import {IMarket} from "../interfaces/IMarket.sol";
import {IPositionManager} from "../interfaces/IPositionManager.sol";
import {ITaker} from "../interfaces/ITaker.sol";
import {IMaker} from "../interfaces/IMaker.sol";
import {IPriceFeed} from "../interfaces/IPriceFeed.sol";
import {IRebalancer} from "../interfaces/IRebalancer.sol";

import {Types} from "./Types.sol";
import {TakersHelper} from "./TakersHelper.sol";
import {MakersHelper} from "./MakersHelper.sol";

contract FrontendHelper is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    Types,
    TakersHelper,
    MakersHelper
{
    using PriceLib for uint256;
    using WeightedStateLib for IMarket.WeightedState;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    function getMarketTokenDetails(
        address market,
        address user
    )
        public
        view
        returns (
            TokenDetails memory assetToken,
            TokenDetails memory capitalToken
        )
    {
        IERC20Upgradeable asset = _deps(market).assetVault.underlying();
        IERC20Upgradeable capital = _deps(market).capitalVault.underlying();

        return (
            TokenDetails({
                addr: address(asset),
                name: IERC20MetadataUpgradeable(address(asset)).name(),
                symbol: IERC20MetadataUpgradeable(address(asset)).symbol(),
                decimals: IERC20MetadataUpgradeable(address(asset)).decimals(),
                userBalance: asset.balanceOf(user)
            }),
            TokenDetails({
                addr: address(capital),
                name: IERC20MetadataUpgradeable(address(capital)).name(),
                symbol: IERC20MetadataUpgradeable(address(capital)).symbol(),
                decimals: IERC20MetadataUpgradeable(address(capital))
                    .decimals(),
                userBalance: capital.balanceOf(user)
            })
        );
    }

    // returns TVL for given market in capital token, scaled with capital token decimals
    function marketTVL(address market) public returns (MarketTVL memory) {
        IMarket.UpdatedState memory state = getUpdatedState(market);

        uint256 protectTVL = (state.state.assetPool + state.state.assetReserve)
            .assetToCapital(
                state.lastVisitedPrice.price,
                IMarket(market).getDecimals()
            );
        uint256 earnTVL = state.state.capitalPool + state.state.capitalReserve;

        return
            MarketTVL({
                market: market,
                protectTVL: protectTVL,
                earnTVL: earnTVL
            });
    }

    // returns TVLs for given markets in capital token, scaled with capital token decimals
    function marketsTVL(
        address[] memory markets
    ) public returns (MarketTVL[] memory) {
        MarketTVL[] memory tvls = new MarketTVL[](markets.length);

        for (uint256 i = 0; i < markets.length; i++) {
            tvls[i] = marketTVL(markets[i]);
        }

        return tvls;
    }

    // returns user's protected assets scaled with asset token decimals
    function userProtectedAssets(
        address market,
        address user
    )
        public
        view
        returns (uint256 totalProtected, uint256 weightedAverageFloorPrice)
    {
        ITaker taker = _taker(market);

        uint256 total = 0;
        uint256 awFloorPrice = 0;
        for (uint256 i = 0; i < taker.balanceOf(user); i++) {
            uint256 tokenId = taker.tokenOfOwnerByIndex(user, i);

            IPositionManager.TakerPosition memory position = taker.getPosition(
                tokenId
            );
            total += position.assetAmount;
            awFloorPrice += position.assetAmount * position.floorPrice;
        }

        if (total == 0) {
            return (0, 0);
        }

        return (total, awFloorPrice / total);
    }

    // returns user's earning capital scaled with capital token decimals
    function userEarningCapital(
        address market,
        address user
    ) public view returns (uint256) {
        IMaker maker = _maker(market);

        uint256 total = 0;
        for (uint256 i = 0; i < maker.balanceOf(user); i++) {
            uint256 tokenId = maker.tokenOfOwnerByIndex(user, i);

            total += maker.getPosition(tokenId).capitalAmount;
        }

        return total;
    }

    function VERSION() public pure returns (string memory) {
        return "1.0.0";
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IMarket} from "../interfaces/IMarket.sol";
import {IModel} from "../interfaces/IModel.sol";
import {IPositionManager} from "../interfaces/IPositionManager.sol";
import {IMaker} from "../interfaces/IMaker.sol";

import {PriceLib} from "../libraries/PriceLib.sol";
import {WeightedStateLib} from "../libraries/state/WeightedStateLib.sol";

import {Types} from "./Types.sol";
import {BaseHelper} from "./BaseHelper.sol";
import {MakerPositionLib} from "../libraries/MakerPositionLib.sol";

abstract contract MakersHelper is Types, BaseHelper {
    using PriceLib for uint256;
    using WeightedStateLib for IMarket.WeightedState;
    using MakerPositionLib for IPositionManager.MakerPosition;

    // @return protocol fee for maker, scaled with capital token decimals
    function computeMakerFee(
        address market,
        uint256 amount,
        uint16 termDays
    ) public view returns (uint256) {
        return _deps(market).model.makerProtocolFee(amount, termDays);
    }

    function computeMakerRequiredBondAmount(
        address market,
        uint256 amount,
        uint16 termDays
    ) public view returns (uint256) {
        uint256 fee = computeMakerFee(market, amount, termDays);

        return
            _deps(market).model.computeMakerBondAmount(
                IModel.ComputeMakerBondAmountInputParams({
                    priceBumpToUsd: currentBUMPPrice(market),
                    makerCapitalDeposit: amount - fee,
                    decimals: _decimals(market)
                })
            );
    }

    function estimateMakerIncentiveAmount(
        address market,
        uint256 amount,
        uint16 termDays
    ) public returns (uint256) {
        IMarket.UpdatedState memory state = getUpdatedState(market);

        uint256 incentiveTvl = _deps(market).model.computeIncentiveTvlUsd(
            IModel.ComputeIncentiveTvlUsdInputParams({
                capitalPool: state.state.capitalPool,
                capitalReserve: state.state.capitalReserve
            })
        );

        return
            _deps(market).model.computeMakerIncentiveAmount(
                IModel.ComputeMakerIncentiveAmountInputParams({
                    makerCapitalDeposit: amount -
                        computeMakerFee(market, amount, termDays),
                    priceBumpToUsd: currentBUMPPrice(market),
                    incentiveTvl: incentiveTvl,
                    termDays: termDays,
                    decimals: _decimals(market)
                })
            );
    }

    function makerPositionCreationSummary(
        address market,
        uint256 amount,
        uint32 tier,
        uint16 termDays
    ) public returns (MakerPositionCreationSummary memory) {
        (uint256 positiveRate, uint256 negativeRate) = _deps(market)
            .riskRatingRegistry
            .getMakerRiskRating(tier, termDays);

        uint256 requiredBond = computeMakerRequiredBondAmount(
            market,
            amount,
            termDays
        );

        IMarket.Decimals memory decimals = _decimals(market);

        (, int256 yieldRate) = marketYield(market);

        return
            MakerPositionCreationSummary({
                depositValue: amount,
                protocolFee: computeMakerFee(market, amount, termDays),
                estimatedBUMPIncentive: estimateMakerIncentiveAmount(
                    market,
                    amount,
                    termDays
                ),
                userPositiveRiskRating: positiveRate,
                userNegativeRiskRating: negativeRate,
                requiredBond: requiredBond,
                requiredBondInCapital: requiredBond.assetToCapital(
                    currentBUMPPrice(market),
                    IMarket.Decimals({
                        asset: 18,
                        capital: decimals.capital,
                        price: decimals.price
                    })
                ),
                currentYieldRate: yieldRate
            });
    }

    function makerPositionRenewSummary(
        address market,
        uint256 positionId
    ) public returns (IPositionManager.MakerPosition memory, IPositionManager.MakerPosition memory, uint256) {
        IMarket.UpdatedState memory state = getUpdatedState(market);

        IPositionManager.MakerPosition memory oldPosition = _maker(market).getPosition(
            positionId
        );

        uint256 protocolFee;
        uint256 expiredFee;
        uint256 expiredPenalty;
        IPositionManager.MakerPosition memory newPosition;
        (, newPosition, protocolFee, expiredFee, expiredPenalty) = _deps(market).model.stateAfterMakerRenew(
            IModel.StateAfterMakerRenewInputParams({
                    currentState: state,
                    position: oldPosition,
                    makerPositiveClaimTokenTotalSupply: _deps(market)
                        .makerPositiveClaimERC20
                        .totalSupply(),
                    makerNegativeClaimTokenTotalSupply: _deps(market)
                        .makerNegativeClaimERC20
                        .totalSupply(),
                priceBumpToUsd: _deps(market).priceFeedBUMPToUSD.priceLatestValue(),
                atBlockTimestamp: block.timestamp,
                decimals: _decimals(market)
            })
        );

        return (oldPosition, newPosition, protocolFee + expiredFee + expiredPenalty);
    }


    function makerPositionCurrentValue(
        address market,
        uint256 positionId
    ) public returns (uint256, uint256) {
        IMarket.UpdatedState memory state = getUpdatedState(market);

        IPositionManager.MakerPosition memory pos = _maker(market).getPosition(
            positionId
        );

        uint256 makerCapital = _deps(market).model.computeMakerCapital(
            IModel.ComputeMakerCapitalInputParams({
                priceAssetToCapital: currentAssetPrice(market),
                capitalPool: state.state.capitalPool,
                capitalReserve: state.state.capitalReserve,
                assetReserve: state.state.assetReserve,
                book: state.state.book,
                debt: state.state.debt,
                assetWeightedFloorPrice: state
                    .weightedState
                    .averageFloorPrice(),
                computedBeta: state.beta,
                decimals: _decimals(market)
            })
        );

        uint256 capitalShare = _deps(market).model.computeMakerWithdrawalAmount(
            IModel.ComputeMakerWithdrawalAmountInputParams({
                makerCapitalDeposit: pos.capitalAmount,
                makerPositiveClaimAmount: pos.positiveClaimAmount,
                makerNegativeClaimAmount: pos.negativeClaimAmount,
                makerPositiveClaimTokenTotalSupply: _deps(market)
                    .makerPositiveClaimERC20
                    .totalSupply(),
                makerNegativeClaimTokenTotalSupply: _deps(market)
                    .makerNegativeClaimERC20
                    .totalSupply(),
                debt: state.state.debt,
                makerCapital: makerCapital
            })
        );

        uint256 expiredPenalty = _deps(market).model.makerExpiredPenalty(
            IModel.MakerExpiredPenaltyInputParams({
                position: pos,
                atBlockTimestamp: block.timestamp,
                makerPositiveClaimTokenTotalSupply: _deps(market)
                    .makerPositiveClaimERC20
                    .totalSupply(),
                makerNegativeClaimTokenTotalSupply: _deps(market)
                    .makerNegativeClaimERC20
                    .totalSupply(),
                debt: state.state.debt,
                makerCapital: makerCapital
            })
        );

        return (capitalShare, expiredPenalty);
    }

    function makerPositionDetails(
        address market,
        uint256 positionId
    ) public returns (MakerPositionDetails memory) {
        IPositionManager.MakerPosition memory position = _maker(market)
            .getPosition(positionId);

        (
            uint256 capitalShare,
            uint256 expiredPenalty
        ) = makerPositionCurrentValue(market, positionId);

        // if capitalShare > position.capitalAmount, it means the position is in profit -> accumulatedYield positive
        // if capitalShare < position.capitalAmount, it means the position is in loss -> accumulatedYield negative
        int256 accumulatedYield = int256(capitalShare) -
            int256(position.capitalAmount);

        int256 currentYieldRate = (((accumulatedYield * int256(1e18)) /
            int256(position.capitalAmount)) * int256(30 days)) /
            int256(position.activeFor(block.timestamp));

        uint256 expiredFee = _deps(market).model.makerExpiredFee(
            position.capitalAmount,
            position.expiredFor(block.timestamp)
        );

        return
            MakerPositionDetails({
                id: positionId,
                capitalMinusFee: position.capitalAmount,
                currentYield: currentYieldRate,
                accumulatedYield: accumulatedYield,
                expiredPenalty: expiredPenalty,
                estimatedNetPosition: capitalShare,
                bondAmount: position.bondAmount,
                incentivesAmount: position.incentiveAmount,
                termDays: position.term,
                startTimestamp: position.start,
                additionalProtocolFee: expiredFee
            });
    }

    function getAllMakerPositions(
        address market,
        address user
    ) public returns (MakerPositionDetails[] memory) {
        IMaker maker = _maker(market);

        uint256 balance = maker.balanceOf(user);

        MakerPositionDetails[] memory positions = new MakerPositionDetails[](
            balance
        );

        for (uint256 i = 0; i < balance; i++) {
            positions[i] = makerPositionDetails(
                market,
                maker.tokenOfOwnerByIndex(user, i)
            );
        }

        return positions;
    }

    /// yieldAbsoluteValue scaled with capital token decimals
    /// yieldRate scaled with 18 decimals
    function marketYield(
        address market
    ) public returns (int256 yieldAbsoluteValue, int256 yieldRate) {
        IMarket.UpdatedState memory state = getUpdatedState(market);

        if (state.state.debt == 0) {
            return (0, 0);
        }

        uint256 makerCapital = _deps(market).model.computeMakerCapital(
            IModel.ComputeMakerCapitalInputParams({
                priceAssetToCapital: currentAssetPrice(market),
                capitalPool: state.state.capitalPool,
                capitalReserve: state.state.capitalReserve,
                assetReserve: state.state.assetReserve,
                book: state.state.book,
                debt: state.state.debt,
                assetWeightedFloorPrice: state
                    .weightedState
                    .averageFloorPrice(),
                computedBeta: state.beta,
                decimals: _decimals(market)
            })
        );

        int256 yield = int256(makerCapital) - int256(state.state.debt);

        return (yield, (yield * 1e18) / int256(state.state.debt));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IPositionManager} from "../interfaces/IPositionManager.sol";
import {IMarket} from "../interfaces/IMarket.sol";
import {IModel} from "../interfaces/IModel.sol";
import {ITaker} from "../interfaces/ITaker.sol";

import {PriceLib} from "../libraries/PriceLib.sol";
import {WeightedStateLib} from "../libraries/state/WeightedStateLib.sol";
import {TakerPositionLib} from "../libraries/TakerPositionLib.sol";

import {Types} from "./Types.sol";
import {BaseHelper} from "./BaseHelper.sol";

abstract contract TakersHelper is Types, BaseHelper {
    using PriceLib for uint256;
    using WeightedStateLib for IMarket.WeightedState;
    using TakerPositionLib for IPositionManager.TakerPosition;

    // returns protocol fee, scaled with asset decimals
    function computeTakerFee(
        address market,
        uint256 amount,
        uint16 termDays
    ) public view returns (uint256) {
        return _deps(market).model.takerProtocolFee(amount, termDays);
    }

    // returns absolute amount of BUMP tokens required to bond scaled with 1e18
    function computeTakerRequiredBondAmount(
        address market,
        uint256 amount,
        uint16 termDays
    ) public view returns (uint256) {
        uint256 fee = _deps(market).model.takerProtocolFee(amount, termDays);

        return
            _deps(market).model.computeTakerBondAmount(
                (amount - fee).assetToCapital(
                    _deps(market).priceFeedAssetToCapital.priceLatestValue(),
                    _decimals(market)
                ),
                _deps(market).priceFeedBUMPToUSD.priceLatestValue(),
                _decimals(market)
            );
    }

    function estimateTakerIncentiveAmount(
        address market,
        uint256 amount,
        uint16 termDays
    ) public returns (uint256) {
        IMarket.UpdatedState memory state = getUpdatedState(market);

        uint256 liability = state.state.book.assetToCapital(
            state.weightedState.averageFloorPrice(),
            _decimals(market)
        );

        return
            _deps(market).model.computeTakerIncentiveAmount(
                IModel.ComputeTakerIncentiveAmountInputParams({
                    takerAssetDeposit: amount -
                        computeTakerFee(market, amount, termDays),
                    priceBumpToUsd: currentBUMPPrice(market),
                    latestPriceAssetToCapital: currentAssetPrice(market),
                    liability: liability,
                    termDays: termDays,
                    decimals: _decimals(market)
                })
            );
    }

    function takerPositionCreationSummary(
        address market,
        uint256 amount,
        uint32 tier,
        uint16 termDays
    ) public returns (TakerPositionCreationSummary memory) {
        uint256 assetPrice = currentAssetPrice(market);
        IMarket.Decimals memory decimals = _decimals(market);

        uint256 floorPrice = _deps(market).model.takerFloorPrice(
            assetPrice,
            tier
        );

        uint256 requiredBond = computeTakerRequiredBondAmount(
            market,
            amount,
            termDays
        );

        return
            TakerPositionCreationSummary({
                currentAssetPrice: assetPrice,
                depositValue: amount.assetToCapital(assetPrice, decimals),
                floorPrice: floorPrice,
                protectedValue: amount.assetToCapital(floorPrice, decimals),
                protocolFee: computeTakerFee(market, amount, termDays),
                estimatedBUMPIncentive: estimateTakerIncentiveAmount(
                    market,
                    amount,
                    termDays
                ),
                protocolRiskAverage: protocolTakerRiskAverage(market),
                userRiskRating: _deps(market)
                    .riskRatingRegistry
                    .getTakerRiskRating(tier, termDays),
                requiredBond: requiredBond,
                requiredBondInCapital: requiredBond.assetToCapital(
                    currentBUMPPrice(market),
                    IMarket.Decimals({
                        asset: 18,
                        capital: decimals.capital,
                        price: decimals.price
                    })
                )
            });
    }

    // returns average risk scaled with 1e8
    function protocolTakerRiskAverage(address market) public returns (uint256) {
        IMarket.UpdatedState memory state = getUpdatedState(market);

        return state.weightedState.wAvgTakerRisk;
    }

    function protocolAverageFloor(address market) public returns (uint256) {
        IMarket.UpdatedState memory state = getUpdatedState(market);

        return state.weightedState.averageFloorPrice();
    }

    function takerPositionAccumulatedPremium(
        address market,
        uint256 positionId
    ) public returns (uint256) {
        IMarket.UpdatedState memory state = getUpdatedState(market);

        IPositionManager.TakerPosition memory position = _taker(market)
            .getPosition(positionId);

        uint256 totalPremium = _deps(market).model.takerAssetPremium(
            position,
            state.weightedState,
            _decimals(market)
        );

        uint256 expiredPenalty = _deps(market).model.takerExpiredPenalty(
            position,
            totalPremium,
            block.timestamp
        );

        uint256 expiredProtocolFee = _deps(market).model.takerProtocolFee(
            position.assetAmount,
            uint16(position.expiredFor(block.timestamp) / 1 days)
        );

        return totalPremium + expiredPenalty + expiredProtocolFee;
    }

    function takerPositionDetails(
        address market,
        uint256 positionId
    ) public returns (TakerPositionDetails memory) {
        IMarket.UpdatedState memory state = getUpdatedState(market);

        IPositionManager.TakerPosition memory position = _taker(market)
            .getPosition(positionId);

        TakerPositionDetails memory details;
        details.id = positionId;
        details.amountMinusFee = position.assetAmount;
        details.floorPrice = position.floorPrice;
        details.bondAmount = position.bondAmount;
        details.incentivesAmount = position.incentiveAmount;
        details.termDays = position.term;
        details.startTimestamp = position.start;

        details.currentPrice = state.lastVisitedPrice.price;

        details.totalCurrentValue = position.assetAmount.assetToCapital(
            state.lastVisitedPrice.price,
            _decimals(market)
        );
        details.totalProtectedValue = position.assetAmount.assetToCapital(
            position.floorPrice,
            _decimals(market)
        );

        uint256 totalPremium = _deps(market).model.takerAssetPremium(
            position,
            state.weightedState,
            _decimals(market)
        );

        uint256 expiredPenalty = _deps(market).model.takerExpiredPenalty(
            position,
            totalPremium,
            block.timestamp
        );

        uint256 activeFor = position.activeFor(block.timestamp);

        details.premiumRatePerMonth =
            (((totalPremium * 1e18) / position.assetAmount) * 30 days) /
            activeFor;

        details.expiredPenaltyRatePerMonth =
            (((expiredPenalty * 1e18) / position.assetAmount) * 30 days) /
            activeFor;

        details.accumulatedPremiumAsset = totalPremium + expiredPenalty;
        details.accumulatedPremiumCapital = details
            .accumulatedPremiumAsset
            .assetToCapital(state.lastVisitedPrice.price, _decimals(market));

        details.additionalProtocolFee = _deps(market).model.takerProtocolFee(
            position.assetAmount,
            uint16(position.expiredFor(block.timestamp) / 1 days)
        );
        details.additionalProtocolFeeCapital = details
            .additionalProtocolFee
            .assetToCapital(state.lastVisitedPrice.price, _decimals(market));

        details.estimatedNetPositionAsset =
            position.assetAmount -
            details.accumulatedPremiumAsset -
            details.additionalProtocolFee;

        details.estimatedNetPositionCapital = details
            .estimatedNetPositionAsset
            .assetToCapital(state.lastVisitedPrice.price, _decimals(market));

        return details;
    }

    function getAllTakerPositions(
        address market,
        address user
    ) public returns (TakerPositionDetails[] memory) {
        ITaker taker = _taker(market);

        uint256 balance = taker.balanceOf(user);

        TakerPositionDetails[] memory positions = new TakerPositionDetails[](
            balance
        );

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = taker.tokenOfOwnerByIndex(user, i);

            positions[i] = takerPositionDetails(market, tokenId);
        }

        return positions;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

abstract contract Types {
    struct MarketTVL {
        address market;
        uint256 protectTVL;
        uint256 earnTVL;
    }

    struct TakerPositionDetails {
        uint256 id;
        uint256 amountMinusFee;
        uint256 currentPrice;
        uint256 totalCurrentValue;
        uint256 totalProtectedValue;
        uint256 floorPrice;
        uint256 accumulatedPremiumAsset;
        uint256 accumulatedPremiumCapital;
        uint256 additionalProtocolFee;
        uint256 additionalProtocolFeeCapital;
        uint256 premiumRatePerMonth;
        uint256 expiredPenaltyRatePerMonth;
        uint256 estimatedNetPositionAsset;
        uint256 estimatedNetPositionCapital;
        uint256 bondAmount;
        uint256 incentivesAmount;
        uint16 termDays;
        uint32 startTimestamp;
    }

    struct MakerPositionDetails {
        uint256 id;
        uint256 capitalMinusFee;
        int256 currentYield;
        int256 accumulatedYield;
        uint256 expiredPenalty;
        uint256 estimatedNetPosition;
        uint256 bondAmount;
        uint256 incentivesAmount;
        uint16 termDays;
        uint32 startTimestamp;
        uint256 additionalProtocolFee;
    }

    struct TakerPositionCreationSummary {
        uint256 currentAssetPrice;
        uint256 depositValue;
        uint256 floorPrice;
        uint256 protectedValue;
        uint256 protocolFee;
        uint256 estimatedBUMPIncentive;
        uint256 protocolRiskAverage;
        uint256 userRiskRating;
        uint256 requiredBond;
        uint256 requiredBondInCapital;
    }

    struct MakerPositionCreationSummary {
        uint256 depositValue;
        uint256 protocolFee;
        uint256 estimatedBUMPIncentive;
        uint256 userPositiveRiskRating;
        uint256 userNegativeRiskRating;
        uint256 requiredBond;
        uint256 requiredBondInCapital;
        int256 currentYieldRate;
    }

    struct TokenDetails {
        address addr;
        string name;
        string symbol;
        uint8 decimals;
        uint256 userBalance;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {IPermit} from "./IPermit.sol";

interface IBondController {
    error InvalidAmount();
    error InsufficientBondBalance();
    error InsufficientIncentiveBalance();

    function initialize(address aclManager_, address bondToken_) external;

    function bondToken() external view returns (IERC20Upgradeable);

    /// @notice Deposits tokens to the contract using permit
    /// @param amount - amount of tokens to deposit
    /// @param permit - ERC20 permit (can be null)
    function deposit(uint256 amount, IPermit.Permit memory permit) external;

    /// @notice allows a user to withdraw their unlocked tokens
    /// @param amount - amount of tokens to withdraw
    /// @dev this function will revert if the user tries to withdraw more than their unlocked balance
    function withdraw(uint256 amount) external;

    /// @notice allows a BONDING_MANAGER_ROLE to automatically deposit tokens from a user's wallet to this contract
    /// @dev this is intended to be used with automatic bump deposits during protect/deposit
    /// @dev allows using permit for BUMP
    function depositFromWithPermit(
        address from,
        uint256 amount,
        IPermit.Permit memory permit
    ) external;

    /// @notice allows a BONDING_MANAGER_ROLE to lock tokens from a user's balance
    /// @param user - address of user
    /// @param amount - amount of tokens to lock
    /// @param incentiveAmount - amount of tokens to lock for the user from the incentives pool
    /// @dev this function can only be called by an address with the BONDING_MANAGER_ROLE role
    function lockTokensFrom(
        address user,
        uint256 amount,
        uint256 incentiveAmount
    ) external;

    /// @notice allows a BONDING_MANAGER_ROLE to unlock tokens from a user's balance
    /// @param user - address of user
    /// @param amount - amount of tokens to unlock
    /// @dev this function can only be called by an address with the BONDING_MANAGER_ROLE role
    function unlockTokensTo(address user, uint256 amount) external;

    /// @notice allows a BONDING_MANAGER_ROLE to unlock incentives from locked pool and add back to incentives pool
    /// @param amount - amount of tokens to unlock
    /// @dev this function can only be called by an address with the BONDING_MANAGER_ROLE role
    function unlockIncentives(uint256 amount) external;

    /// @notice allows a deposit of BUMP tokens to the incentives pool
    /// @param amount - amount of tokens to deposit
    function depositIncentives(uint256 amount) external;

    /// @notice allows a BONDING_MANAGER_ROLE to withdraw tokens from the incentives pool
    /// @param to - address where to send tokens
    /// @param amount - amount of tokens to withdraw
    /// @dev this function can only be called by an address with the BONDING_MANAGER_ROLE role
    function withdrawIncentives(address to, uint256 amount) external;

    /// @notice Returns the total balance of a user: locked and unlocked tokens
    /// @param user - address of user
    /// @return balance of user
    function balanceOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IClaimToken is IERC20Upgradeable {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address owner_,
        address aclManager_
    ) external;

    function mint(address to_, uint256 amount_) external;

    function burnFrom(address from_, uint256 amount_) external;

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IModel} from "./IModel.sol";
import {IVault} from "./IVault.sol";
import {IPriceFeed} from "./IPriceFeed.sol";
import {IPositionToken} from "./IPositionToken.sol";
import {IClaimToken} from "./IClaimToken.sol";
import {IBondController} from "./IBondController.sol";
import {IRebalancer} from "./IRebalancer.sol";
import {IRiskRatingRegistry} from "./IRiskRatingRegistry.sol";
import {ISwapper} from "./ISwapper.sol";

interface IConfigurableMarket {
    struct ProtocolConfig {
        /**
         * address receiving fees from calling Market.withdrawFees()
         */
        address feesCollector;
        /**
         * @dev The maximum number of iterations the premium computation should run for
         * before reverting (in case the loop is inside a user tx) or before the loop is ended (in case the bot is calling).
         */
        uint8 maxUpdatePriceIterations;
        uint256 takerMinDepositAmount;
        uint256 makerMinDepositAmount;
    }

    struct Dependencies {
        IModel model;
        IVault assetVault;
        IVault capitalVault;
        IPriceFeed priceFeedAssetToCapital;
        IPriceFeed priceFeedBUMPToUSD;
        IPositionToken takerPositionNFT;
        IPositionToken makerPositionNFT;
        IClaimToken makerPositiveClaimERC20;
        IClaimToken makerNegativeClaimERC20;
        IBondController bondController;
        IRebalancer rebalancer;
        IRiskRatingRegistry riskRatingRegistry;
        ISwapper swapper;
    }

    function getProtocolConfig() external view returns (ProtocolConfig memory);

    function getDependencies() external view returns (Dependencies memory);

    function setProtocolConfig(ProtocolConfig memory protocolConfig_) external;

    function setDependencies(Dependencies memory dependencies_) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IPermit} from "./IPermit.sol";
import {IPositionManager} from "./IPositionManager.sol";

interface IMaker is IPositionManager {
    function initialize(
        string memory name_,
        string memory symbol_,
        address aclManager_,
        address market_
    ) external;

    /**
     * @dev called by makers to open a position by adding capital to the pool
     * @param for_ address to receive claim tokens and position
     * @param amount_ amount deposited
     * @param tier_ protection tier, not scaled (e.g 1, 2 ... )
     * @param termDays_ protection duration (days)
     * @return positionId
     */
    function depositFor(
        address for_,
        uint256 amount_,
        uint32 tier_,
        uint16 termDays_
    ) external returns (uint256);

    /**
     * @notice Same as depositFor but for_ = msg.sender
     */
    function deposit(
        uint256 amount_,
        uint32 tier_,
        uint16 termDays_
    ) external returns (uint256);

    /**
     * @notice Same as depositFor, but with automatic BUMP bonding
     *
     * @dev bumpAmount is assumed to be computed off-chain using the function from the Model
     * We avoid re-computing it here to keep things clean and gas-efficient, but if the amount is not sufficient
     * the transaction would revert when the actual lock is attempted
     */
    function depositForAutoBond(
        address for_,
        uint256 amount_,
        uint32 tier_,
        uint16 termDays_,
        uint256 bumpAmount_,
        IPermit.Permit memory bumpPermit_
    ) external returns (uint256);

    /**
     * @notice called by makers to close their open position
     *
     * @param positionId_ position to close
     * @param to_ address to receive claim tokens and position
     */
    function withdrawTo(uint256 positionId_, address to_) external;

    /**
     * @notice same as withdrawTo but to_ = msg.sender
     */
    function withdraw(uint256 positionId_) external;

    /**
     * @notice called by makers to renew their expired position
     *
     * @param positionId_ position to renew
     */
    function makerRenew(uint256 positionId_) external;

    /**
     * @notice called by anyone to liquidate a position
     *
     * @param positionId_ position to liquidate
     * @param to_ address to receive remaining bond and incentive associated with the position
     */
    function makerLiquidateTo(uint256 positionId_, address to_) external;

    /**
     * @notice Returns a maker position identified by its id
     * @dev Reverts if position does not exist
     */
    function getPosition(
        uint256 positionId_
    ) external view returns (MakerPosition memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IPriceFeed} from "./IPriceFeed.sol";
import {IModel} from "./IModel.sol";
import {ISwapper} from "./ISwapper.sol";
import {IVault} from "./IVault.sol";
import {IConfigurableMarket} from "./IConfigurableMarket.sol";

interface IMarket {
    struct Decimals {
        // asset token decimals (ETH = 18)
        uint8 asset;
        // capital token decimals (USDC = 6)
        uint8 capital;
        // price in format ASSET/CAPITAL (ETH/USDC = 18)
        uint8 price;
    }

    struct State {
        uint256 assetPool; // AP ETH
        uint256 assetReserve; // AR ETH
        uint256 capitalPool; // CP USDC
        uint256 capitalReserve; // CR USDC
        // total book at given time, excluding fees, asset token decimals, sum(asset deposit amout) // (s=B, p=Book_ETH)
        uint256 book;
        uint256 debt; // USDC
        uint256 yieldTarget; // USDC
        uint256 assetTreasury;
        uint256 capitalTreasury;
    }

    struct WeightedState {
        // weighted average taker risk
        uint256 wAvgTakerRisk;
        // sum(amount * maturity)
        // used in VRF computation, added to in protect(), removed from in close()
        uint256 awMaturities;
        // sum(amount * floor price)
        // used in VRF computation, added to in protect(), removed from in close()
        uint256 awFloorPrices;
        // total amount of assets deposited, asset token decimals, sum(asset deposit amount)
        // used in VRF computation, added to in protect(), removed from in close()
        // p=get_weighted_average_position_floor
        uint256 assetsDeposited;
        // positiveRwCapital (RWCp(t)) is a positive risk-weighted sum of maker deposits
        // sum(maker_deposit_amount * rate_positive * total_maker_deposits(t-1) / maker_capital(t-1))
        uint256 positiveRwCapital;
        // negativeRwCapital (RWCn(t)) is a negative risk-weighted sum of maker deposits
        // sum(maker_deposit_amount * rate_negative * total_maker_deposits(t-1) / maker_capital(t-1))
        uint256 negativeRwCapital;
        // cumulative premium index, in asset, asset token decimals
        uint256 takerPremiumCI;
        // total premium rate; used to divide deltaPremium into units to be distributed to individual takers
        uint256 totalPremiumRate;
    }

    struct RebalanceState {
        int256 deltaAssets;
        int256 deltaCapital;
    }

    struct UpdatedState {
        IMarket.State state;
        IMarket.WeightedState weightedState;
        IMarket.RebalanceState rebalanceState;
        IPriceFeed.Item prevVisitedPrice;
        IPriceFeed.Item lastVisitedPrice;
        uint256 beta;
    }

    struct UpdatedStateLoopVars {
        IPriceFeed.Item nextPrice;
        uint256 premiumDeltaPerRun;
        uint256 premiumDelta;
        uint256 beta;
        uint8 iteration;
        bool canContinue;
    }

    // ERRORS
    error Paused();
    error NotPositionManager();
    error NotReady();

    event StateUpdate(
        uint256 premiumDelta,
        uint256 yieldTargetDelta,
        uint256 bookBefore
    );

    event Swapped(
        int256 deltaAssets,
        int256 deltaCapital,
        int256 realDeltaAssets,
        int256 realDeltaCapital
    );

    event FailedSwap(uint256 amountIn, uint256 minAmountOut, bool sellAssets);

    function initialize(
        IConfigurableMarket.Dependencies memory deps_,
        IConfigurableMarket.ProtocolConfig memory protocolConfig_,
        IMarket.Decimals memory decimals_,
        address aclManagerAddress_
    ) external;

    function updateState() external;

    function getUpdatedState(
        bool inAction_
    ) external returns (IMarket.UpdatedState memory newState_);

    function rebalanceAndSwap(
        IMarket.UpdatedState memory state_,
        int256 diffAsset_,
        int256 diffCapital_,
        bool doRecomputeBeta_
    ) external;
    function getDecimals() external view returns (IMarket.Decimals memory);

    function getStoredState()
        external
        view
        returns (
            IMarket.State memory state_,
            IMarket.WeightedState memory weightedState_,
            IMarket.RebalanceState memory rebalanceState_,
            uint80 lastVisitedPriceId_
        );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IMarket} from "./IMarket.sol";
import {IPriceFeed} from "./IPriceFeed.sol";
import {IRiskRatingRegistry} from "./IRiskRatingRegistry.sol";
import {IPositionManager} from "./IPositionManager.sol";

interface IModel {
    // used in Premium.sol
    struct ComputeYieldTargetInputParams {
        IPriceFeed.Item prevPriceItem;
        IPriceFeed.Item priceItem;
        uint256 debt; // IMarket.State.debt
    }

    // used in Premium.sol
    struct ComputeBetaInputParams {
        uint256 Prf; // computed in Premium.sol
        uint256 Vrf; // computed in Premium.sol
    }

    // used in Premium.sol
    struct ComputePremiumInputParams {
        IPriceFeed.Item prevPriceItem;
        IPriceFeed.Item priceItem;
        uint256 awAvgFloorPrice; // IMarket.WeighedState.awFloorPrice
        uint256 awAvgMaturity; // IMarket.WeighedState.awAverageMaturity
        uint256 assetPool; // IMarket.State.assetPool
        uint256 assetReserve; // IMarket.State.assetReserve
        uint256 capitalPool; // IMarket.State.capitalPool
        uint256 capitalReserve; // IMarket.State.capitalReserve
        uint256 liability; // IMarket.State.liability
        uint256 book; // IMarket.State.book
        uint256 debt; // IMarket.State.debt
        uint256 yieldTarget; // IMarket.State.yieldTarget
    }

    // used in Premium.sol
    struct ComputeVrfInputParams {
        IPriceFeed.Item priceItem;
        uint256 awAvgFloorPrice; // IMarket.WeighedState.awAvgFloorPrice
        uint256 awAvgMaturity; // IMarket.WeighedState.awAvgMaturity
    }

    // used in Premium.sol
    struct ComputePrfVrfBetaInputParams {
        IPriceFeed.Item prevPriceItem;
        IPriceFeed.Item priceItem;
        uint256 awAvgFloorPrice; // IMarket.WeighedState.awAvgFloorPrice
        uint256 awAvgMaturity; // IMarket.WeighedState.awAvgMaturity
    }

    // used in Premium.sol
    struct ComputeVectorLrfInputParams {
        uint256 wMax;
        uint256 wMin;
        uint256 lScale;
        uint256 alpha;
        uint256 lShiftR;
    }

    // used in Premium.sol
    struct ComputeLrfInputParams {
        uint256 assetPool; // IMarket.State.assetPool
        uint256 assetReserve; // IMarket.State.assetReserve
        uint256 capitalPool; // IMarket.State.capitalPool
        uint256 capitalReserve; // IMarket.State.capitalReserve
        uint256 book; // IMarket.State.book
        uint256 liability; // IMarket.State.liability
        uint256 debt; // IMarket.State.debt
        uint256 yieldTarget; // IMarket.State.yieldTarget
    }

    struct ComputeLR3InputParams {
        uint256 assetPool;
        uint256 assetReserve;
        uint256 book;
        int256 diffAsset;
    }

    struct ComputeLR13InputParams {
        uint256 capitalPool;
        uint256 capitalReserve;
        uint256 beta;
        uint256 liabilities;
        uint256 debt;
        uint256 yieldTarget;
        int256 diffCapital;
    }

    struct ComputeAssetLedgerInputParams {
        uint256 assetPool;
        uint256 assetReserve;
        uint256 book;
        int256 diffAsset;
    }

    struct ComputeCapitalLedgerInputParams {
        uint256 capitalPool;
        uint256 capitalReserve;
        int256 diffCapital;
    }

    struct ComputeCrossSideSwapAmountsInputParams {
        uint256 assetPool;
        uint256 assetReserve;
        uint256 capitalPool;
        uint256 capitalReserve;
        uint256 book;
        uint256 liabilities;
        uint256 debt;
        uint256 yieldTarget;
        uint256 beta;
        int256 diffAsset;
        int256 diffCapital;
        uint256 priceAssetToCapital;
    }

    struct ComputeExpectedCapitalInputParams {
        uint256 priceAssetToCapital;
        uint256 capitalPool; // IMarket.State.capitalPool
        uint256 assetReserve; // IMarket.State.assetReserve
        uint256 book; // IMarket.State.book
        uint256 computedBeta;
        IMarket.Decimals decimals;
    }

    struct ComputeExpectedLiabilitiesInputParams {
        uint256 book; // IMarket.State.book
        uint256 assetWeightedFloorPrice; // IMarket.WeightedState
        uint256 computedBeta;
        IMarket.Decimals decimals;
    }

    struct ComputeExpectedDebtInputParams {
        uint256 debt; // IMarket.State.debt
    }

    struct ComputeMakerCapitalInputParams {
        uint256 priceAssetToCapital;
        uint256 capitalPool; // IMarket.State.capitalPool
        uint256 capitalReserve; // IMarket.State.capitalReserve
        uint256 assetReserve; // IMarket.State.assetReserve
        uint256 book; // IMarket.State.book
        uint256 debt; // IMarket.State.debt
        uint256 assetWeightedFloorPrice; // IMarket.WeightedState
        uint256 computedBeta;
        IMarket.Decimals decimals;
    }

    struct ComputeMakerBondAmountInputParams {
        uint256 priceBumpToUsd;
        uint256 makerCapitalDeposit; // maker capital deposit minus fees
        IMarket.Decimals decimals;
    }

    struct ComputeMakerClaimAmountsInputParams {
        uint256 makerCapitalDeposit; // maker capital deposit minus fees
        uint256 makerPositiveRisk; // maker position risk, positive
        uint256 makerNegativeRisk; // maker position risk, negative
        uint256 makerCapital; // IModel.computeMakerCapital()
        uint256 positiveRwCapital; // IMaker.WeightedState.positiveRwCapital
        uint256 negativeRwCapital; // IMaker.WeightedState.negativeRwCapital
        uint256 makerPositiveClaimTokenTotalSupply; // IMaker.makerPositiveClaimERC20.totalSupply()
        uint256 makerNegativeClaimTokenTotalSupply; // IMaker.makerNegativeClaimERC20.totalSupply()
        uint256 debt; // IMarket.State.debt
    }

    struct ComputeIncentiveTvlUsdInputParams {
        uint256 capitalPool; // IMarket.State.capitalPool
        uint256 capitalReserve; // IMarket.State.capitalReserve
    }

    struct ComputeTakerIncentiveAmountInputParams {
        uint256 takerAssetDeposit;
        uint256 priceBumpToUsd;
        uint256 latestPriceAssetToCapital;
        uint256 liability;
        uint16 termDays;
        IMarket.Decimals decimals;
    }

    struct ComputeMakerIncentiveAmountInputParams {
        uint256 makerCapitalDeposit;
        uint256 priceBumpToUsd;
        uint256 incentiveTvl;
        uint16 termDays;
        IMarket.Decimals decimals;
    }

    struct ComputeMakerWithdrawalAmountInputParams {
        uint256 makerCapitalDeposit; // maker capital deposit minus fees
        uint256 makerPositiveClaimAmount; // maker claim token amount
        uint256 makerNegativeClaimAmount; // maker claim token amount
        uint256 makerPositiveClaimTokenTotalSupply; // IMaker.makerPositiveClaimERC20.totalSupply()
        uint256 makerNegativeClaimTokenTotalSupply; // IMaker.makerNegativeClaimERC20.totalSupply()
        uint256 debt; // IMarket.State.debt
        uint256 makerCapital; // IModel.computeMakerCapital()
    }

    struct MakerExpiredPenaltyInputParams {
        IPositionManager.MakerPosition position;
        uint256 atBlockTimestamp;
        uint256 makerPositiveClaimTokenTotalSupply; // IMaker.makerPositiveClaimERC20.totalSupply()
        uint256 makerNegativeClaimTokenTotalSupply; // IMaker.makerNegativeClaimERC20.totalSupply()
        uint256 debt; // IMarket.State.debt
        uint256 makerCapital; // IModel.computeMakerCapital()
    }

    struct StateAfterMakerEnterInputParams {
        IMarket.UpdatedState currentState;
        uint256 makerCapitalDeposit;
        uint256 priceBumpToUsd;
        uint256 claimTokenPositiveTotalSupply;
        uint256 claimTokenNegativeTotalSupply;
        uint32 positionStart;
        uint32 tier;
        uint16 termDays;
        IMarket.Decimals decimals;
        IRiskRatingRegistry riskRatingRegistry;
    }

    struct StateAfterMakerEnterVars {
        uint256 fee;
        uint256 positiveRisk;
        uint256 negativeRisk;
        uint256 makerCapital;
        uint256 negativeClaimAmount;
        uint256 positiveClaimAmount;
        uint256 positiveRiskWeightedCapital;
        uint256 negativeRiskWeightedCapital;
        uint128 bondAmountNeeded;
        uint128 incentiveAmount;
    }

    struct StateAfterMakerWithdrawInputParams {
        IMarket.UpdatedState currentState;
        IPositionManager.MakerPosition position;
        uint256 makerPositiveClaimTokenTotalSupply;
        uint256 makerNegativeClaimTokenTotalSupply;
        uint256 atBlockTimestamp;
        IMarket.Decimals decimals;
    }

    struct StateAfterMakerRenewInputParams {
        IMarket.UpdatedState currentState;
        IPositionManager.MakerPosition position;
        uint256 makerPositiveClaimTokenTotalSupply;
        uint256 makerNegativeClaimTokenTotalSupply;
        uint256 priceBumpToUsd;
        uint256 atBlockTimestamp;
        IMarket.Decimals decimals;
    }

    struct StateAfterMakerRenewVars {
        uint256 expiredFee;
        uint256 makerCapital;
        uint256 expiredPenalty;
        uint256 protocolFee;
    }

    struct StateAfterTakerEnterInputParams {
        IMarket.UpdatedState currentState;
        uint256 assetAmount;
        uint32 tier;
        uint16 term;
        uint256 priceBumpToUsd;
        IMarket.Decimals decimals;
        uint32 currentTimestamp;
        IRiskRatingRegistry riskRatingRegistry;
    }

    struct StateAfterTakerCloseInputParams {
        IMarket.UpdatedState currentState;
        IPositionManager.TakerPosition position;
        uint32 currentTimestamp;
        IMarket.Decimals decimals;
    }

    struct StateAfterTakerRenewInputParams {
        IMarket.UpdatedState currentState;
        IPositionManager.TakerPosition oldPosition;
        uint32 currentTimestamp;
        uint32 newTier;
        uint16 newTerm;
        IMarket.Decimals decimals;
        IRiskRatingRegistry riskRatingRegistry;
        uint256 priceBumpToUsd;
    }

    struct TakerPremiumRateInputParams {
        uint256 depositAmount;
        uint256 riskRating;
        uint256 book;
        uint256 weightedAvgRiskRating;
        uint256 totalPremiumRate;
    }

    function globalYieldTargetDelta(
        ComputeYieldTargetInputParams memory stateInput_
    ) external pure returns (uint256 yieldTarget_);

    function globalPremiumDelta(
        ComputePremiumInputParams memory stateInput_
    ) external view returns (uint256 premiumDelta_, uint256 beta_);

    /**
     * @dev computes "Virtual Probability of Claim" (BETA) for a price tick. per spec: 0 <= BETA(t) <= 1
     * @param stateInput_ PRF and VRF computed for a price tick, multiplied by PrecisionLib.PERCENTAGE_PRECISION
     * @return BETA multiplied by PrecisionLib.PERCENTAGE_PRECISION
     */
    function computeBETA(
        IModel.ComputeBetaInputParams memory stateInput_
    ) external pure returns (uint256);

    function computePrfVrfBeta(
        IModel.ComputePrfVrfBetaInputParams memory stateInput_
    ) external view returns (uint256 prf_, uint256 vrf_, uint256 beta_);

    /**
     * @dev computes the premium share per total deposits and total premium rate and the actual (rounded) premium
     * @param premiumDelta the premium
     * @param totalPremiumRate the total premium rate from WeightedState
     * @return premiumPerShare_ the premium share per total premium rate (scaled with asset token decimals)
     * @return actualPremiumDelta_ the actual (rounded) premium (scaled with asset token decimals)
     */
    function premiumPerShareDelta(
        uint256 premiumDelta,
        uint256 totalPremiumRate,
        IMarket.Decimals memory decimals
    )
        external
        pure
        returns (uint256 premiumPerShare_, uint256 actualPremiumDelta_);

    /**
     * @dev computes maker capital
     * @param input_ see IModel.ComputeMakerCapitalInputParams
     * @return maker capital
     */
    function computeMakerCapital(
        IModel.ComputeMakerCapitalInputParams memory input_
    ) external pure returns (uint256);

    /**
     * @dev returns taker premium, proportional to what they withdraw and including expired penalty premium
     * @param position_ taker position
     * @param weightedState_ market weighted state
     * @return assetPremiumAmount_ total premium to be paid by taker, asset denominated; DOES NOT include expired penalty premium.
     * BEWARE: Total premium can exceed total position size!
     */
    function takerAssetPremium(
        IPositionManager.TakerPosition memory position_,
        IMarket.WeightedState memory weightedState_,
        IMarket.Decimals memory decimals_
    ) external view returns (uint256 assetPremiumAmount_);

    /**
     * @dev returns expired penalty to be paid by taker, asset denominated
     * @param position_ taker position
     * @param totalPremium total premium to be paid by taker, asset denominated
     * @param blockTimestamp_ current block timestamp
     * @return penalty expired penalty to be paid by taker, asset denominated
     */
    function takerExpiredPenalty(
        IPositionManager.TakerPosition memory position_,
        uint256 totalPremium,
        uint256 blockTimestamp_
    ) external view returns (uint256);

    /**
     * @dev returns maker expired penalty, capital denominated
     * @param p_ see IModel.MakerExpiredPenaltyInputParams
     * @return penalty maker expired penalty, capital denominated
     */
    function makerExpiredPenalty(
        IModel.MakerExpiredPenaltyInputParams memory p_
    ) external pure returns (uint256);

    function stateAfterTakerEnter(
        StateAfterTakerEnterInputParams memory input_
    )
        external
        view
        returns (
            IMarket.UpdatedState memory,
            IPositionManager.TakerPosition memory,
            uint256 protocolFee
        );

    function stateAfterTakerClose(
        StateAfterTakerCloseInputParams memory input_,
        bool liquidate_
    )
        external
        view
        returns (
            IMarket.UpdatedState memory,
            uint256 assetOut,
            uint256 expiredProtocolFeeAsset,
            bool mustLiquidate
        );

    function stateAfterTakerRenew(
        StateAfterTakerRenewInputParams memory input_
    )
        external
        view
        returns (
            IMarket.UpdatedState memory,
            IPositionManager.TakerPosition memory,
            uint256 totalProtocolFeeAsset
        );

    function stateAfterMakerEnter(
        StateAfterMakerEnterInputParams memory p_
    )
        external
        view
        returns (
            IMarket.UpdatedState memory,
            IPositionManager.MakerPosition memory
        );

    function stateAfterMakerWithdraw(
        IModel.StateAfterMakerWithdrawInputParams memory p_
    )
        external
        pure
        returns (
            IMarket.UpdatedState memory,
            uint256 capitalShare_,
            uint256 expiredFee_,
            uint256 expiredPenalty_
        );

    function stateAfterMakerRenew(
        IModel.StateAfterMakerRenewInputParams memory p_
    )
        external
        pure
        returns (
            IMarket.UpdatedState memory,
            IPositionManager.MakerPosition memory,
            uint256 protocolFee_,
            uint256 expiredFee_,
            uint256 expiredPenalty_
        );

    function takerProtocolFee(
        uint256 assetAmount_,
        uint16 term_
    ) external view returns (uint256);

    function makerProtocolFee(
        uint256 assetAmount_,
        uint16 termDays_
    ) external view returns (uint256);

    function makerExpiredFee(
        uint256 capitalAmount_,
        uint256 expiredForSeconds_
    ) external pure returns (uint256);

    /**
     * @dev compute floor price based on oracle price and risk. Expressed with the same amount of decimals as oraclePrice
     * @param oraclePrice_ price reported by the oracle
     * @param tier_ risk factor selected by taker
     * @return floorPrice_ computed, same decimals as {oraclePrice_}
     */
    function takerFloorPrice(
        uint256 oraclePrice_,
        uint32 tier_
    ) external view returns (uint256);

    /// @notice Compute the amount of BUMP tokens that must be locked by taker for the deposited amount
    /// @param depositValueUSD The value of the deposit in USD
    /// @param priceBumpUSD The price of BUMP token in USD
    /// @param decimals The decimals of the market
    function computeTakerBondAmount(
        uint256 depositValueUSD,
        uint256 priceBumpUSD,
        IMarket.Decimals memory decimals
    ) external view returns (uint128);

    /// @notice Compute the amount of BUMP tokens that are locked by the protocol as incentive with the taker psoition
    /// @param p_ params
    /// @return the amount of BUMP tokens that are locked by the protocol as incentive with the taker psoition
    function computeTakerIncentiveAmount(
        ComputeTakerIncentiveAmountInputParams memory p_
    ) external view returns (uint128);

    function computeCrossSideSwapAmounts(
        IModel.ComputeCrossSideSwapAmountsInputParams memory input_,
        IMarket.Decimals memory decimals_
    ) external view returns (int256, int256);

    function stateAfterSameSideRebalance(
        IMarket.UpdatedState memory state_,
        int256 diffAsset_,
        int256 diffCapital_,
        IMarket.Decimals memory decimals_
    ) external view returns (IMarket.UpdatedState memory);

    function computeMakerBondAmount(
        IModel.ComputeMakerBondAmountInputParams memory p_
    ) external pure returns (uint128);

    function computeIncentiveTvlUsd(
        ComputeIncentiveTvlUsdInputParams memory p_
    ) external pure returns (uint256);

    /// @notice Compute the amount of BUMP tokens that are locked by the protocol as incentive with the maker psoition
    /// @param p_ params
    /// @return the amount of BUMP tokens that are locked by the protocol as incentive with the maker psoition
    function computeMakerIncentiveAmount(
        ComputeMakerIncentiveAmountInputParams memory p_
    ) external pure returns (uint128);

    // in busd
    function computeMakerClaimAmounts(
        IModel.ComputeMakerClaimAmountsInputParams memory p_
    ) external pure returns (uint256 positive_, uint256 negative_);

    function computeMakerWithdrawalAmount(
        IModel.ComputeMakerWithdrawalAmountInputParams memory p_
    ) external pure returns (uint256);

    function computeExpectedCapital(
        IModel.ComputeExpectedCapitalInputParams memory p_
    ) external pure returns (uint256);

    function computeExpectedLiabilities(
        IModel.ComputeExpectedLiabilitiesInputParams memory p_
    ) external pure returns (uint256);

    function computeExpectedDebt(
        IModel.ComputeExpectedDebtInputParams memory p_
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

interface IPermit {
    struct Permit {
        bool usePermit;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IPositionManager is IERC721EnumerableUpgradeable {
    struct TakerPosition {
        // amount deposited by taker
        uint256 assetAmount;
        // position risk rating as returned by PositionRates.getTakerRiskRating
        uint256 riskRating;
        // floor price computed from risk tier and current price
        uint256 floorPrice;
        // premium rate; used to compute individual premium at time of exit
        uint256 premiumRate;
        // cumulative premium index at position open, in asset, asset token decimals
        uint256 takerPremiumCIAtStart;
        // amount of BUMP tokens locked(/bonded) for this position
        uint128 bondAmount;
        // amount of bump locked as incentive
        uint128 incentiveAmount;
        // timestamp when position was opened
        uint32 start;
        // duration of the position in days
        uint16 term;
    }

    struct MakerPosition {
        // amount deposited by maker minus initial protocol fee
        uint256 capitalAmount;
        // bUSD tokens positive risk
        uint256 positiveClaimAmount;
        // bUSD tokens negative risk
        uint256 negativeClaimAmount;
        // deposit_capital_amount * position_rate_positive * debt / maker_capital
        uint256 positiveRiskWeightedCapital;
        // deposit_capital_amount * position_rate_negative * debt / maker_capital
        uint256 negativeRiskWeightedCapital;
        // amount of BUMP tokens locked(/bonded) for this position
        uint128 bondAmount;
        // amount of bump locked as incentive
        uint128 incentiveAmount;
        // timestamp when position was opened
        uint32 start;
        // duration of the position in days
        uint16 term;
    }

    enum UserActionType {
        TakerProtect,
        TakerClose,
        TakerClaim,
        TakerRenew,
        TakerLiquidate,
        MakerDeposit,
        MakerWithdraw,
        MakerRenew,
        MakerLiquidate,
        TakerCancel
    }

    event UserAction(
        address indexed caller,
        address target,
        uint256 positionId,
        uint256 amount,
        uint256 fees,
        uint256 priceAssetToCapital,
        UserActionType actionType
    );

    event MakerPositionCreated(
        uint256 positionId,
        uint32 tier,
        uint16 termDays
    );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IPositionToken is IERC721Upgradeable {
    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IPriceOracle} from "./IPriceOracle.sol";

interface IPriceFeed is IPriceOracle {
    struct Item {
        uint80 priceId;
        uint256 price;
        uint256 updatedAt;
    }

    function decimals() external view returns (uint8);

    /// @notice Returns the price at the next round id after the given round id
    /// taking into account the aggregator proxy phase id.
    /// @param currentRoundId_ The current round id.
    /// @return price The price at the next round id.
    /// @return roundExists True if a price was found corresponding to the next roundId after the currentRoundId_
    function nextPrice(
        uint80 currentRoundId_
    ) external view returns (IPriceFeed.Item memory, bool);

    /// @notice Returns the price at the previous round id before the given round id
    /// taking into account the aggregator proxy phase id.
    /// @param currentRoundId_ The current round id.
    /// @return price The price at the previous round id.
    /// @return roundExists True if a price was found corresponding to the previous roundId before the currentRoundId_
    function prevPrice(
        uint80 currentRoundId_
    ) external view returns (IPriceFeed.Item memory, bool);

    /// @notice Return the price at the given round id
    /// @dev The price might be 0-value if the round id is not found
    /// @param priceId_ The round id
    /// @return The price at the given round id
    function priceAt(
        uint80 priceId_
    ) external view returns (IPriceFeed.Item memory);

    /// @notice Return the latest price based on the combination of the configured feeds at the latest round
    /// @dev The price is always returned in 18 decimals
    /// @return The latest price
    function priceLatest() external view returns (IPriceFeed.Item memory);

    /// @notice Returns true if between fromRoundId_ and toRoundId_ there are no more than iterations_ rounds
    /// @dev This function will always return false if the phase of the toRoundId_ is not the same (or the very next phase) as the phase of the fromRoundId_
    /// @param iterations_ The number of iterations
    /// @param fromRoundId_ The starting round id
    /// @param toRoundId_ The ending round id
    /// @return true if the number of rounds between fromRoundId_ and toRoundId_ is less than iterations_
    function canCatchUp(
        uint80 iterations_,
        uint80 fromRoundId_,
        uint80 toRoundId_
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IPriceFeed} from "./IPriceFeed.sol";

interface IPriceOracle {
    /// @notice Return the number of decimals for the returned price values
    /// @return The number of decimals
    function decimals() external view returns (uint8);

    /// @notice Return the latest price value with decimals()
    /// @return only the latest price value (no priceId or updatedAt)
    function priceLatestValue() external view returns (uint256);

    /// @notice Return the latest price with decimals()
    /// @return The latest price struct containing the price, priceId and updatedAt.
    function priceLatest() external view returns (IPriceFeed.Item memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IMarket} from "./IMarket.sol";
import {IModel} from "./IModel.sol";
import {IPriceFeed} from "./IPriceFeed.sol";
import {IConfigurableMarket} from "./IConfigurableMarket.sol";

interface IRebalancer {
    struct GetUpdatedStateInputParams {
        IMarket.UpdatedState storedState;
        IModel model;
        IPriceFeed priceFeedAssetToCapital;
        IMarket.Decimals decimals;
        uint80 lastVisitedPriceId;
        uint8 maxUpdatePriceIterations;
        bool inAction;
    }

    struct RebalanceVirtualInputParams {
        IMarket.UpdatedState state;
        int256 diffAsset;
        int256 diffCapital;
        bool doRecomputeBeta;
        IModel model;
        IMarket.Decimals decimals;
    }

    function initialize(address aclManager_) external;

    function rebalanceVirtual(
        RebalanceVirtualInputParams memory p_
    ) external returns (IMarket.UpdatedState memory);

    /**
     * @dev Computes the amount of assets or capital to sell and the minimum amount out to receive
     * when returned deltaAssets is negative => wants to sell assets and deltaCapital = min amount out
     * when returned deltaCapital is negative => wants to buy assets and deltaAssets = min amount out
     */
    function getSwapAmounts(
        int256 deltaAssets_,
        uint256 availableAssets_,
        uint256 availableCapital_,
        uint256 priceAssetToCapital_,
        IMarket.Decimals memory decimals_
    ) external returns (int256 deltaAssets, int256 deltaCapital);

    /**
     * @dev Called after the swap has been executed to reconcile the current (virtual) state to real values
     */
    function reconcileState(
        IMarket.UpdatedState memory state_,
        IModel model_,
        int256 realDeltaAssets,
        int256 realDeltaCapital,
        IMarket.Decimals memory decimals_
    ) external returns (IMarket.UpdatedState memory);

    function getUpdatedState(
        GetUpdatedStateInputParams memory p_
    ) external view returns (IMarket.UpdatedState memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

interface IRiskRatingRegistry {
    struct TakerRiskRating {
        bool exists;
        uint64 rate;
    }

    struct TakerRiskRatingInput {
        uint32 tier;
        uint16 term;
        uint64 rate;
    }

    struct MakerRiskRating {
        bool exists;
        uint64 ratePositive;
        uint64 rateNegative;
    }

    struct MakerRiskRatingInput {
        uint32 tier;
        uint16 term;
        uint64 ratePositive;
        uint64 rateNegative;
    }

    function initialize(address aclManager_) external;

    /**
     * @dev returns taker risk rating for user chosen tier_ and term_
     * @param tier_ user chosen tier, rational, multiplied by PrecisionLib.PERCENTAGE_PRECISION
     * @param termDays_ user chosen term, days
     * @return riskRate_ taker risk rating, rational, multiplied by PrecisionLib.PERCENTAGE_PRECISION
     */
    function getTakerRiskRating(
        uint32 tier_,
        uint16 termDays_
    ) external view returns (uint256 riskRate_);

    /**
     * @dev returns maker risk rating, positive and negative, based on user selected tier_ and term_
     * @param tier_ user selected tier, constant
     * @param term_ user selected term, days
     * @return positiveRiskRate_ maker positive risk rating, rational, multiplied by PrecisionLib.PERCENTAGE_PRECISION
     * @return negativeRiskRate_ maker negative risk rating, rational, multiplied by PrecisionLib.PERCENTAGE_PRECISION
     */
    function getMakerRiskRating(
        uint32 tier_,
        uint16 term_
    )
        external
        view
        returns (uint256 positiveRiskRate_, uint256 negativeRiskRate_);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

interface ISwapper {
    function swap(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address returnTokenInTo_,
        address returnTokenOutTo_
    ) external returns (uint256 amountOut, bool fail);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IPositionManager} from "./IPositionManager.sol";
import {IPermit} from "./IPermit.sol";

interface ITaker is IPositionManager {
    function initialize(
        string memory name_,
        string memory symbol_,
        address aclManager_,
        address market_,
        address weth_
    ) external;

    /**
     * @dev Called by takers to protect an asset {amount_}
     * @param for_ address to receive claim tokens and position
     * @param amount_ amount deposited
     * @param tier_ protection tier
     * @param term_ protection duration (days)
     * @return positionId
     */
    function protectFor(
        address for_,
        uint256 amount_,
        uint32 tier_,
        uint16 term_
    ) external returns (uint256 positionId);

    /**
     * @notice Same as protectFor but for_ = msg.sender
     */
    function protect(
        uint256 amount_,
        uint32 tier_,
        uint16 term_
    ) external returns (uint256 positionId);

    /**
     * @notice Same as protectFor, but with automatic BUMP bonding
     *
     * @dev bumpAmount is assumed to be computed off-chain using the function from the Model
     * We avoid re-computing it here to keep things clean and gas-efficient, but if the amount is not sufficient
     * the transaction would revert when the actual lock is attempted
     */
    function protectForAutoBond(
        address for_,
        uint256 amount_,
        uint32 tier_,
        uint16 term_,
        uint256 bumpAmount_,
        IPermit.Permit memory bumpPermit_
    ) external returns (uint256);

    /**
     * @notice Same as protectFor, but with native tokens
     *
     * @dev native tokens are wrapped into ERC20 tokens and deposited into the asset vault
     */
    function protectNativeFor(
        address for_,
        uint32 tier_,
        uint16 term_
    ) external payable returns (uint256);

    /**
     * @notice Same as protectNativeFor but for_ = msg.sender
     */
    function protectNative(
        uint32 tier_,
        uint16 term_
    ) external payable returns (uint256);

    /**
     * @notice Same as protectNativeFor, but with automatic BUMP bonding
     *
     * @dev bumpAmount is assumed to be computed off-chain using the function from the model
     * We avoid re-computing it here to keep things clean and gas-efficient, but if the amount is not sufficient
     * the transaction would revert when the actual lock is attempted
     */
    function protectNativeForAutoBond(
        address for_,
        uint32 tier_,
        uint16 term_,
        uint256 bumpAmount_,
        IPermit.Permit memory bumpPermit_
    ) external payable returns (uint256);

    /**
     * @notice Closes a position and converts resulting WETH to ETH and sends them to the user
     */
    function closeNative(uint256 positionId_) external;

    /**
     * @notice Closes or claims a position, sending the resulting assets or capital to the address specified
     *
     * @param positionId_ position to close or claim
     * @param isClaim_ if true, claim the position, otherwise close it
     * @param to_ address to send the assets or capital to
     */
    function closeTo(
        uint256 positionId_,
        bool isClaim_,
        address to_,
        address bondTo_
    ) external;

    /**
     * @dev Called by takers to close or claim their position
     *
     * REQUIREMENTS:
     * - when isClaim_ = false then: asset current price >= position floor price
     * - when isClaim_ = true then: asset current price < position floor price
     */
    function close(uint256 positionId_, bool isClaim_) external;

    /**
     * @dev Called by takers to renew their positions for a new term with a new tier
     *
     * REQUIREMENTS:
     * - position must be matured
     * - position must be above floor price
     */
    function takerRenew(
        uint256 positionId_,
        uint32 newTier_,
        uint16 newTerm_
    ) external;

    /**
     * @dev Called by anyone wishing to liquidate a position
     *
     * REQUIREMENTS:
     * - position must be liquidatable
     */
    function takerLiquidateTo(uint256 positionId_, address to_) external;

    /**
     * @notice Returns a taker position identified by positionId_
     * @dev Reverts if position does not exist
     */
    function getPosition(
        uint256 positionId_
    ) external view returns (TakerPosition memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IVault {
    function underlying() external view returns (IERC20Upgradeable);

    function depositFrom(address from_, uint256 amount_) external;

    function withdrawTo(address to_, uint256 amount_) external;

    function balance() external view returns (uint256);

    function initialize(address underlying_, address aclManager_) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IPositionManager} from "../interfaces/IPositionManager.sol";

library MakerPositionLib {
    /**
     * @dev Returns the number of seconds the position has been expired
     */
    function expiredFor(
        IPositionManager.MakerPosition memory position_,
        uint256 atTimestamp_
    ) internal pure returns (uint256) {
        if (isExpired(position_, atTimestamp_)) {
            return
                atTimestamp_ -
                (uint256(position_.start) + uint256(position_.term) * 1 days);
        }
        return 0;
    }

    /**
     * @dev Returns the duration of the position in seconds
     */
    function activeFor(
        IPositionManager.MakerPosition memory position_,
        uint256 atTimestamp_
    ) internal pure returns (uint256) {
        return atTimestamp_ - position_.start;
    }

    /**
     * @dev Returns the timestamp at which the position expires
     */
    function expiresAt(
        IPositionManager.MakerPosition memory position_
    ) internal pure returns (uint256) {
        return (uint256(position_.start) + uint256(position_.term) * 1 days);
    }

    /**
     * @dev Returns true if the position has expired
     */
    function isExpired(
        IPositionManager.MakerPosition memory position_,
        uint256 atTimestamp_
    ) internal pure returns (bool) {
        if (expiresAt(position_) < atTimestamp_) {
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

library PrecisionLib {
    uint256 internal constant PRECISION = 1e18;

    uint256 internal constant PERCENTAGE_PRECISION = 1e8;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IMarket} from "../interfaces/IMarket.sol";

import {PrecisionLib} from "./PrecisionLib.sol";

library PriceLib {
    function assetToCapital(
        uint256 assetAmount_,
        uint256 priceAssetToCapital_,
        IMarket.Decimals memory decimals_
    ) internal pure returns (uint256 capitalAmount_) {
        if (assetAmount_ == 0) {
            return 0;
        }

        int8 decimalsAdjustment = int8(decimals_.asset) +
            int8(decimals_.price) -
            int8(decimals_.capital);

        if (decimalsAdjustment < 0) {
            return
                assetAmount_ *
                priceAssetToCapital_ *
                (10 ** uint256(uint8(-decimalsAdjustment)));
        }

        return
            (assetAmount_ * priceAssetToCapital_) /
            (10 ** uint256(uint8(decimalsAdjustment)));
    }

    function capitalToAsset(
        uint256 capitalAmount_,
        uint256 priceAssetToCapital_,
        IMarket.Decimals memory decimals_
    ) internal pure returns (uint256 assetAmount_) {
        if (capitalAmount_ == 0) {
            return 0;
        }

        int8 decimalsAdjustment = int8(decimals_.asset) +
            int8(decimals_.price) -
            int8(decimals_.capital);

        if (decimalsAdjustment < 0) {
            return
                capitalAmount_ /
                priceAssetToCapital_ /
                (10 ** uint256(uint8(-decimalsAdjustment)));
        }

        return
            (capitalAmount_ * (10 ** uint256(uint8(decimalsAdjustment)))) /
            priceAssetToCapital_;
    }

    function capitalToAsset(
        int256 capitalAmount_,
        uint256 priceAssetToCapital_,
        IMarket.Decimals memory decimals_
    ) internal pure returns (int256 assetAmount_) {
        if (capitalAmount_ == 0) {
            return 0;
        }

        if (capitalAmount_ < 0) {
            return
                -int256(
                    capitalToAsset(
                        uint256(-capitalAmount_),
                        priceAssetToCapital_,
                        decimals_
                    )
                );
        }

        return
            int256(
                capitalToAsset(
                    uint256(capitalAmount_),
                    priceAssetToCapital_,
                    decimals_
                )
            );
    }

    function assetToCapital(
        int256 assetAmount_,
        uint256 priceAssetToCapital_,
        IMarket.Decimals memory decimals_
    ) internal pure returns (int256 capitalAmount_) {
        if (assetAmount_ == 0) {
            return 0;
        }

        if (assetAmount_ < 0) {
            return
                -int256(
                    assetToCapital(
                        uint256(-assetAmount_),
                        priceAssetToCapital_,
                        decimals_
                    )
                );
        }

        return
            int256(
                assetToCapital(
                    uint256(assetAmount_),
                    priceAssetToCapital_,
                    decimals_
                )
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IMarket} from "../../interfaces/IMarket.sol";

library WeightedStateLib {
    function averageMaturity(
        IMarket.WeightedState memory weightedState_
    ) internal pure returns (uint256) {
        return
            (weightedState_.assetsDeposited == 0)
                ? 0
                : weightedState_.awMaturities / weightedState_.assetsDeposited;
    }

    function averageFloorPrice(
        IMarket.WeightedState memory weightedState_
    ) internal pure returns (uint256) {
        return
            (weightedState_.assetsDeposited == 0)
                ? 0
                : weightedState_.awFloorPrices / weightedState_.assetsDeposited;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IPositionManager} from "../interfaces/IPositionManager.sol";

library TakerPositionLib {
    /**
     * @dev Returns the number of seconds the position has been expired
     */
    function expiredFor(
        IPositionManager.TakerPosition memory position_,
        uint256 atTimestamp_
    ) internal pure returns (uint256) {
        if (isExpired(position_, atTimestamp_)) {
            return
                atTimestamp_ -
                (uint256(position_.start) + uint256(position_.term * 1 days));
        }
        return 0;
    }

    /**
     * @dev Returns the duration of the position in seconds
     */
    function activeFor(
        IPositionManager.TakerPosition memory position_,
        uint256 atTimestamp_
    ) internal pure returns (uint256) {
        return atTimestamp_ - position_.start;
    }

    /**
     * @dev Returns the timestamp at which the position expires
     */
    function expiresAt(
        IPositionManager.TakerPosition memory position_
    ) internal pure returns (uint256) {
        return uint256(position_.start) + uint256(position_.term * 1 days);
    }

    /**
     * @dev Returns true if the position has expired
     */
    function isExpired(
        IPositionManager.TakerPosition memory position_,
        uint256 atTimestamp_
    ) internal pure returns (bool) {
        if (expiresAt(position_) < atTimestamp_) {
            return true;
        }
        return false;
    }
}