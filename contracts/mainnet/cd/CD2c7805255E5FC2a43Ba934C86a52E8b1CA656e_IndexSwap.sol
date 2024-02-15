// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
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
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

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
 * ```solidity
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: BUSL-1.1

/**
 * @title AccessController for the Index
 * @author Velvet.Capital
 * @notice Interface to specify and grant different roles
 * @dev Functionalities included:
 *      1. Checks if an address has role
 *      2. Grant different roles to addresses
 */

pragma solidity 0.8.16;

import {FunctionParameters} from "../FunctionParameters.sol";

interface IAccessController {
  function setupRole(bytes32 role, address account) external;

  function hasRole(bytes32 role, address account) external view returns (bool);

  function setUpRoles(FunctionParameters.AccessSetup memory) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {ErrorLibrary} from "../library/ErrorLibrary.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable-4.3.2/proxy/utils/Initializable.sol";

abstract contract CommonReentrancyGuard is Initializable {
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

  function _nonReentrantBefore() internal {
    // On the first call to nonReentrant, _status will be _NOT_ENTERED
    if (_status == _ENTERED) {
      revert ErrorLibrary.ReentrancyGuardReentrantCall();
    }
    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;
  }

  function _nonReentrantAfter() internal {
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
   */
  uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1

/**
 * @title IndexManager for a particular Index
 * @author Velvet.Capital
 * @notice This contract is used for transferring funds form vault to contract and vice versa 
           and swap tokens to and fro from BNB
 * @dev This contract includes functionalities:
 *      1. Deposit tokens to vault
 *      2. Withdraw tokens from vault
 *      3. Swap BNB for tokens
 *      4. Swap tokens for BNB
 */

pragma solidity 0.8.16;

import {IIndexSwap} from "../core/IIndexSwap.sol";

import {FunctionParameters} from "../FunctionParameters.sol";
import {IHandler} from "../handler/IHandler.sol";
import {ExchangeData} from "../handler/ExternalSwapHandler/Helper/ExchangeData.sol";

interface IExchange {
  function init(address _accessController, address _safe, address _oracle, address _tokenRegistry) external;

  /**
   * @return Checks if token is WETH
   */
  function isWETH(address _token, address _protocol) external view returns (bool);

  function _pullFromVault(address t, uint256 amount, address to) external;

  function _pullFromVaultRewards(address token, uint256 amount, address to) external;

  /**
   * @notice The function swaps ETH to a specific token
   * @param inputData includes the input parmas
   */
  function swapETHToToken(FunctionParameters.SwapETHToTokenPublicData calldata inputData) external payable;

  /**
   * @notice The function swaps a specific token to ETH
   * @dev Requires the tokens to be send to this contract address before swapping
   * @param inputData includes the input parmas
   * @return swapResult The outcome amount in ETH afer swapping
   */
  function _swapTokenToETH(
    FunctionParameters.SwapTokenToETHData calldata inputData
  ) external returns (uint256[] calldata);

  /**
   * @notice The function swaps a specific token to ETH
   * @dev Requires the tokens to be send to this contract address before swapping
   * @param inputData includes the input parmas
   * @return swapResult The outcome amount in ETH afer swapping
   */
  function _swapTokenToToken(FunctionParameters.SwapTokenToTokenData memory inputData) external returns (uint256);

  function _swapTokenToTokens(
    FunctionParameters.SwapTokenToTokensData memory inputData,uint256 balanceBefore
  ) external payable returns (uint256 investedAmountAfterSlippage);

  function _swapTokenToTokensOffChain(
    ExchangeData.InputData memory inputData,
    IIndexSwap index,
    uint256[] calldata _lpSlippage,
    address[] memory _tokens,
    uint256[] calldata _buyAmount,
    uint256 balanceBefore,
    address _toUser
  ) external returns (uint256 investedAmountAfterSlippage);

  function swapOffChainTokens(
    ExchangeData.IndexOperationData memory inputdata
  ) external returns (uint256 balanceInUSD, uint256 underlyingIndex);

  function claimTokens(IIndexSwap _index, address[] calldata _tokens) external;

  function oracle() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

/**
 * @title IndexSwap for the Index
 * @author Velvet.Capital
 * @notice This contract is used by the user to invest and withdraw from the index
 * @dev This contract includes functionalities:
 *      1. Invest in the particular fund
 *      2. Withdraw from the fund
 */

pragma solidity 0.8.16;

import {FunctionParameters} from "../FunctionParameters.sol";

interface IIndexSwap {
  function vault() external view returns (address);

  function feeModule() external view returns (address);

  function exchange() external view returns (address);

  function tokenRegistry() external view returns (address);

  function accessController() external view returns (address);

  function paused() external view returns (bool);

  function TOTAL_WEIGHT() external view returns (uint256);

  function iAssetManagerConfig() external view returns (address);

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

  /**
   * @dev Token record data structure
   * @param lastDenormUpdate timestamp of last denorm change
   * @param denorm denormalized weight
   * @param index index of address in tokens array
   */
  struct Record {
    uint40 lastDenormUpdate;
    uint96 denorm;
    uint8 index;
  }

  /** @dev Emitted when public trades are enabled. */
  event LOG_PUBLIC_SWAP_ENABLED();

  function init(FunctionParameters.IndexSwapInitData calldata initData) external;

  /**
   * @dev Sets up the initial assets for the pool.
   * @param tokens Underlying tokens to initialize the pool with
   * @param denorms Initial denormalized weights for the tokens
   */
  function initToken(address[] calldata tokens, uint96[] calldata denorms) external;

  // For Minting Shares
  function mintShares(address _to, uint256 _amount) external;

  //For Burning Shares
  function burnShares(address _to, uint256 _amount) external;

  /**
     * @notice The function swaps BNB into the portfolio tokens after a user makes an investment
     * @dev The output of the swap is converted into USD to get the actual amount after slippage to calculate 
            the index token amount to mint
     * @dev (tokenBalance, vaultBalance) has to be calculated before swapping for the _mintShareAmount function 
            because during the swap the amount will change but the index token balance is still the same 
            (before minting)
     */
  function investInFund(uint256[] calldata _slippage, address _swapHandler) external payable;

  /**
     * @notice The function swaps the amount of portfolio tokens represented by the amount of index token back to 
               BNB and returns it to the user and burns the amount of index token being withdrawn
     * @param tokenAmount The index token amount the user wants to withdraw from the fund
     */
  function withdrawFund(uint256 tokenAmount, uint256[] calldata _slippage) external;

  /**
    @notice The function will pause the InvestInFund() and Withdrawal() called by the rebalancing contract.
    @param _state The state is bool value which needs to input by the Index Manager.
    */
  function setPaused(bool _state) external;

  function setRedeemed(bool _state) external;

  /**
    @notice The function will set lastRebalanced time called by the rebalancing contract.
    @param _time The time is block.timestamp, the moment when rebalance is done
  */
  function setLastRebalance(uint256 _time) external;

  /**
    @notice The function returns lastRebalanced time
  */
  function getLastRebalance() external view returns (uint256);

  /**
    @notice The function returns lastPaused time
  */
  function getLastPaused() external view returns (uint256);

  /**
   * @notice The function updates the record struct including the denorm information
   * @dev The token list is passed so the function can be called with current or updated token list
   * @param tokens The updated token list of the portfolio
   * @param denorms The new weights for for the portfolio
   */
  function updateRecords(address[] memory tokens, uint96[] memory denorms) external;

  /**
   * @notice This function update records with new tokenlist and weights
   * @param tokens Array of the tokens to be updated
   * @param _denorms Array of the updated denorm values
   */
  function updateTokenListAndRecords(address[] calldata tokens, uint96[] calldata _denorms) external;

  function getRedeemed() external view returns (bool);

  function getTokens() external view returns (address[] memory);

  function getRecord(address _token) external view returns (Record memory);

  function updateTokenList(address[] memory tokens) external;

  function deleteRecord(address t) external;

  function oracle() external view returns (address);

  function lastInvestmentTime(address owner) external view returns (uint256);

  function checkCoolDownPeriod(address _user) external view;

  function mintTokenAndSetCooldown(address _to, uint256 _mintAmount) external returns (uint256);

  function burnWithdraw(address _to, uint256 _mintAmount) external returns (uint256 exitFee);

  function setFlags(bool _pauseState, bool _redeemState) external;

  function reentrancyGuardEntered() external returns (bool);

  function nonReentrantBefore() external;

  function nonReentrantAfter() external;
}

// SPDX-License-Identifier: BUSL-1.1

/**
 * @title IndexSwap for the Index
 * @author Velvet.Capital
 * @notice This contract is used by the user to invest and withdraw from the index
 * @dev  The IndexSwap contract facilitates the investment and withdrawal of funds in a portfolio of tokens.
 *        It allows users to invest in the portfolio and receive index tokens representing their share in the portfolio.
 *        Users can also withdraw their investment by burning index tokens and receiving the corresponding portfolio tokens.
 * This contract includes functionalities:
 *      1. Invest in the particular fund
 *      2. Withdraw from the fund
 */

pragma solidity 0.8.16;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.3.2/token/ERC20/ERC20Upgradeable.sol";
import {UUPSUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable-4.3.2/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable-4.3.2/access/OwnableUpgradeable.sol";
import {IIndexSwap} from "../core/IIndexSwap.sol";
import "../core/IndexSwapLibrary.sol";
import {IPriceOracle} from "../oracle/IPriceOracle.sol";
import {IAccessController} from "../access/IAccessController.sol";
import {ITokenRegistry} from "../registry/ITokenRegistry.sol";
import {IExchange} from "./IExchange.sol";
import {IAssetManagerConfig} from "../registry/IAssetManagerConfig.sol";
import {IWETH} from "../interfaces/IWETH.sol";

import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import {IFeeModule} from "../fee/IFeeModule.sol";
import {FunctionParameters} from "../FunctionParameters.sol";

import {ErrorLibrary} from "../library/ErrorLibrary.sol";
import {CommonReentrancyGuard} from "./CommonReentrancyGuard.sol";

contract IndexSwap is Initializable, ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable, CommonReentrancyGuard {
  /**
   * @dev Token record data structure
   * @param lastDenormUpdate timestamp of last denorm change
   * @param denorm denormalized weight
   * @param index index of address in tokens array
   * @param handler handler address for token
   */
  struct Record {
    uint40 lastDenormUpdate;
    uint96 denorm;
    uint256 index;
  }

  // Array of underlying tokens in the pool.
  address[] internal _tokens;

  // Internal records of the pool's underlying tokens
  mapping(address => Record) internal _records;

  // Internal records of the tokens input by asset manager while updating
  mapping(address => bool) internal _previousToken;

  // IERC20 public token;

  //Keeps track of user last investment time
  mapping(address => uint256) public lastInvestmentTime;
  mapping(address => uint256) public lastWithdrawCooldown;

  address internal _vault;
  address internal _module;

  bool internal _paused;
  uint256 internal _lastPaused;

  uint256 internal _lastRebalanced;

  bool internal _redeemed;

  IPriceOracle internal _oracle;
  IFeeModule internal _feeModule;
  IAccessController internal _accessController;
  ITokenRegistry internal _tokenRegistry;
  IExchange internal _exchange;
  IAssetManagerConfig internal _iAssetManagerConfig;
  address internal WETH;
  // Total denormalized weight of the pool.
  uint256 internal constant _TOTAL_WEIGHT = 10_000;

  //events
  event InvestInFund(
    address user,
    uint256 investedAmount,
    uint256 tokenAmount,
    uint256 rate,
    uint256 currentUserBalance,
    address index
  );
  event WithdrawFund(
    address indexed user,
    uint256 tokenAmount,
    uint256 indexed rate,
    uint256 currentUserBalance,
    address indexed index
  );

  // /** @dev Emitted when public trades are enabled. */
  event LOG_PUBLIC_SWAP_ENABLED(uint indexed time);

  constructor() {
    _disableInitializers();
  }

  /**
   * @notice This function make sure of the necessary checks before the transfer of index tokens.
   * (Making sure that the fund allows the token transfer and the receipient address is whitelisted)
   */
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);
    if (from == address(0) || to == address(0)) {
      return;
    }
    if (
      !(_iAssetManagerConfig.transferableToPublic() ||
        (_iAssetManagerConfig.transferable() && _iAssetManagerConfig.whitelistedUsers(to)))
    ) {
      revert ErrorLibrary.Transferprohibited();
    }
    checkCoolDownPeriod(from);
  }

  /**
   * @notice This function is used to init the IndexSwap while deployment
   * @param initData Includes the input params
   */
  function init(FunctionParameters.IndexSwapInitData calldata initData) external initializer {
    __ERC20_init(initData._name, initData._symbol);
    __UUPSUpgradeable_init();
    __Ownable_init();
    __ReentrancyGuard_init();
    _vault = initData._vault;
    _module = initData._module;
    _accessController = IAccessController(initData._accessController);
    _tokenRegistry = ITokenRegistry(initData._tokenRegistry);
    _oracle = IPriceOracle(initData._oracle);
    _exchange = IExchange(initData._exchange);
    _iAssetManagerConfig = IAssetManagerConfig(initData._iAssetManagerConfig);
    _feeModule = IFeeModule(initData._feeModule);
    WETH = _tokenRegistry.getETH();
  }

  /**
   * @dev Sets up the initial assets for the pool.
   * @param tokens Underlying tokens to initialize the pool with
   * @param denorms Initial denormalized weights for the tokens
   */
  function initToken(address[] calldata tokens, uint96[] calldata denorms) external virtual onlySuperAdmin {
    if (tokens.length > _tokenRegistry.getMaxAssetLimit())
      revert ErrorLibrary.TokenCountOutOfLimit(_tokenRegistry.getMaxAssetLimit());

    if (tokens.length != denorms.length) {
      revert ErrorLibrary.InvalidInitInput();
    }
    if (_tokens.length != 0) {
      revert ErrorLibrary.AlreadyInitialized();
    }
    uint256 totalWeight;
    for (uint256 i = 0; i < tokens.length; i++) {
      if (_previousToken[tokens[i]] == true) {
        revert ErrorLibrary.TokenAlreadyExist();
      }
      address token = tokens[i];
      uint96 _denorm = denorms[i];
      IndexSwapLibrary._beforeInitCheck(IIndexSwap(address(this)), token, _denorm);
      _records[token] = Record({lastDenormUpdate: uint40(getTimeStamp()), denorm: _denorm, index: uint256(i)});
      _tokens.push(token);

      totalWeight = totalWeight + _denorm;
      _previousToken[tokens[i]] = true;
    }
    setFalse(tokens);
    _weightCheck(totalWeight);
    emit LOG_PUBLIC_SWAP_ENABLED(getTimeStamp());
  }

  modifier onlySuperAdmin() {
    if (!_checkRole("SUPER_ADMIN", msg.sender)) {
      revert ErrorLibrary.CallerNotSuperAdmin();
    }
    _;
  }

  /**
   * @notice This function mints new shares to a particular address of the specific amount
   */
  function mintShares(address _to, uint256 _amount) external virtual onlyMinter {
    _mint(_to, _amount);
  }

  /**
   * @notice This function burns the specific amount of shares of a particular address
   */
  function burnShares(address _to, uint256 _amount) external virtual onlyMinter {
    _burn(_to, _amount);
  }

  /**
     * @notice The function swaps BNB into the portfolio tokens after a user makes an investment
     * @dev The output of the swap is converted into USD to get the actual amount after slippage to calculate 
            the index token amount to mint
     * @dev (tokenBalance, vaultBalance) has to be calculated before swapping for the _mintShareAmount function 
            because during the swap the amount will change but the index token balance is still the same 
            (before minting)
     */
  function investInFund(
    FunctionParameters.InvestFund memory investData
  ) external payable virtual nonReentrant notPaused {
    IndexSwapLibrary.beforeInvestment(
      IIndexSwap(address(this)),
      investData._slippage.length,
      investData._lpSlippage.length,
      msg.sender
    );
    address _token = investData._token;
    uint256 balanceBefore = IndexSwapLibrary.checkBalance(_token, address(_exchange), WETH);
    uint256 _amount = investData._tokenAmount;
    uint256 _investmentAmountInUSD;

    if (msg.value > 0) {
      if (WETH != _token) {
        revert ErrorLibrary.InvalidToken();
      }
      _amount = msg.value;
    } else {
      IndexSwapLibrary._checkPermissionAndBalance(_token, _amount, _iAssetManagerConfig, msg.sender);
      TransferHelper.safeTransferFrom(_token, msg.sender, address(_exchange), _amount);
    }

    _investmentAmountInUSD = _oracle.getPriceTokenUSD18Decimals(_token, _amount);
    _checkInvestmentValue(_investmentAmountInUSD);

    uint256 investedAmountAfterSlippage;
    uint256 vaultBalance;
    uint256[] memory amount = new uint256[](_tokens.length);
    uint256[] memory tokenBalance = new uint256[](_tokens.length);

    (tokenBalance, vaultBalance) = getTokenAndVaultBalance();
    chargeFees(vaultBalance);

    amount = IndexSwapLibrary.calculateSwapAmounts(
      IIndexSwap(address(this)),
      _amount,
      tokenBalance,
      vaultBalance,
      _tokens
    );
    uint256[] memory slippage = investData._slippage;

    investedAmountAfterSlippage = _exchange._swapTokenToTokens{value: msg.value}(
      FunctionParameters.SwapTokenToTokensData(
        address(this),
        _token,
        investData._swapHandler,
        msg.sender,
        _amount,
        totalSupply(),
        amount,
        slippage,
        investData._lpSlippage
      ),
      balanceBefore
    );

    if (investedAmountAfterSlippage <= 0) {
      revert ErrorLibrary.ZeroFinalInvestmentValue();
    }
    uint256 tokenAmount;
    uint256 _totalSupply = totalSupply();
    tokenAmount = getTokenAmount(_totalSupply, investedAmountAfterSlippage, vaultBalance);
    if (tokenAmount <= 0) {
      revert ErrorLibrary.ZeroTokenAmount();
    }
    uint256 _mintedAmount = _mintInvest(msg.sender, tokenAmount);
    lastWithdrawCooldown[msg.sender] = IndexSwapLibrary.calculateCooldownPeriod(
      balanceOf(msg.sender),
      _mintedAmount,
      _tokenRegistry.COOLDOWN_PERIOD(),
      lastWithdrawCooldown[msg.sender],
      lastInvestmentTime[msg.sender]
    );
    lastInvestmentTime[msg.sender] = getTimeStamp();

    emit InvestInFund(
      msg.sender,
      _amount,
      _mintedAmount,
      IndexSwapLibrary.getIndexTokenRate(IIndexSwap(address(this))),
      balanceOf(msg.sender),
      address(this)
    );
  }

  /*
   * @notice The function swaps the amount of portfolio tokens represented by the amount of index token back to
   *           BNB or token pass and returns it to the user and burns the amount of index token being withdrawn
   *          Allows users to withdraw their investment by burning index tokens.
   *          also option  Users will receive the corresponding underlying tokens.
   * @dev This function implements the withdrawal process for the fund.
   * @param initData WithdrawFund struct containing the function parameters:
   *        - _slippage: Array of slippage values for token swaps
   *        - _lpSlippage: Array of slippage values for LP token swaps
   *        - tokenAmount: Amount of index tokens to be burned
   *        - _swapHandler: Address of the swap handler contract
   *        - _token: Address of the token to withdraw or convert to
   *        - isMultiAsset: Flag indicating if the withdrawal involves multiple assets or a single asset
   *
   */
  function withdrawFund(FunctionParameters.WithdrawFund calldata initData) external nonReentrant notPaused {
    checkCoolDownPeriod(msg.sender);
    IndexSwapLibrary.beforeWithdrawCheck(
      initData._slippage.length,
      initData._lpSlippage.length,
      initData._token,
      msg.sender,
      IIndexSwap(address(this)),
      initData.tokenAmount
    );
    uint256 vaultBalance;
    (, vaultBalance) = getTokenAndVaultBalance();
    if (!(msg.sender == _iAssetManagerConfig.assetManagerTreasury() || msg.sender == _tokenRegistry.velvetTreasury())) {
      chargeFees(vaultBalance);
    }
    uint256 totalSupplyIndex = totalSupply();
    uint256 _exitFee = _burnWithdraw(msg.sender, initData.tokenAmount);
    uint256 _tokenAmount = initData.tokenAmount - _exitFee;
    for (uint256 i = 0; i < _tokens.length; i++) {
      address token = _tokens[i];
      IHandler handler = IHandler(_tokenRegistry.getTokenInformation(token).handler);
      uint256 tokenBalance = handler.getTokenBalance(_vault, token);
      tokenBalance = (tokenBalance * _tokenAmount) / totalSupplyIndex;
      if (initData.isMultiAsset || token == initData._token) {
        IndexSwapLibrary.withdrawMultiAssetORWithdrawToken(
          address(_tokenRegistry),
          address(_exchange),
          token,
          tokenBalance
        );
      } else {
        _exchange._pullFromVault(token, tokenBalance, address(_exchange));
        _exchange._swapTokenToToken(
          FunctionParameters.SwapTokenToTokenData(
            token,
            initData._token,
            msg.sender,
            initData._swapHandler,
            msg.sender,
            tokenBalance,
            initData._slippage[i],
            initData._lpSlippage[i],
            false
          )
        );
      }
    }
    emit WithdrawFund(
      msg.sender,
      initData.tokenAmount,
      IndexSwapLibrary.getIndexTokenRate(IIndexSwap(address(this))),
      balanceOf(msg.sender),
      address(this)
    );
  }

  /**
   * @notice Performs additional validation after the withdrawal process.
   *  Basic us that when use withdraw he not keep dust after withdraw index token
   * @dev This function is called after the withdrawal process is completed.
   */
  function validateWithdraw(address _user) internal {
    uint256 _minInvestValue = _tokenRegistry.MIN_VELVET_INVESTMENTAMOUNT();
    if (!(balanceOf(_user) == 0 || balanceOf(_user) >= _minInvestValue)) {
      revert ErrorLibrary.BalanceCantBeBelowVelvetMinInvestAmount({minVelvetInvestment: _minInvestValue});
    }
  }

  /**
   * @notice Calculates the token amount based on the total supply, invested amount, and vault balance.
   * @dev If the total supply is greater than zero, the token amount is calculated using the formula:
   *  tokenAmount = investedAmount * _totalSupply / vaultBalance
   *  If the total supply is zero, the token amount is equal to the invested amount.
   * @param _totalSupply The total supply of index tokens.
   * @param investedAmount The amount of funds invested.
   * @param vaultBalance The balance of funds in the vault.
   * @return tokenAmount The calculated token amount.
   */
  function getTokenAmount(
    uint256 _totalSupply,
    uint256 investedAmount,
    uint256 vaultBalance
  ) internal pure returns (uint256 tokenAmount) {
    if (_totalSupply > 0) {
      tokenAmount = (investedAmount * _totalSupply) / vaultBalance;
    } else {
      tokenAmount = investedAmount;
    }
  }

  function nonReentrantBefore() external onlyMinter {
    _nonReentrantBefore();
  }

  function nonReentrantAfter() external onlyMinter {
    _nonReentrantAfter();
  }

  /**
   * @notice Mints new index tokens and assigns them to the specified address.
   * @dev If the entry fee is applicable, it is charged and deducted from the minted tokens.
   * @param _to The address to which the minted index tokens are assigned.
   * @param _mintAmount The amount of index tokens to mint.
   */
  function _mintInvest(address _to, uint256 _mintAmount) internal returns (uint256) {
    uint256 entryFee = _iAssetManagerConfig.entryFee();

    // Check if the entry fee should be charged and deducted from the minted tokens
    if (IndexSwapLibrary.mintAndBurnCheck(entryFee, _to, address(_tokenRegistry), address(_iAssetManagerConfig))) {
      _mintAmount = _feeModule.chargeEntryFee(_mintAmount, entryFee);
    }

    // Mint new index tokens and assign them to the specified address
    _mint(_to, _mintAmount);
    return _mintAmount;
  }

  /**
   * @notice Burns a specified amount of index tokens from the specified address and returns the exit fee.
   * @dev If the exit fee is applicable, it is charged and deducted from the burned tokens.
   * @param _to The address from which the index tokens are burned.
   * @param _mintAmount The amount of index tokens to burn.
   * @return The exit fee deducted from the burned tokens.
   */
  function _burnWithdraw(address _to, uint256 _mintAmount) internal returns (uint256) {
    uint256 exitFee = _iAssetManagerConfig.exitFee();
    uint256 returnValue;

    // Check if the exit fee should be charged and deducted from the burned tokens
    if (IndexSwapLibrary.mintAndBurnCheck(exitFee, _to, address(_tokenRegistry), address(_iAssetManagerConfig))) {
      (, , uint256 _exitFee) = _feeModule.chargeExitFee(_mintAmount, exitFee);
      returnValue = _exitFee;
    }

    // Burn the specified amount of index tokens from the specified address
    _burn(_to, _mintAmount);

    validateWithdraw(_to);

    return returnValue;
  }

  /**
   * @notice Mints a specified amount of index tokens to the specified address.
   * @dev This function can only be called by the designated minter.
   * @param _to The address to which the index tokens are minted.
   * @param _mintAmount The amount of index tokens to mint.
   */
  function mintTokenAndSetCooldown(
    address _to,
    uint256 _mintAmount
  ) external onlyMinter returns (uint256 _mintedAmount) {
    _mintedAmount = _mintInvest(_to, _mintAmount);
    lastWithdrawCooldown[_to] = IndexSwapLibrary.calculateCooldownPeriod(
      balanceOf(_to),
      _mintedAmount,
      _tokenRegistry.COOLDOWN_PERIOD(),
      lastWithdrawCooldown[_to],
      lastInvestmentTime[_to]
    );
    lastInvestmentTime[_to] = getTimeStamp();
  }

  /**
   * @notice Burns a specified amount of index tokens from the specified address and returns the exit fee.
   * @dev This function can only be called by the designated minter.
   * @param _to The address from which the index tokens are burned.
   * @param _mintAmount The amount of index tokens to burn.
   * @return exitFee The exit fee charged for the burn operation.
   */
  function burnWithdraw(address _to, uint256 _mintAmount) external onlyMinter returns (uint256 exitFee) {
    exitFee = _burnWithdraw(_to, _mintAmount);
  }

  modifier onlyRebalancerContract() {
    if (!_checkRole("REBALANCER_CONTRACT", msg.sender)) {
      revert ErrorLibrary.CallerNotRebalancerContract();
    }
    _;
  }

  modifier onlyMinter() {
    if (!_checkRole("MINTER_ROLE", msg.sender)) {
      revert ErrorLibrary.CallerNotIndexManager();
    }
    _;
  }

  modifier notPaused() {
    if (_paused) {
      revert ErrorLibrary.ContractPaused();
    }
    _;
  }

  /**
    @notice The function will pause the InvestInFund() and Withdrawal() called by the rebalancing contract.
    @param _state The state is bool value which needs to input by the Index Manager.
  */
  function setPaused(bool _state) external virtual onlyRebalancerContract {
    _setPaused(_state);
  }

  function _setPaused(bool _state) internal virtual {
    _paused = _state;
    _lastPaused = getTimeStamp();
  }

  /**
    @notice The function will set lastRebalanced time called by the rebalancing contract.
    @param _time The time is block.timestamp, the moment when rebalance is done
  */
  function setLastRebalance(uint256 _time) external virtual onlyRebalancerContract {
    _setLastRebalance(_time);
  }

  function _setLastRebalance(uint256 _time) internal virtual {
    _lastRebalanced = _time;
  }

  /**
    @notice The function will update the redeemed value
    @param _state The state is bool value which needs to input by the Index Manager.
  */
  function setRedeemed(bool _state) external virtual onlyRebalancerContract {
    _setRedeemed(_state);
  }

  function _setRedeemed(bool _state) internal virtual {
    _redeemed = _state;
  }

  /**
   * @notice The function updates the record struct including the denorm information
   * @dev The token list is passed so the function can be called with current or updated token list
   * @param tokens The updated token list of the portfolio
   * @param denorms The new weights for for the portfolio
   */
  function updateRecords(address[] calldata tokens, uint96[] calldata denorms) external virtual onlyRebalancerContract {
    _updateRecords(tokens, denorms);
  }

  /**
   * @notice The function is internal function for update records
   * @dev The token list is passed so the function can be called with current or updated token list
   * @param tokens The updated token list of the portfolio
   * @param denorms The new weights for for the portfolio
   */
  function _updateRecords(address[] calldata tokens, uint96[] calldata denorms) internal {
    uint256 totalWeight;
    for (uint256 i = 0; i < tokens.length; i++) {
      uint96 _denorm = denorms[i];
      address token = tokens[i];
      if (_denorm <= 0) {
        revert ErrorLibrary.ZeroDenormValue();
      }
      if (_previousToken[token] == true) {
        revert ErrorLibrary.TokenAlreadyExist();
      }
      _records[token] = Record({lastDenormUpdate: uint40(getTimeStamp()), denorm: _denorm, index: uint8(i)});

      totalWeight = totalWeight + _denorm;
      _previousToken[token] = true;
    }
    setFalse(tokens);
    _weightCheck(totalWeight);
  }

  /**
   * @notice This function update records with new tokenlist and weights
   * @param tokens Array of the tokens to be updated
   * @param _denorms Array of the updated denorm values
   */
  function updateTokenListAndRecords(
    address[] calldata tokens,
    uint96[] calldata _denorms
  ) external virtual onlyRebalancerContract {
    _updateTokenList(tokens);
    _updateRecords(tokens, _denorms);
  }

  /**
    @notice The function sets the token state to false for it be reused later by the asset manager
    @param tokens Addresses of the tokens whose state is to be changed
  */
  function setFalse(address[] calldata tokens) internal {
    for (uint i = 0; i < tokens.length; i++) {
      _previousToken[tokens[i]] = false;
    }
  }

  /**
    @notice The function returns the token list
  */
  function getTokens() public view virtual returns (address[] memory) {
    return _tokens;
  }

  /**
    @notice The function returns a boolean ouput of the redeemed value
  */
  function getRedeemed() public view virtual returns (bool) {
    return _redeemed;
  }

  /**
    @notice The function returns lastRebalanced time
  */
  function getLastRebalance() public view virtual returns (uint256) {
    return _lastRebalanced;
  }

  /**
    @notice The function returns lastPaused time
  */
  function getLastPaused() public view virtual returns (uint256) {
    return _lastPaused;
  }

  /**
   * @notice This function returns the record of a specific token
   */
  function getRecord(address _token) external view virtual returns (Record memory) {
    return _records[_token];
  }

  /**
   * @notice This function updates the token list with new tokens
   * @param tokens List of updated tokens
   */
  function updateTokenList(address[] calldata tokens) external virtual onlyRebalancerContract {
    _updateTokenList(tokens);
  }

  function _updateTokenList(address[] calldata tokens) internal {
    uint256 _maxAssetLimit = _tokenRegistry.getMaxAssetLimit();
    if (tokens.length > _maxAssetLimit) revert ErrorLibrary.TokenCountOutOfLimit(_maxAssetLimit);
    _tokens = tokens;
  }

  /**
   * @notice This function returns the address of the vault
   */
  function vault() external view returns (address) {
    return _vault;
  }

  /**
   * @notice This function returns the address of the fee module
   */
  function feeModule() external view returns (address) {
    return address(_feeModule);
  }

  /**
   * @notice This function returns the address of the exchange
   */
  function exchange() external view returns (address) {
    return address(_exchange);
  }

  /**
   * @notice This function returns the address of the token registry
   */
  function tokenRegistry() external view returns (address) {
    return address(_tokenRegistry);
  }

  /**
   * @notice This function returns the address of the access controller
   */
  function accessController() external view returns (address) {
    return address(_accessController);
  }

  /**
   * @notice This function returns the paused or unpaused state of the investment/withdrawal
   */
  function paused() external view returns (bool) {
    return _paused;
  }

  /**
   * @notice This function returns the total weight, which is supposed to be = 10_000 (representing 100%)
   */
  function TOTAL_WEIGHT() external pure returns (uint256) {
    return _TOTAL_WEIGHT;
  }

  /**
   * @notice This function returns the address of the asset manager config
   */
  function iAssetManagerConfig() external view returns (address) {
    return address(_iAssetManagerConfig);
  }

  /**
   * @notice This function returns the address of the price oracle
   */
  function oracle() external view returns (address) {
    return address(_oracle);
  }

  /**
   * @notice This function deletes a particular token record
   * @param t Address of the token whose record is to be deleted
   */
  function deleteRecord(address t) external virtual onlyRebalancerContract {
    delete _records[t];
  }

  /**
   * @notice Claims the token for the caller via the Exchange contract
   * @param tokens Addresses of the token for which the reward is to be claimed
   */
  function claimTokens(address[] calldata tokens) external nonReentrant {
    _exchange.claimTokens(IIndexSwap(address(this)), tokens);
  }

  /**
   * @notice Check for totalweight == _TOTAL_WEIGHT
   * @param weight weight of portfolio
   */
  function _weightCheck(uint256 weight) internal pure {
    if (weight != _TOTAL_WEIGHT) {
      revert ErrorLibrary.InvalidWeights({totalWeight: _TOTAL_WEIGHT});
    }
  }

  /**
   * @notice This internal function returns tokenBalance in array, vaultBalance and vaultBalance in usd
   */
  function getTokenAndVaultBalance() internal returns (uint256[] memory tokenBalance, uint256 vaultBalance) {
    (tokenBalance, vaultBalance) = IndexSwapLibrary.getTokenAndVaultBalance(IIndexSwap(address(this)), getTokens());
  }

  /**
   * @notice This internal function check for role
   */
  function _checkRole(bytes memory _role, address user) internal view returns (bool) {
    return _accessController.hasRole(keccak256(_role), user);
  }

  /**
   * @notice This internal set multiple flags such as setLastRebalance,setPause and setRedeemed
   */
  function setFlags(bool _pauseState, bool _redeemState) external onlyRebalancerContract {
    _setLastRebalance(getTimeStamp());
    _setPaused(_pauseState);
    _setRedeemed(_redeemState);
  }

  /**
   * @notice The function is used to check investment value
   */
  function _checkInvestmentValue(uint256 _tokenAmount) internal view {
    IndexSwapLibrary._checkInvestmentValue(_tokenAmount, _iAssetManagerConfig);
  }

  /**
   * @notice This function is used to charge fees
   */
  function chargeFees(uint256 vaultBalance) internal {
    _feeModule.chargeFeesFromIndex(vaultBalance);
  }

  /**
   * @notice This function returns remaining cooldown for user
   */
  function getRemainingCoolDown(address _user) public view returns (uint256) {
    uint256 userCoolDownPeriod = lastInvestmentTime[_user] + lastWithdrawCooldown[_user];
    return userCoolDownPeriod < getTimeStamp() ? 0 : userCoolDownPeriod - getTimeStamp();
  }

  /**
   * @notice This function check whether the cooldown period is passed or not
   */
  function checkCoolDownPeriod(address _user) public view {
    if (getRemainingCoolDown(_user) > 0) {
      revert ErrorLibrary.CoolDownPeriodNotPassed();
    }
  }

  /**
   * @notice This function returns timeStamp
   */
  function getTimeStamp() internal view returns (uint256) {
    return block.timestamp;
  }

  // important to receive ETH
  receive() external payable {}

  /**
   * @notice Authorizes upgrade for this contract
   * @param newImplementation Address of the new implementation
   */
  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}
}

// SPDX-License-Identifier: BUSL-1.1

/**
 * @title IndexSwapLibrary for a particular Index
 * @author Velvet.Capital
 * @notice This contract is used for all the calculations and also get token balance in vault
 * @dev This contract includes functionalities:
 *      1. Get tokens balance in the vault
 *      2. Calculate the swap amount needed while performing different operation
 */

pragma solidity 0.8.16;

import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.3.2/interfaces/IERC20Upgradeable.sol";

import {IPriceOracle} from "../oracle/IPriceOracle.sol";
import {IIndexSwap} from "./IIndexSwap.sol";
import {IAssetManagerConfig} from "../registry/IAssetManagerConfig.sol";
import {ITokenRegistry} from "../registry/ITokenRegistry.sol";

import {ISwapHandler} from "../handler/ISwapHandler.sol";
import {IExternalSwapHandler} from "../handler/IExternalSwapHandler.sol";
import {IFeeModule} from "../fee/IFeeModule.sol";

import {IExchange} from "./IExchange.sol";
import {IHandler, FunctionParameters} from "../handler/IHandler.sol";

import {ErrorLibrary} from "../library/ErrorLibrary.sol";

import {IWETH} from "../interfaces/IWETH.sol";

library IndexSwapLibrary {
  /**
     * @notice The function calculates the balance of each token in the vault and converts them to USD and 
               the sum of those values which represents the total vault value in USD
     * @return tokenXBalance A list of the value of each token in the portfolio in USD
     * @return vaultValue The total vault value in USD
     */
  function getTokenAndVaultBalance(
    IIndexSwap _index,
    address[] memory _tokens
  ) internal returns (uint256[] memory, uint256) {
    uint256[] memory tokenBalanceInUSD = new uint256[](_tokens.length);
    uint256 vaultBalance;
    ITokenRegistry registry = ITokenRegistry(_index.tokenRegistry());
    address vault = _index.vault();
    if (_index.totalSupply() > 0) {
      for (uint256 i = 0; i < _tokens.length; i++) {
        address _token = _tokens[i];
        IHandler handler = IHandler(registry.getTokenInformation(_token).handler);
        tokenBalanceInUSD[i] = handler.getTokenBalanceUSD(vault, _token);
        vaultBalance = vaultBalance + tokenBalanceInUSD[i];
      }
      return (tokenBalanceInUSD, vaultBalance);
    } else {
      return (new uint256[](0), 0);
    }
  }

  /**
   * @notice The function calculates the amount in BNB to swap from BNB to each token
   * @dev The amount for each token has to be calculated to ensure the ratio (weight in the portfolio) stays constant
   * @param tokenAmount The amount a user invests into the portfolio
   * @param tokenBalanceInUSD The balanace of each token in the portfolio converted to USD
   * @param vaultBalance The total vault value of all tokens converted to USD
   * @return A list of amounts that are being swapped into the portfolio tokens
   */
  function calculateSwapAmounts(
    IIndexSwap _index,
    uint256 tokenAmount,
    uint256[] memory tokenBalanceInUSD,
    uint256 vaultBalance,
    address[] memory _tokens
  ) internal view returns (uint256[] memory) {
    uint256[] memory amount = new uint256[](_tokens.length);
    if (_index.totalSupply() > 0) {
      for (uint256 i = 0; i < _tokens.length; i++) {
        uint256 balance = tokenBalanceInUSD[i];
        if (balance * tokenAmount < vaultBalance) revert ErrorLibrary.IncorrectInvestmentTokenAmount();
        amount[i] = (balance * tokenAmount) / vaultBalance;
      }
    }
    return amount;
  }

  /**
   * @notice This function transfers the token to swap handler and makes the token to token swap happen
   */
  function transferAndSwapTokenToToken(
    address tokenIn,
    ISwapHandler swapHandler,
    uint256 swapValue,
    uint256 slippage,
    address tokenOut,
    address to,
    bool isEnabled
  ) external returns (uint256 swapResult) {
    TransferHelper.safeTransfer(address(tokenIn), address(swapHandler), swapValue);
    swapResult = swapHandler.swapTokenToTokens(swapValue, slippage, tokenIn, tokenOut, to, isEnabled);
  }

  /**
   * @notice This function transfers the token to swap handler and makes the token to ETH (native BNB) swap happen
   */
  function transferAndSwapTokenToETH(
    address tokenIn,
    ISwapHandler swapHandler,
    uint256 swapValue,
    uint256 slippage,
    address to,
    bool isEnabled
  ) external returns (uint256 swapResult) {
    TransferHelper.safeTransfer(address(tokenIn), address(swapHandler), swapValue);
    swapResult = swapHandler.swapTokensToETH(swapValue, slippage, tokenIn, to, isEnabled);
  }

  /**
   * @notice This function calls the _pullFromVault() function of the IndexSwapLibrary
   */
  function pullFromVault(IExchange _exchange, address _token, uint256 _amount, address _to) external {
    _exchange._pullFromVault(_token, _amount, _to);
  }

  /**
   * @notice This function returns the token balance of the particular contract address
   * @param _token Token whose balance has to be found
   * @param _contract Address of the contract whose token balance is to be retrieved
   * @param _WETH Weth (native) token address
   * @return currentBalance Returns the current token balance of the passed contract address
   */
  function checkBalance(
    address _token,
    address _contract,
    address _WETH
  ) external view returns (uint256 currentBalance) {
    if (_token != _WETH) {
      currentBalance = IERC20Upgradeable(_token).balanceOf(_contract);
      // TransferHelper.safeApprove(_token, address(this), currentBalance);
    } else {
      currentBalance = _contract.balance;
    }
  }

  /**
     * @notice The function calculates the amount of index tokens the user can buy/mint with the invested amount.
     * @param _amount The invested amount after swapping ETH into portfolio tokens converted to USD to avoid 
                      slippage errors
     * @param sumPrice The total value in the vault converted to USD
     * @return Returns the amount of index tokens to be minted.
     */
  function _mintShareAmount(
    uint256 _amount,
    uint256 sumPrice,
    uint256 _indexTokenSupply
  ) external pure returns (uint256) {
    return (_amount * _indexTokenSupply) / sumPrice;
  }

  /**
   * @notice This function helps in multi-asset withdrawal from a portfolio
   */
  function withdrawMultiAssetORWithdrawToken(
    address _tokenRegistry,
    address _exchange,
    address _token,
    uint256 _tokenBalance
  ) external {
    if (_token == ITokenRegistry(_tokenRegistry).getETH()) {
      IExchange(_exchange)._pullFromVault(_token, _tokenBalance, address(this));
      IWETH(ITokenRegistry(_tokenRegistry).getETH()).withdraw(_tokenBalance);
      (bool success, ) = payable(msg.sender).call{value: _tokenBalance}("");
      if (!success) revert ErrorLibrary.ETHTransferFailed();
    } else {
      IExchange(_exchange)._pullFromVault(_token, _tokenBalance, msg.sender);
    }
  }

  /**
   * @notice This function puts some checks before an investment operation
   */
  function beforeInvestment(
    IIndexSwap _index,
    uint256 _slippageLength,
    uint256 _lpSlippageLength,
    address _to
  ) external {
    IAssetManagerConfig _assetManagerConfig = IAssetManagerConfig(_index.iAssetManagerConfig());
    address[] memory _tokens = _index.getTokens();
    if (!(_assetManagerConfig.publicPortfolio() || _assetManagerConfig.whitelistedUsers(_to))) {
      revert ErrorLibrary.UserNotAllowedToInvest();
    }
    if (ITokenRegistry(_index.tokenRegistry()).getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }
    if (_slippageLength != _tokens.length || _lpSlippageLength != _tokens.length) {
      revert ErrorLibrary.InvalidSlippageLength();
    }
    if (_tokens.length == 0) {
      revert ErrorLibrary.NotInitialized();
    }
  }

  /**
   * @notice This function pulls from the vault, sends the tokens to the handler and then redeems it via the handler
   */
  function _pullAndRedeem(
    IExchange _exchange,
    address _token,
    address _to,
    uint256 _amount,
    uint256 _lpSlippage,
    bool isPrimary,
    IHandler _handler
  ) internal {
    if (!isPrimary) {
      _exchange._pullFromVault(_token, _amount, address(_handler));
      _handler.redeem(
        FunctionParameters.RedeemData(_amount, _lpSlippage, _to, _token, _exchange.isWETH(_token, address(_handler)))
      );
    } else {
      _exchange._pullFromVault(_token, _amount, _to);
    }
  }

  /**
   * @notice This function returns the rate of the Index token based on the Vault  and token balance
   */
  function getIndexTokenRate(IIndexSwap _index) external returns (uint256) {
    (, uint256 totalVaultBalance) = getTokenAndVaultBalance(_index, _index.getTokens());
    uint256 _totalSupply = _index.totalSupply();
    if (_totalSupply > 0 && totalVaultBalance > 0) {
      return (totalVaultBalance * (10 ** 18)) / _totalSupply;
    }
    return 10 ** 18;
  }

  /**
   * @notice This function calculates the swap amount for off-chain operations
   */
  function calculateSwapAmountsOffChain(IIndexSwap _index, uint256 tokenAmount) external returns (uint256[] memory) {
    uint256 vaultBalance;
    address[] memory _tokens = _index.getTokens();
    uint256 len = _tokens.length;
    uint256[] memory amount = new uint256[](len);
    uint256[] memory tokenBalanceInUSD = new uint256[](len);
    (tokenBalanceInUSD, vaultBalance) = getTokenAndVaultBalance(_index, _tokens);
    if (_index.totalSupply() == 0) {
      for (uint256 i = 0; i < len; i++) {
        uint256 _denorm = _index.getRecord(_tokens[i]).denorm;
        amount[i] = (tokenAmount * _denorm) / 10_000;
      }
    } else {
      for (uint256 i = 0; i < len; i++) {
        uint256 balance = tokenBalanceInUSD[i];
        if (balance * tokenAmount < vaultBalance) revert ErrorLibrary.IncorrectInvestmentTokenAmount();
        amount[i] = (balance * tokenAmount) / vaultBalance;
      }
    }
    return (amount);
  }

  /**
   * @notice This function applies checks from the asset manager config and token registry side before redeeming
   */
  function beforeRedeemCheck(IIndexSwap _index, uint256 _tokenAmount, address _token, bool _status) external {
    if (_status) {
      revert ErrorLibrary.TokenAlreadyRedeemed();
    }
    if (_tokenAmount > _index.balanceOf(msg.sender)) {
      revert ErrorLibrary.CallerNotHavingGivenTokenAmount();
    }
    address registry = _index.tokenRegistry();
    if (ITokenRegistry(registry).getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }
    if (
      !IAssetManagerConfig(_index.iAssetManagerConfig()).isTokenPermitted(_token) &&
      _token != ITokenRegistry(registry).getETH()
    ) {
      revert ErrorLibrary.InvalidToken();
    }
  }

  /**
   * @notice This function applies checks before withdrawal
   */
  function beforeWithdrawCheck(
    uint256 _slippage,
    uint256 _lpSlippage,
    address token,
    address owner,
    IIndexSwap index,
    uint256 tokenAmount
  ) external {
    ITokenRegistry registry = ITokenRegistry(index.tokenRegistry());
    address[] memory _tokens = index.getTokens();
    if (registry.getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }

    if (!IAssetManagerConfig(index.iAssetManagerConfig()).isTokenPermitted(token) && token != registry.getETH()) {
      revert ErrorLibrary.InvalidToken();
    }

    if (tokenAmount > index.balanceOf(owner)) {
      revert ErrorLibrary.CallerNotHavingGivenTokenAmount();
    }
    if (_slippage != _tokens.length || _lpSlippage != _tokens.length) {
      revert ErrorLibrary.InvalidSlippageLength();
    }
  }

  /**
   * @notice This function checks if the investment value is correct or not
   */
  function _checkInvestmentValue(uint256 _tokenAmount, IAssetManagerConfig _assetManagerConfig) external view {
    uint256 max = _assetManagerConfig.MAX_INVESTMENTAMOUNT();
    uint256 min = _assetManagerConfig.MIN_INVESTMENTAMOUNT();
    if (!(_tokenAmount <= max && _tokenAmount >= min)) {
      revert ErrorLibrary.WrongInvestmentAmount({minInvestment: max, maxInvestment: min});
    }
  }

  /**
   * @notice This function adds sanity check to the fee value as well as the _to address
   */
  function mintAndBurnCheck(
    uint256 _fee,
    address _to,
    address _tokenRegistry,
    address _assetManagerConfig
  ) external returns (bool) {
    return (_fee > 0 &&
      !(_to == IAssetManagerConfig(_assetManagerConfig).assetManagerTreasury() ||
        _to == ITokenRegistry(_tokenRegistry).velvetTreasury()));
  }

  /**
   * @notice This function checks if the token is permitted or not and if the token balance is optimum or not
   */
  function _checkPermissionAndBalance(
    address _token,
    uint256 _tokenAmount,
    IAssetManagerConfig _config,
    address _to
  ) external {
    if (!_config.isTokenPermitted(_token)) {
      revert ErrorLibrary.InvalidToken();
    }
    if (IERC20Upgradeable(_token).balanceOf(_to) < _tokenAmount) {
      revert ErrorLibrary.LowBalance();
    }
  }

  /**
   * @notice This function takes care of the checks required before init of the index
   */
  function _beforeInitCheck(IIndexSwap index, address token, uint96 denorm) external {
    IAssetManagerConfig config = IAssetManagerConfig(index.iAssetManagerConfig());
    if ((config.whitelistTokens() && !config.whitelistedToken(token))) {
      revert ErrorLibrary.TokenNotWhitelisted();
    }
    if (denorm <= 0) {
      revert ErrorLibrary.InvalidDenorms();
    }
    if (token == address(0)) {
      revert ErrorLibrary.InvalidTokenAddress();
    }
    if (!(ITokenRegistry(index.tokenRegistry()).isEnabled(token))) {
      revert ErrorLibrary.TokenNotApproved();
    }
  }

  /**
   * @notice The function converts the given token amount into USD
   * @param t The base token being converted to USD
   * @param amount The amount to convert to USD
   * @return amountInUSD The converted USD amount
   */
  function _getTokenAmountInUSD(
    address _oracle,
    address t,
    uint256 amount
  ) external view returns (uint256 amountInUSD) {
    amountInUSD = IPriceOracle(_oracle).getPriceTokenUSD18Decimals(t, amount);
  }

  /**
   * @notice The function calculates the balance of a specific token in the vault
   * @return tokenBalance of the specific token
   */
  function getTokenBalance(IIndexSwap _index, address t) external view returns (uint256 tokenBalance) {
    IHandler handler = IHandler(ITokenRegistry(_index.tokenRegistry()).getTokenInformation(t).handler);
    tokenBalance = handler.getTokenBalance(_index.vault(), t);
  }

  /**
   * @notice This function checks if the token is primary and also if the external swap handler is valid
   */
  function checkPrimaryAndHandler(ITokenRegistry registry, address[] calldata tokens, address handler) external view {
    if (!(registry.isExternalSwapHandler(handler))) {
      revert ErrorLibrary.OffHandlerNotValid();
    }
    for (uint i = 0; i < tokens.length; i++) {
      if (!registry.getTokenInformation(tokens[i]).primary) {
        revert ErrorLibrary.NotPrimaryToken();
      }
    }
  }

  /**
   * @notice This function makes the necessary checks before an off-chain withdrawal
   */
  function beforeWithdrawOffChain(bool status, ITokenRegistry tokenRegistry, address handler) external {
    if (tokenRegistry.getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }

    if (!status) {
      revert ErrorLibrary.TokensNotRedeemed();
    }
    if (!(tokenRegistry.isExternalSwapHandler(handler))) {
      revert ErrorLibrary.OffHandlerNotValid();
    }
  }

  /**
   * @notice This function charges the fees from the index via the Fee Module
   */
  function chargeFees(IIndexSwap index, IFeeModule feeModule) external returns (uint256 vaultBalance) {
    (, vaultBalance) = getTokenAndVaultBalance(index, index.getTokens());
    feeModule.chargeFeesFromIndex(vaultBalance);
  }

  /**
   * @notice This function gets the underlying balances of the input token
   */
  function getUnderlyingBalances(
    address _token,
    IHandler _handler,
    address _contract
  ) external view returns (uint256[] memory) {
    address[] memory underlying = _handler.getUnderlying(_token);
    uint256[] memory balances = new uint256[](underlying.length);
    for (uint256 i = 0; i < underlying.length; i++) {
      balances[i] = IERC20Upgradeable(underlying[i]).balanceOf(_contract);
    }
    return balances;
  }

  /// @notice Calculate lockup cooldown applied to the investor after pool deposit
  /// @param _currentUserBalance Investor's current pool tokens balance
  /// @param _mintedLiquidity Liquidity to be minted to investor after pool deposit
  /// @param _currentCooldownTime New cooldown lockup time
  /// @param _oldCooldownTime Last cooldown lockup time applied to investor
  /// @param _lastDepositTimestamp Timestamp when last pool deposit happened
  /// @return cooldown New lockup cooldown to be applied to investor address
  function calculateCooldownPeriod(
    uint256 _currentUserBalance,
    uint256 _mintedLiquidity,
    uint256 _currentCooldownTime,
    uint256 _oldCooldownTime,
    uint256 _lastDepositTimestamp
  ) external view returns (uint256 cooldown) {
    // Get timestamp when current cooldown ends
    uint256 prevCooldownEnd = _lastDepositTimestamp + _oldCooldownTime;
    // Current exit remaining cooldown
    uint256 prevCooldownRemaining = prevCooldownEnd < block.timestamp ? 0 : prevCooldownEnd - block.timestamp;
    // If it's first deposit with zero liquidity, no cooldown should be applied
    if (_currentUserBalance == 0 && _mintedLiquidity == 0) {
      cooldown = 0;
      // If it's first deposit, new cooldown should be applied
    } else if (_currentUserBalance == 0) {
      cooldown = _currentCooldownTime;
      // If zero liquidity or new cooldown reduces remaining cooldown, apply remaining
    } else if (_mintedLiquidity == 0 || _currentCooldownTime < prevCooldownRemaining) {
      cooldown = prevCooldownRemaining;
      // For the rest cases calculate cooldown based on current balance and liquidity minted
    } else {
      // If the user already owns liquidity, the additional lockup should be in proportion to their existing liquidity.
      // Aggregate additional and remaining cooldowns
      uint256 balanceBeforeMint = _currentUserBalance - _mintedLiquidity;
      uint256 averageCooldown = (_mintedLiquidity * _currentCooldownTime + balanceBeforeMint * prevCooldownRemaining) /
        _currentUserBalance;
      // Resulting value is capped at new cooldown time (shouldn't be bigger) and falls back to one second in case of zero
      cooldown = averageCooldown > _currentCooldownTime ? _currentCooldownTime : averageCooldown != 0
        ? averageCooldown
        : 1;
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface IFeeModule {
  function chargeFeesFromIndex(uint256 _vaultBalance) external;

  function init(
    address _indexSwap,
    address _assetManagerConfig,
    address _tokenRegistry,
    address _accessController
  ) external;

  function chargeFees() external;

  function chargeEntryFee(uint256 _mintAmount, uint256 _fee) external returns (uint256);

  function chargeExitFee(uint256 _mintAmount, uint256 _fee) external returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library FunctionParameters {
  /**
   * @notice Struct having the init data for a new IndexFactory creation
   * @param _indexSwapLibrary Address of the base IndexSwapLibrary
   * @param _baseIndexSwapAddress Address of the base IndexSwap
   * @param _baseRebalancingAddres Address of the base Rebalancing module
   * @param _baseOffChainRebalancingAddress Address of the base Offchain-Rebalance module
   * @param _baseRebalanceAggregatorAddress Address of the base Rebalance Aggregator module
   * @param _baseExchangeHandlerAddress Address of the base Exchange Handler
   * @param _baseAssetManagerConfigAddress Address of the baes AssetManager Config address
   * @param _baseOffChainIndexSwapAddress Address of the base Offchain-IndexSwap module
   * @param _feeModuleImplementationAddress Address of the base Fee Module implementation
   * @param _baseVelvetGnosisSafeModuleAddress Address of the base Gnosis-Safe module
   * @param _gnosisSingleton Address of the Gnosis Singleton
   * @param _gnosisFallbackLibrary Address of the Gnosis Fallback Library
   * @param _gnosisMultisendLibrary Address of the Gnosis Multisend Library
   * @param _gnosisSafeProxyFactory Address of the Gnosis Safe Proxy Factory
   * @param _priceOracle Address of the base Price Oracle to be used
   * @param _tokenRegistry Address of the Token Registry to be used
   * @param _velvetProtocolFee Fee cut that is being charged (eg: 25% of the fees)
   */
  struct IndexFactoryInitData {
    address _indexSwapLibrary;
    address _baseIndexSwapAddress;
    address _baseRebalancingAddres;
    address _baseOffChainRebalancingAddress;
    address _baseRebalanceAggregatorAddress;
    address _baseExchangeHandlerAddress;
    address _baseAssetManagerConfigAddress;
    address _baseOffChainIndexSwapAddress;
    address _feeModuleImplementationAddress;
    address _baseVelvetGnosisSafeModuleAddress;
    address _gnosisSingleton;
    address _gnosisFallbackLibrary;
    address _gnosisMultisendLibrary;
    address _gnosisSafeProxyFactory;
    address _priceOracle;
    address _tokenRegistry;
  }

  /**
   * @notice Data passed from the Factory for the init of IndexSwap module
   * @param _name Name of the Index Fund
   * @param _symbol Symbol to represent the Index Fund
   * @param _vault Address of the Vault associated with that Index Fund
   * @param _module Address of the Safe module  associated with that Index Fund
   * @param _oracle Address of the Price Oracle associated with that Index Fund
   * @param _accessController Address of the Access Controller associated with that Index Fund
   * @param _tokenRegistry Address of the Token Registry associated with that Index Fund
   * @param _exchange Address of the Exchange Handler associated with that Index Fund
   * @param _iAssetManagerConfig Address of the Asset Manager Config associated with that Index Fund
   * @param _feeModule Address of the Fee Module associated with that Index Fund
   */
  struct IndexSwapInitData {
    string _name;
    string _symbol;
    address _vault;
    address _module;
    address _oracle;
    address _accessController;
    address _tokenRegistry;
    address _exchange;
    address _iAssetManagerConfig;
    address _feeModule;
  }

  /**
   * @notice Struct used to pass data when a Token is swapped to ETH (native token) using the swap handler
   * @param _token Address of the token being swapped
   * @param _to Receiver address that is receiving the swapped result
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _swapAmount Amount of tokens to be swapped
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   */
  struct SwapTokenToETHData {
    address _token;
    address _to;
    address _swapHandler;
    uint256 _swapAmount;
    uint256 _slippage;
    uint256 _lpSlippage;
  }

  /**
   * @notice Struct used to pass data when ETH (native token) is swapped to some other Token using the swap handler
   * @param _token Address of the token being swapped to
   * @param _to Receiver address that will receive the swapped tokens
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   * @param _swapAmount Amount of tokens that is to be swapped
   */
  struct SwapETHToTokenData {
    address _token;
    address _to;
    address _swapHandler;
    address _toUser;
    uint256 _slippage;
    uint256 _lpSlippage;
    uint256 _swapAmount;
  }

  /**
   * @notice Struct used to pass data when ETH (native token) is swapped to some other Token using the swap handler
   * @param _token Address of the token being swapped to
   * @param _to Receiver address that will receive the swapped tokens
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   */
  struct SwapETHToTokenPublicData {
    address _token;
    address _to;
    address _swapHandler;
    address _toUser;
    uint256 _slippage;
    uint256 _lpSlippage;
  }

  /**
   * @notice Struct used to pass data when a Token is swapped to another token using the swap handler
   * @param _tokenIn Address of the token being swapped from
   * @param _tokenOut Address of the token being swapped to
   * @param _to Receiver address that will receive the swapped tokens
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _swapAmount Amount of tokens that is to be swapped
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   * @param _isInvesting Boolean parameter indicating if the swap is being done during investment or withdrawal
   */
  struct SwapTokenToTokenData {
    address _tokenIn;
    address _tokenOut;
    address _to;
    address _swapHandler;
    address _toUser;
    uint256 _swapAmount;
    uint256 _slippage;
    uint256 _lpSlippage;
    bool _isInvesting;
  }

  /**
   * @notice Struct having data for the swap of one token to another based on the input
   * @param _index Address of the IndexSwap associated with the swap tokens
   * @param _inputToken Address of the token being swapped from
   * @param _swapHandler Address of the swap handler being used
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _tokenAmount Investment amount that is being distributed into all the portfolio tokens
   * @param _totalSupply Total supply of the Index tokens
   * @param amount The swap amount (in case totalSupply != 0) value calculated from the IndexSwapLibrary
   * @param _slippage Slippage for providing the liquidity
   * @param _lpSlippage LP Slippage for providing the liquidity
   */
  struct SwapTokenToTokensData {
    address _index;
    address _inputToken;
    address _swapHandler;
    address _toUser;
    uint256 _tokenAmount;
    uint256 _totalSupply;
    uint256[] amount;
    uint256[] _slippage;
    uint256[] _lpSlippage;
  }

  /**
   * @notice Struct having the Offchain Investment data used for multiple functions
   * @param _offChainHandler Address of the off-chain handler being used
   * @param _buyAmount Array of amounts representing the distribution to all portfolio tokens; sum of this amount is the total investment amount
   * @param _buySwapData Array including the calldata which is required for the external swap handlers to swap ("buy") the portfolio tokens
   */
  struct ZeroExData {
    address _offChainHandler;
    uint256[] _buyAmount;
    bytes[] _buySwapData;
  }

  /**
   * @notice Struct having the init data for a new Index Fund creation using the Factory
   * @param _assetManagerTreasury Address of the Asset Manager Treasury to be associated with the fund
   * @param _whitelistedTokens Array of tokens which limits the use of only those addresses as portfolio tokens in the fund
   * @param maxIndexInvestmentAmount Maximum Investment amount for the fund
   * @param maxIndexInvestmentAmount Minimum Investment amount for the fund
   * @param _managementFee Management fee (streaming fee) that the asset manager will receive for managing the fund
   * @param _performanceFee Fee that the asset manager will receive for managing the fund and if the portfolio performance well
   * @param _entryFee Entry fee for investing into the fund
   * @param _exitFee Exit fee for withdrawal from the fund
   * @param _public Boolean parameter for is the fund eligible for public investment or only some whitelist users can invest
   * @param _transferable Boolean parameter for is the Index tokens from the fund transferable or not
   * @param _transferableToPublic Boolean parameter for is the Index tokens from the fund transferable to public or only to whitelisted users
   * @param _whitelistTokens Boolean parameter which specifies if the asset manager can only choose portfolio tokens from the whitelisted array or not
   * @param name Name of the fund
   * @param symbol Symbol associated with the fund
   */
  struct IndexCreationInitData {
    address _assetManagerTreasury;
    address[] _whitelistedTokens;
    uint256 maxIndexInvestmentAmount;
    uint256 minIndexInvestmentAmount;
    uint256 _managementFee;
    uint256 _performanceFee;
    uint256 _entryFee;
    uint256 _exitFee;
    bool _public;
    bool _transferable;
    bool _transferableToPublic;
    bool _whitelistTokens;
    string name;
    string symbol;
  }

  /**
   * @notice Struct having data for the Enable Rebalance (1st transaction) during ZeroEx's `Update Weight` call
   * @param _lpSlippage Array of LP Slippage values passed to the function
   * @param _newWeights Array of new weights for the rebalance
   */
  struct EnableRebalanceData {
    uint256[] _lpSlippage;
    uint96[] _newWeights;
  }

  /**
   * @notice Struct having data for the init of Asset Manager Config
   * @param _managementFee Management fee (streaming fee) that the asset manager will receive for managing the fund
   * @param _performanceFee Fee that the asset manager will receive for managing the fund and if the portfolio performance well
   * @param _entryFee Entry fee associated with the config
   * @param _exitFee Exit fee associated with the config
   * @param _minInvestmentAmount Minimum investment amount specified as per the config
   * @param _maxInvestmentAmount Maximum investment amount specified as per the config
   * @param _tokenRegistry Address of the Token Registry associated with the config
   * @param _accessController Address of the Access Controller associated with the config
   * @param _assetManagerTreasury Address of the Asset Manager Treasury account
   * @param _whitelistTokens Boolean parameter which specifies if the asset manager can only choose portfolio tokens from the whitelisted array or not
   * @param _publicPortfolio Boolean parameter for is the portfolio eligible for public investment or not
   * @param _transferable Boolean parameter for is the Index tokens from the fund transferable to public or not
   * @param _transferableToPublic Boolean parameter for is the Index tokens from the fund transferable to public or not
   * @param _whitelistTokens Boolean parameter for is the token whitelisting enabled for the fund or not
   */
  struct AssetManagerConfigInitData {
    uint256 _managementFee;
    uint256 _performanceFee;
    uint256 _entryFee;
    uint256 _exitFee;
    uint256 _minInvestmentAmount;
    uint256 _maxInvestmentAmount;
    address _tokenRegistry;
    address _accessController;
    address _assetManagerTreasury;
    address[] _whitelistedTokens;
    bool _publicPortfolio;
    bool _transferable;
    bool _transferableToPublic;
    bool _whitelistTokens;
  }

  /**
   * @notice Struct with data passed during the withdrawal from the Index Fund
   * @param _slippage Array of Slippage values passed for the withdrawal
   * @param _lpSlippage Array of LP Slippage values passed for the withdrawal
   * @param tokenAmount Amount of the Index Tokens that is to be withdrawn
   * @param _swapHandler Address of the swap handler being used for the withdrawal process
   * @param _token Address of the token being withdrawn to (must be a primary token)
   * @param isMultiAsset Boolean parameter for is the withdrawal being done in portfolio tokens (multi-token) or in the native token
   */
  struct WithdrawFund {
    uint256[] _slippage;
    uint256[] _lpSlippage;
    uint256 tokenAmount;
    address _swapHandler;
    address _token;
    bool isMultiAsset;
  }

  /**
   * @notice Struct with data passed during the investment into the Index Fund
   * @param _slippage Array of Slippage values passed for the investment
   * @param _lpSlippage Array of LP Slippage values passed for the deposit into LP protocols
   * @param _tokenAmount Amount of token being invested
   * @param _to Address that would receive the index tokens post successful investment
   * @param _swapHandler Address of the swap handler being used for the investment process
   * @param _token Address of the token being made investment in
   */
  struct InvestFund {
    uint256[] _slippage;
    uint256[] _lpSlippage;
    uint256 _tokenAmount;
    address _swapHandler;
    address _token;
  }

  /**
   * @notice Struct passed with values for the updation of tokens via the Rebalancing module
   * @param tokens Array of the new tokens that is to be updated to 
   * @param _swapHandler Address of the swap handler being used for the token update
   * @param denorms Denorms of the new tokens
   * @param _slippageSell Slippage allowed for the sale of tokens
   * @param _slippageBuy Slippage allowed for the purchase of tokens
   * @param _lpSlippageSell LP Slippage allowed for the sale of tokens
   * @param _lpSlippageBuy LP Slippage allowed for the purchase of tokens
   */
  struct UpdateTokens {
    address[] tokens;
    address _swapHandler;
    uint96[] denorms;
    uint256[] _slippageSell;
    uint256[] _slippageBuy;
    uint256[] _lpSlippageSell;
    uint256[] _lpSlippageBuy;
  }

  /**
   * @notice Struct having data for the redeem of tokens using the handlers for different protocols
   * @param _amount Amount of protocol tokens to be redeemed using the handler
   * @param _lpSlippage LP Slippage allowed for the redeem process
   * @param _to Address that would receive the redeemed tokens
   * @param _yieldAsset Address of the protocol token that is being redeemed against
   * @param isWETH Boolean parameter for is the redeem being done for WETH (native token) or not
   */
  struct RedeemData {
    uint256 _amount;
    uint256 _lpSlippage;
    address _to;
    address _yieldAsset;
    bool isWETH;
  }

  /**
   * @notice Struct having data for the setup of different roles during an Index Fund creation
   * @param _exchangeHandler Addresss of the Exchange handler for the fund
   * @param _index Address of the IndexSwap for the fund
   * @param _tokenRegistry Address of the Token Registry for the fund
   * @param _portfolioCreator Address of the account creating/deploying the portfolio
   * @param _rebalancing Address of the Rebalancing module for the fund
   * @param _offChainRebalancing Address of the Offchain-Rebalancing module for the fund
   * @param _rebalanceAggregator Address of the Rebalance Aggregator for the fund
   * @param _feeModule Address of the Fee Module for the fund
   * @param _offChainIndexSwap Address of the OffChain-IndexSwap for the fund
   */
  struct AccessSetup {
    address _exchangeHandler;
    address _index;
    address _tokenRegistry;
    address _portfolioCreator;
    address _rebalancing;
    address _offChainRebalancing;
    address _rebalanceAggregator;
    address _feeModule;
    address _offChainIndexSwap;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IHandler} from "./../../IHandler.sol";
import {IIndexSwap} from "./../../../core/IIndexSwap.sol";

contract ExchangeData {
  /**
   * @notice Struct having data for the swap and deposit using the Meta Aggregator
   * @param sellAmount Amount of token being swapped
   * @param _lpSlippage LP Slippage value allowed for the swap
   * @param sellTokenAddress Address of the token being swapped from
   * @param buyTokenAddress Address of the token being swapped to
   * @param swapHandler Address of the swaphandler being used for the swap
   * @param portfolioToken Portfolio token for the deposit
   * @param callData Encoded data associated with the swap
   */
  struct ExSwapData {
    uint256[] sellAmount;
    uint256 _lpSlippage;
    address[] sellTokenAddress;
    address[] buyTokenAddress;
    address swapHandler;
    address portfolioToken;
    bytes[] callData;
  }

  /**
   * @notice Struct having data for the offchain investment values
   * @param buyAmount Amount to be invested
   * @param _buyToken Address of the token to be invested in
   * @param sellTokenAddress Address of the token in which the investment is being made
   * @param offChainHandler Address of the offchain handler being used
   * @param _buySwapData Encoded data for the investment
   */
  struct ZeroExData {
    uint256[] buyAmount;
    address[] _buyToken;
    address sellTokenAddress;
    address _offChainHandler;
    bytes[] _buySwapData;
  }

  /**
   * @notice Struct having data for the offchain withdrawal values
   * @param sellAmount Amount of token to be withd
   * @param sellTokenAddress Address of the token being swapped from
   * @param offChainHandler Address of the offchain handler being used
   * @param buySwapData Encoded data for the withdrawal
   */
  struct ZeroExWithdraw {
    uint256[] sellAmount;
    address[] sellTokenAddress;
    address offChainHandler;
    bytes[] buySwapData;
  }

  /**
   * @notice Struct having data for pulling tokens and redeeming during withdrawal
   * @param tokenAmount Amount of token to be pulled and redeemed
   * @param _lpSlippage LP Slippage amount allowed for the operation
   * @param token Address of the token being pulled and redeemed
   */
  struct RedeemData {
    uint256 tokenAmount;
    uint256[] _lpSlippage;
    address token;
  }

  /**
   * @notice Struct having data for `IndexOperationsData` struct and also other functions like `SwapAndCalculate`
   * @param buyAmount Amount of the token to be purchased
   * @param sellTokenAddress Address of the token being swapped from
   * @param _offChainHanlder Address of the offchain handler being used
   * @param _buySwapData Encoded data for the swap
   */
  struct InputData {
    uint256[] buyAmount;
    address sellTokenAddress;
    address _offChainHandler;
    bytes[] _buySwapData;
  }

  /**
   * @notice Struct having data for the `swapOffChainTokens` function from the Exchange handler
   * @param inputData Struct having different input params
   * @param index IndexSwap instance of the current fund
   * @param indexValue Value of the IndexSwap whose inforamtion has to be obtained
   * @param balance Token balance passed during the offchain swap
   * @param _lpSlippage Amount of LP Slippage allowed for the swap
   * @param _buyAmount Amount of token being swapped to
   * @param _token Portoflio token to be invested in
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   */
  struct IndexOperationData {
    ExchangeData.InputData inputData;
    IIndexSwap index;
    uint256 indexValue;
    uint256 _lpSlippage;
    uint256 _buyAmount;
    address _token;
    address _toUser;
  }

  /**
   * @notice Struct having data for the offchain withdrawal
   * @param sellAmount Amount of token being withdrawn
   * @param userAmount Amount of sell token that the user is holding
   * @param sellTokenAddress Address of the token being swapped from
   * @param offChainHandler Address of the offchain handler being used
   * @param buyToken Address of the token being swapped to
   * @param swapData Enocoded swap data for the withdraw
   */
  struct withdrawData {
    uint256 sellAmount;
    uint256 userAmount;
    address sellTokenAddress;
    address offChainHandler;
    address buyToken;
    bytes swapData;
  }

  /**
   * @notice Struct having data for the swap of tokens using the offchain handler
   * @param sellAmount Amount of token being swapped
   * @param sellTokenAddress Address of the token being swapped from
   * @param buyTokenAddress Address of the token being swapped to
   * @param swapHandler Address of the offchain swaphandler being used
   * @param callData Encoded calldata for the swap
   */
  struct MetaSwapData {
    uint256 sellAmount;
    address sellTokenAddress;
    address buyTokenAddress;
    address swapHandler;
    bytes callData;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {ExchangeData} from "../handler/ExternalSwapHandler/Helper/ExchangeData.sol";

interface IExternalSwapHandler {
  function swap(
    address sellTokenAddress,
    address buyTokenAddress,
    uint sellAmount,
    bytes memory callData,
    address _to
  ) external payable;

  function setAllowance(address _token, address _spender, uint _sellAmount) external;
}

// SPDX-License-Identifier: BUSL-1.1

// lend token
// redeem token
// claim token
// get token balance
// get underlying balance

pragma solidity 0.8.16;

import {FunctionParameters} from "../FunctionParameters.sol";

interface IHandler {
  function deposit(address, uint256[] memory, uint256, address, address) external payable returns (uint256);

  function redeem(FunctionParameters.RedeemData calldata inputData) external;

  function getTokenBalance(address, address) external view returns (uint256);

  function getUnderlyingBalance(address, address) external returns (uint256[] memory);

  function getUnderlying(address) external view returns (address[] memory);

  function getRouterAddress() external view returns (address);

  function encodeData(address t, uint256 _amount) external returns (bytes memory);

  function getClaimTokenCalldata(address _alpacaToken, address _holder) external returns (bytes memory, address);

  function getTokenBalanceUSD(address _tokenHolder, address t) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

interface ISwapHandler {
  function getETH() external view returns (address);

  function getSwapAddress(uint256 _swapAmount, address _t) external view returns (address);

  function swapTokensToETH(uint256 _swapAmount, uint256 _slippage, address _t, address _to, bool isEnabled) external returns (uint256);

  function swapETHToTokens(uint256 _slippage, address _t, address _to) external payable returns (uint256);

  function swapTokenToTokens(
    uint256 _swapAmount,
    uint256 _slippage,
    address _tokenIn,
    address _tokenOut,
    address _to,
    bool isEnabled
  ) external returns (uint256 swapResult);

  function getPathForETH(address crypto) external view returns (address[] memory);

  function getPathForToken(address token) external view returns (address[] memory);

  function getSlippage(
    uint256 _amount,
    uint256 _slippage,
    address[] memory path
  ) external view returns (uint256 minAmount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

/**
 * @title ErrorLibrary
 * @author Velvet.Capital
 * @notice This is a library contract including custom defined errors
 */

library ErrorLibrary {
  error ContractPaused();
  /// @notice Thrown when caller is not rebalancer contract
  error CallerNotRebalancerContract();
  /// @notice Thrown when caller is not asset manager
  error CallerNotAssetManager();
  /// @notice Thrown when caller is not asset manager
  error CallerNotSuperAdmin();
  /// @notice Thrown when caller is not whitelist manager
  error CallerNotWhitelistManager();
  /// @notice Thrown when length of slippage array is not equal to tokens array
  error InvalidSlippageLength();
  /// @notice Thrown when length of tokens array is zero
  error InvalidLength();
  /// @notice Thrown when token is not permitted
  error TokenNotPermitted();
  /// @notice Thrown when user is not allowed to invest
  error UserNotAllowedToInvest();
  /// @notice Thrown when index token in not initialized
  error NotInitialized();
  /// @notice Thrown when investment amount is greater than or less than the set range
  error WrongInvestmentAmount(uint256 minInvestment, uint256 maxInvestment);
  /// @notice Thrown when swap amount is greater than BNB balance of the contract
  error NotEnoughBNB();
  /// @notice Thrown when the total sum of weights is not equal to 10000
  error InvalidWeights(uint256 totalWeight);
  /// @notice Thrown when balance is below set velvet min investment amount
  error BalanceCantBeBelowVelvetMinInvestAmount(uint256 minVelvetInvestment);
  /// @notice Thrown when caller is not holding underlying token amount being swapped
  error CallerNotHavingGivenTokenAmount();
  /// @notice Thrown when length of denorms array is not equal to tokens array
  error InvalidInitInput();
  /// @notice Thrown when the tokens are already initialized
  error AlreadyInitialized();
  /// @notice Thrown when the token is not whitelisted
  error TokenNotWhitelisted();
  /// @notice Thrown when denorms array length is zero
  error InvalidDenorms();
  /// @notice Thrown when token address being passed is zero
  error InvalidTokenAddress();
  /// @notice Thrown when token is not permitted
  error InvalidToken();
  /// @notice Thrown when token is not approved
  error TokenNotApproved();
  /// @notice Thrown when transfer is prohibited
  error Transferprohibited();
  /// @notice Thrown when transaction caller balance is below than token amount being invested
  error LowBalance();
  /// @notice Thrown when address is already approved
  error AddressAlreadyApproved();
  /// @notice Thrown when swap handler is not enabled inside token registry
  error SwapHandlerNotEnabled();
  /// @notice Thrown when swap amount is zero
  error ZeroBalanceAmount();
  /// @notice Thrown when caller is not index manager
  error CallerNotIndexManager();
  /// @notice Thrown when caller is not fee module contract
  error CallerNotFeeModule();
  /// @notice Thrown when lp balance is zero
  error LpBalanceZero();
  /// @notice Thrown when desired swap amount is greater than token balance of this contract
  error InvalidAmount();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInAlpacaProtocol();
  /// @notice Thrown when the mint amount is not equal to token amount passed
  error MintAmountMustBeEqualToValue();
  /// @notice Thrown when the mint function returned 0 for success & 1 for failure
  error MintProcessFailed();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInApeSwap();
  /// @notice Thrown when the redeeming was success(0) or failure(1)
  error RedeemingCTokenFailed();
  /// @notice Thrown when native BNB is sent for any vault other than mooVenusBNB
  error PleaseDepositUnderlyingToken();
  /// @notice Thrown when redeem amount is greater than tokenBalance of protocol
  error NotEnoughBalanceInBeefyProtocol();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInBeefy();
  /// @notice Thrown when the deposit amount of underlying token A is more than contract balance
  error InsufficientTokenABalance();
  /// @notice Thrown when the deposit amount of underlying token B is more than contract balance
  error InsufficientTokenBBalance();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInBiSwapProtocol();
  //Not enough funds
  error InsufficientFunds(uint256 available, uint256 required);
  //Not enough eth for protocol fee
  error InsufficientFeeFunds(uint256 available, uint256 required);
  //Order success but amount 0
  error ZeroTokensSwapped();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInLiqeeProtocol();
  /// @notice Thrown when the mint amount is not equal to token amount passed
  error MintAmountMustBeEqualToValuePassed();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInPancakeProtocol();
  /// @notice Thrown when Pid passed is not equal to Pid stored in Pid map
  error InvalidPID();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error InsufficientBalance();
  /// @notice Thrown when the redeem function returns 1 for fail & 0 for success
  error RedeemingFailed();
  /// @notice Thrown when the token passed in getUnderlying is not cToken
  error NotcToken();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInWombatProtocol();
  /// @notice Thrown when the mint amount is not equal to token amount passed
  error MintAmountNotEqualToPassedValue();
  /// @notice Thrown when slippage value passed is greater than 100
  error SlippageCannotBeGreaterThan100();
  /// @notice Thrown when tokens are already staked
  error TokensStaked();
  /// @notice Thrown when contract is not paused
  error ContractNotPaused();
  /// @notice Thrown when offchain handler is not valid
  error OffHandlerNotValid();
  /// @notice Thrown when offchain handler is not enabled
  error OffHandlerNotEnabled();
  /// @notice Thrown when swapHandler is not enabled
  error SwaphandlerNotEnabled();
  /// @notice Thrown when account other than asset manager calls
  error OnlyAssetManagerCanCall();
  /// @notice Thrown when already redeemed
  error AlreadyRedeemed();
  /// @notice Thrown when contract is not paused
  error NotPaused();
  /// @notice Thrown when token is not index token
  error TokenNotIndexToken();
  /// @notice Thrown when swaphandler is invalid
  error SwapHandlerNotValid();
  /// @notice Thrown when token that will be bought is invalid
  error BuyTokenAddressNotValid();
  /// @notice Thrown when not redeemed
  error NotRedeemed();
  /// @notice Thrown when caller is not asset manager
  error CallerIsNotAssetManager();
  /// @notice Thrown when account other than asset manager is trying to pause
  error OnlyAssetManagerCanCallUnpause();
  /// @notice Thrown when trying to redeem token that is not staked
  error TokensNotStaked();
  /// @notice Thrown when account other than asset manager is trying to revert or unpause
  error FifteenMinutesNotExcedeed();
  /// @notice Thrown when swapping weight is zero
  error WeightNotGreaterThan0();
  /// @notice Thrown when dividing by zero
  error DivBy0Sumweight();
  /// @notice Thrown when lengths of array are not equal
  error LengthsDontMatch();
  /// @notice Thrown when contract is not paused
  error ContractIsNotPaused();
  /// @notice Thrown when set time period is not over
  error TimePeriodNotOver();
  /// @notice Thrown when trying to set any fee greater than max allowed fee
  error InvalidFee();
  /// @notice Thrown when zero address is passed for treasury
  error ZeroAddressTreasury();
  /// @notice Thrown when assetManagerFee or performaceFee is set zero
  error ZeroFee();
  /// @notice Thrown when trying to enable an already enabled handler
  error HandlerAlreadyEnabled();
  /// @notice Thrown when trying to disable an already disabled handler
  error HandlerAlreadyDisabled();
  /// @notice Thrown when zero is passed as address for oracle address
  error InvalidOracleAddress();
  /// @notice Thrown when zero is passed as address for handler address
  error InvalidHandlerAddress();
  /// @notice Thrown when token is not in price oracle
  error TokenNotInPriceOracle();
  /// @notice Thrown when address is not approved
  error AddressNotApproved();
  /// @notice Thrown when minInvest amount passed is less than minInvest amount set
  error InvalidMinInvestmentAmount();
  /// @notice Thrown when maxInvest amount passed is greater than minInvest amount set
  error InvalidMaxInvestmentAmount();
  /// @notice Thrown when zero address is being passed
  error InvalidAddress();
  /// @notice Thrown when caller is not the owner
  error CallerNotOwner();
  /// @notice Thrown when out asset address is zero
  error InvalidOutAsset();
  /// @notice Thrown when protocol is not paused
  error ProtocolNotPaused();
  /// @notice Thrown when protocol is paused
  error ProtocolIsPaused();
  /// @notice Thrown when proxy implementation is wrong
  error ImplementationNotCorrect();
  /// @notice Thrown when caller is not offChain contract
  error CallerNotOffChainContract();
  /// @notice Thrown when user has already redeemed tokens
  error TokenAlreadyRedeemed();
  /// @notice Thrown when user has not redeemed tokens
  error TokensNotRedeemed();
  /// @notice Thrown when user has entered wrong amount
  error InvalidSellAmount();
  /// @notice Thrown when trasnfer fails
  error WithdrawTransferFailed();
  /// @notice Thrown when caller is not having minter role
  error CallerNotMinter();
  /// @notice Thrown when caller is not handler contract
  error CallerNotHandlerContract();
  /// @notice Thrown when token is not enabled
  error TokenNotEnabled();
  /// @notice Thrown when index creation is paused
  error IndexCreationIsPause();
  /// @notice Thrown denorm value sent is zero
  error ZeroDenormValue();
  /// @notice Thrown when asset manager is trying to input token which already exist
  error TokenAlreadyExist();
  /// @notice Thrown when cool down period is not passed
  error CoolDownPeriodNotPassed();
  /// @notice Thrown When Buy And Sell Token Are Same
  error BuyAndSellTokenAreSame();
  /// @notice Throws arrow when token is not a reward token
  error NotRewardToken();
  /// @notice Throws arrow when MetaAggregator Swap Failed
  error SwapFailed();
  /// @notice Throws arrow when Token is Not  Primary
  error NotPrimaryToken();
  /// @notice Throws when the setup is failed in gnosis
  error ModuleNotInitialised();
  /// @notice Throws when threshold is more than owner length
  error InvalidThresholdLength();
  /// @notice Throws when no owner address is passed while fund creation
  error NoOwnerPassed();
  /// @notice Throws when length of underlying token is greater than 1
  error InvalidTokenLength();
  /// @notice Throws when already an operation is taking place and another operation is called
  error AlreadyOngoingOperation();
  /// @notice Throws when wrong function is executed for revert offchain fund
  error InvalidExecution();
  /// @notice Throws when Final value after investment is zero
  error ZeroFinalInvestmentValue();
  /// @notice Throws when token amount after swap / token amount to be minted comes out as zero
  error ZeroTokenAmount();
  /// @notice Throws eth transfer failed
  error ETHTransferFailed();
  /// @notice Thorws when the caller does not have a default admin role
  error CallerNotAdmin();
  /// @notice Throws when buyAmount is not correct in offchainIndexSwap
  error InvalidBuyValues();
  /// @notice Throws when token is not primary
  error TokenNotPrimary();
  /// @notice Throws when tokenOut during withdraw is not permitted in the asset manager config
  error _tokenOutNotPermitted();
  /// @notice Throws when token balance is too small to be included in index
  error BalanceTooSmall();
  /// @notice Throws when a public fund is tried to made transferable only to whitelisted addresses
  error PublicFundToWhitelistedNotAllowed();
  /// @notice Throws when list input by user is invalid (meta aggregator)
  error InvalidInputTokenList();
  /// @notice Generic call failed error
  error CallFailed();
  /// @notice Generic transfer failed error
  error TransferFailed();
  /// @notice Throws when handler underlying token is not ETH
  error TokenNotETH();  
   /// @notice Thrown when the token passed in getUnderlying is not vToken
  error NotVToken();
  /// @notice Throws when incorrect token amount is encountered during offchain/onchain investment
  error IncorrectInvestmentTokenAmount();
  /// @notice Throws when final invested amount after slippage is 0
  error ZeroInvestedAmountAfterSlippage();
  /// @notice Throws when the slippage trying to be set is in incorrect range
  error IncorrectSlippageRange();
  /// @notice Throws when invalid LP slippage is passed
  error InvalidLPSlippage();
  /// @notice Throws when invalid slippage for swapping is passed
  error InvalidSlippage();
  /// @notice Throws when msg.value is less than the amount passed into the handler
  error WrongNativeValuePassed();
  /// @notice Throws when there is an overflow during muldiv full math operation
  error FULLDIV_OVERFLOW();
  /// @notice Throws when the oracle price is not updated under set timeout
  error PriceOracleExpired();
  /// @notice Throws when the oracle price is returned 0
  error PriceOracleInvalid();
  /// @notice Throws when the initToken or updateTokenList function of IndexSwap is having more tokens than set by the Registry
  error TokenCountOutOfLimit(uint256 limit);
  /// @notice Throws when the array lenghts don't match for adding price feed or enabling tokens
  error IncorrectArrayLength();
  /// @notice Common Reentrancy error for IndexSwap and IndexSwapOffChain
  error ReentrancyGuardReentrantCall();
  /// @notice Throws when user calls updateFees function before proposing a new fee
  error NoNewFeeSet();
  /// @notice Throws when wrong asset is supplied to the Compound v3 Protocol
  error WrongAssetBeingSupplied();
  /// @notice Throws when wrong asset is being withdrawn from the Compound v3 Protocol
  error WrongAssetBeingWithdrawn();
  /// @notice Throws when sequencer is down
  error SequencerIsDown();
  /// @notice Throws when sequencer threshold is not crossed
  error SequencerThresholdNotCrossed();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

interface IPriceOracle {
  function WETH() external returns(address);

  function _addFeed(address base, address quote, AggregatorV2V3Interface aggregator) external;

  function decimals(address base, address quote) external view returns (uint8);

  function latestRoundData(address base, address quote) external view returns (int256);

  function getUsdEthPrice(uint256 amountIn) external view returns (uint256 amountOut);

  function getEthUsdPrice(uint256 amountIn) external view returns (uint256 amountOut);

  function getPrice(address base, address quote) external view returns (int256);

  function getPriceForAmount(address token, uint256 amount, bool ethPath) external view returns (uint256 amountOut);

  function getPriceForTokenAmount(
    address tokenIn,
    address tokenOut,
    uint256 amount
  ) external view returns (uint256 amountOut);

  function getPriceTokenUSD18Decimals(address _base, uint256 amountIn) external view returns (uint256 amountOut);

  function getPriceForOneTokenInUSD(address _base) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {FunctionParameters} from "../FunctionParameters.sol";

interface IAssetManagerConfig {
  function init(FunctionParameters.AssetManagerConfigInitData calldata initData) external;

  function managementFee() external view returns (uint256);

  function performanceFee() external view returns (uint256);

  function entryFee() external view returns (uint256);

  function exitFee() external view returns (uint256);

  function MAX_INVESTMENTAMOUNT() external view returns (uint256);

  function MIN_INVESTMENTAMOUNT() external view returns (uint256);

  function assetManagerTreasury() external returns (address);

  function whitelistedToken(address) external returns (bool);

  function whitelistedUsers(address) external returns (bool);

  function publicPortfolio() external returns (bool);

  function transferable() external returns (bool);

  function transferableToPublic() external returns (bool);

  function whitelistTokens() external returns (bool);

  function setPermittedTokens(address[] calldata _newTokens) external;

  function deletePermittedTokens(address[] calldata _newTokens) external;

  function isTokenPermitted(address _token) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface ITokenRegistry {
  struct TokenRecord {
    bool primary;
    bool enabled;
    address handler;
    address[] rewardTokens;
  }

  function enableToken(address _oracle, address _token) external;

  function isEnabled(address _token) external view returns (bool);

  function isSwapHandlerEnabled(address swapHandler) external view returns (bool);

  function isOffChainHandlerEnabled(address offChainHandler) external view returns (bool);

  function disableToken(address _token) external;

  function checkNonDerivative(address handler) external view returns (bool);

  function getTokenInformation(address) external view returns (TokenRecord memory);

  function enableExternalSwapHandler(address swapHandler) external;

  function disableExternalSwapHandler(address swapHandler) external;

  function isExternalSwapHandler(address swapHandler) external view returns (bool);

  function isRewardToken(address) external view returns (bool);

  function velvetTreasury() external returns (address);

  function IndexOperationHandler() external returns (address);

  function WETH() external returns (address);

  function protocolFee() external returns (uint256);

  function protocolFeeBottomConstraint() external returns (uint256);

  function maxManagementFee() external returns (uint256);

  function maxPerformanceFee() external returns (uint256);

  function maxEntryFee() external returns (uint256);

  function maxExitFee() external returns (uint256);

  function exceptedRangeDecimal() external view returns(uint256);

  function MIN_VELVET_INVESTMENTAMOUNT() external returns (uint256);

  function MAX_VELVET_INVESTMENTAMOUNT() external returns (uint256);

  function enablePermittedTokens(address[] calldata _newTokens) external;

  function setIndexCreationState(bool _state) external;

  function setProtocolPause(bool _state) external;

  function setExceptedRangeDecimal(uint256 _newRange) external ;

  function getProtocolState() external returns (bool);

  function disablePermittedTokens(address[] calldata _tokens) external;

  function isPermitted(address _token) external returns (bool);

  function getETH() external view returns (address);

  function COOLDOWN_PERIOD() external view returns (uint256);

  function setMaxAssetLimit(uint256) external;

  function getMaxAssetLimit() external view returns (uint256);
}