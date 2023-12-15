// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

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
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
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
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
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
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.20;

import {EnumerableSet} from "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code repetition as possible, we write it in
    // terms of a generic Map type with bytes32 keys and values. The Map implementation uses private functions,
    // and user-facing implementations such as `UintToAddressMap` are just wrappers around the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit in bytes32.

    /**
     * @dev Query for a nonexistent map key.
     */
    error EnumerableMapNonexistentKey(bytes32 key);

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 key => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToBytes32Map storage map, bytes32 key, bytes32 value) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        if (value == 0 && !contains(map, key)) {
            revert EnumerableMapNonexistentKey(key);
        }
        return value;
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToBytes32Map storage map) internal view returns (bytes32[] memory) {
        return map._keys.values();
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToUintMap storage map, uint256 key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToUintMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToAddressMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToUintMap storage map, address key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(AddressToUintMap storage map) internal view returns (address[] memory) {
        bytes32[] memory store = keys(map._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToUintMap storage map, bytes32 key, uint256 value) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToUintMap storage map) internal view returns (bytes32[] memory) {
        bytes32[] memory store = keys(map._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

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
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
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
            set._positions[value] = set._values.length;
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
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/structs/EnumerableMap.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import '../interfaces/IFactorMsgSendEndpoint.sol';

/**
 * @notice This abstract is a modified version of Pendle's PendleMsgSenderAppUpg.sol:
 * https://github.com/pendle-finance/pendle-core-v2-public/blob/main/contracts/LiquidityMining
 * /CrossChainMsg/PendleMsgSenderAppUpg.sol
 *
 */

// solhint-disable no-empty-blocks

abstract contract FactorMsgSenderUpgradeable is OwnableUpgradeable {
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    struct FactorMsgSenderStorage {
        uint256 approxDstExecutionGas;
        address factorMsgSendEndpoint;
        EnumerableMap.UintToAddressMap destinationContracts;
    }

    bytes32 private constant MSG_SENDER_STORAGE = keccak256('factor.crosschain.MsgSenderStorage');

    function _getMsgSenderStorage() internal pure returns (FactorMsgSenderStorage storage $) {
        bytes32 slot = MSG_SENDER_STORAGE;
        assembly {
            $.slot := slot
        }
    }

    error InsufficientFeeToSendMsg(uint256 currentFee, uint256 requiredFee);

    modifier refundUnusedEth() {
        _;
        if (address(this).balance > 0) {
            (bool success, ) = payable(msg.sender).call{ value: address(this).balance }('');
            require(success, 'Address: unable to send value, recipient may have reverted');
        }
    }

    function __FactorMsgSender_init(
        address _factorMsgSendEndpoint,
        uint256 _approxDstExecutionGas
    ) internal onlyInitializing {
        _getMsgSenderStorage().factorMsgSendEndpoint = _factorMsgSendEndpoint;
        _getMsgSenderStorage().approxDstExecutionGas = _approxDstExecutionGas;
    }

    function _sendMessage(uint256 chainId, bytes memory message) internal {
        FactorMsgSenderStorage storage $ = _getMsgSenderStorage();
        assert($.destinationContracts.contains(chainId));
        address toAddr = $.destinationContracts.get(chainId);
        uint256 estimatedGasAmount = $.approxDstExecutionGas;
        uint256 fee = IFactorMsgSendEndpoint($.factorMsgSendEndpoint).calcFee(
            toAddr,
            chainId,
            message,
            estimatedGasAmount
        );
        // LM contracts won't hold ETH on its own so this is fine
        if (address(this).balance < fee) revert InsufficientFeeToSendMsg(address(this).balance, fee);
        IFactorMsgSendEndpoint($.factorMsgSendEndpoint).sendMessage{ value: fee }(
            toAddr,
            chainId,
            message,
            estimatedGasAmount
        );
    }

    function addDestinationContract(address _address, uint256 _chainId) external payable onlyOwner {
        _getMsgSenderStorage().destinationContracts.set(_chainId, _address);
    }

    function setApproxDstExecutionGas(uint256 gas) external onlyOwner {
        _getMsgSenderStorage().approxDstExecutionGas = gas;
    }

    function getAllDestinationContracts() public view returns (uint256[] memory chainIds, address[] memory addrs) {
        FactorMsgSenderStorage storage $ = _getMsgSenderStorage();
        uint256 length = $.destinationContracts.length();
        chainIds = new uint256[](length);
        addrs = new address[](length);

        for (uint256 i = 0; i < length; ++i) {
            (chainIds[i], addrs[i]) = $.destinationContracts.at(i);
        }
    }

    function _getSendMessageFee(uint256 chainId, bytes memory message) internal view returns (uint256) {
        FactorMsgSenderStorage storage $ = _getMsgSenderStorage();
        return
            IFactorMsgSendEndpoint($.factorMsgSendEndpoint).calcFee(
                $.destinationContracts.get(chainId),
                chainId,
                message,
                $.approxDstExecutionGas
            );
    }

    function approxDstExecutionGas() public view returns (uint256) {
        return _getMsgSenderStorage().approxDstExecutionGas;
    }

    function factorMsgSendEndpoint() public view returns (address) {
        return _getMsgSenderStorage().factorMsgSendEndpoint;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFactorGaugeController {

    event VaultClaimReward(
        address indexed vault, 
        uint256 amount
    );

    event ReceiveVotingResults(
        uint128 indexed wTime, 
        address[] vaults, 
        uint256[] fctrAmounts
    );

    event UpdateVaultReward(
        address indexed vault,
        uint256 fctrPerSec,
        uint256 incentiveEndsAt
    );

    event AddVault(address indexed vault);

    event RemoveVault(address indexed vault);

    function fundEsFctr(uint256 amount) external;

    function withdrawEsFctr(uint256 amount) external;

    function esFctr() external returns (address);

    function redeemVaultReward() external;

    function rewardData(
        address pool
    ) external view returns (uint128 fctrPerSec, uint128, uint128, uint128);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import './IFactorGaugeController.sol';

interface IFactorGaugeControllerMainchain is IFactorGaugeController {
    function updateVotingResults(
        uint128 wTime, 
        address[] calldata vaults, 
        uint256[] calldata fctrSpeeds
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

interface IFactorMsgSendEndpoint {
    function calcFee(
        address dstAddress,
        uint256 dstChainId,
        bytes memory payload,
        uint256 estimatedGasAmount
    ) external view returns (uint256 fee);

    function sendMessage(
        address dstAddress,
        uint256 dstChainId,
        bytes calldata payload,
        uint256 estimatedGasAmount
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/VeBalanceLib.sol";

interface IFactorScale {

    event AddVault(uint64 indexed chainId, address indexed vault);

    event RemoveVault(uint64 indexed chainId, address indexed vault);

    event Vote(address indexed user, address indexed vault, uint64 weight, VeBalance vote);

    event VaultVoteChange(address indexed vault, VeBalance vote);

    event SetFctrPerSec(uint256 newFctrPerSec);

    event BroadcastResults(
        uint64 indexed chainId,
        uint128 indexed wTime,
        uint128 totalFctrPerSec
    );

    function applyVaultSlopeChanges(address vault) external;

    function getWeekData(uint128 wTime, address[] calldata vaults)
        external
        view
        returns (
            bool isEpochFinalized,
            uint128 totalVotes,
            uint128[] memory vaultVotes
        );

    function getVaultTotalVoteAt(address vault, uint128 wTime) external view returns (uint128);

    function finalizeEpoch() external;

    function getBroadcastResultFee(uint64 chainId) external view returns (uint256);

    function broadcastResults(uint64 chainId) external payable;

    function isVaultActive(address vault) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

interface IVotingEscrow {
    // ============= USER INFO =============

    function balanceOf(address user) external view returns (uint128);

    function balanceOfAt(address user, uint128 timestamp) external view returns (uint128);

    function positionData(address user) external view returns (uint128 amount, uint128 expiry);

    // ============= META DATA =============

    function totalSupplyStored() external view returns (uint128);

    function totalSupplyCurrent() external returns (uint128);

    function totalSupplyAndBalanceCurrent(address user) external returns (uint128, uint128);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

library Helpers {
    uint128 internal constant WEEK = 7 days;

    function getWeekStartTimestamp(uint128 timestamp) internal pure returns (uint128) {
        return (timestamp / WEEK) * WEEK;
    }

    function getCurrentWeekStart() internal view returns (uint128) {
        return getWeekStartTimestamp(uint128(block.timestamp));
    }

    function isValidWTime(uint256 time) internal pure returns (bool) {
        return time % WEEK == 0;
    }

    function isCurrentlyExpired(uint256 expiry) internal view returns (bool) {
        return (expiry <= block.timestamp);
    }

    function isExpired(uint256 expiry, uint256 blockTime) internal pure returns (bool) {
        return (expiry <= blockTime);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

/**
 * @notice This library is a modified version of Pendle's VeBalanceLib.sol:
 * https://github.com/pendle-finance/pendle-core-v2-public/blob/main/contracts/LiquidityMining
 * /libraries/VeBalanceLib.sol
 *
 */

struct VeBalance {
    uint128 bias;
    uint128 slope;
}

struct LockedPosition {
    uint128 amount;
    uint128 expiry;
}

library VeBalanceLib {
    error VEZeroSlope(uint128 bias, uint128 slope);
    error VEOverflowSlope(uint256 slope);

    uint128 internal constant MAX_LOCK_TIME = 104 weeks;
    uint256 internal constant USER_VOTE_MAX_WEIGHT = 10 ** 18;

    function add(VeBalance memory a, VeBalance memory b) internal pure returns (VeBalance memory res) {
        res.bias = a.bias + b.bias;
        res.slope = a.slope + b.slope;
    }

    function sub(VeBalance memory a, VeBalance memory b) internal pure returns (VeBalance memory res) {
        res.bias = a.bias - b.bias;
        res.slope = a.slope - b.slope;
    }

    function sub(VeBalance memory a, uint128 slope, uint128 expiry) internal pure returns (VeBalance memory res) {
        res.slope = a.slope - slope;
        res.bias = a.bias - slope * expiry;
    }

    function isExpired(VeBalance memory a) internal view returns (bool) {
        return a.slope * uint128(block.timestamp) >= a.bias;
    }

    function getCurrentValue(VeBalance memory a) internal view returns (uint128) {
        if (isExpired(a)) return 0;
        return getValueAt(a, uint128(block.timestamp));
    }

    function getValueAt(VeBalance memory a, uint128 t) internal pure returns (uint128) {
        if (a.slope * t > a.bias) {
            return 0;
        }
        return a.bias - a.slope * t;
    }

    function getExpiry(VeBalance memory a) internal pure returns (uint128) {
        if (a.slope == 0) revert VEZeroSlope(a.bias, a.slope);
        return a.bias / a.slope;
    }

    function convertToVeBalance(LockedPosition memory position) internal pure returns (VeBalance memory res) {
        res.slope = position.amount / MAX_LOCK_TIME;
        res.bias = res.slope * position.expiry;
    }

    function convertToVeBalance(
        LockedPosition memory position,
        uint256 weight
    ) internal pure returns (VeBalance memory res) {
        uint256 slope = (position.amount * weight) / MAX_LOCK_TIME / USER_VOTE_MAX_WEIGHT;
        if (slope > type(uint128).max) revert VEOverflowSlope(slope);
        res.slope = uint128(slope);
        res.bias = res.slope * position.expiry;
    }

    function convertToVeBalance(uint128 amount, uint128 expiry) internal pure returns (uint128, uint128) {
        VeBalance memory balance = convertToVeBalance(LockedPosition(amount, expiry));
        return (balance.bias, balance.slope);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Forked from OpenZeppelin (v4.5.0) (utils/Checkpoints.sol)
pragma solidity ^0.8.20;

import './VeBalanceLib.sol';
import './Helpers.sol';

struct Checkpoint {
    uint128 timestamp;
    VeBalance value;
}

library CheckpointHelper {
    function assignWith(Checkpoint memory a, Checkpoint memory b) internal pure {
        a.timestamp = b.timestamp;
        a.value = b.value;
    }
}

library Checkpoints {
    struct History {
        Checkpoint[] _checkpoints;
    }

    function length(History storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    function get(History storage self, uint256 index) internal view returns (Checkpoint memory) {
        return self._checkpoints[index];
    }

    function push(History storage self, VeBalance memory value) internal {
        uint256 pos = self._checkpoints.length;
        if (pos > 0 && self._checkpoints[pos - 1].timestamp == Helpers.getCurrentWeekStart()) {
            self._checkpoints[pos - 1].value = value;
        } else {
            self._checkpoints.push(Checkpoint({ timestamp: Helpers.getCurrentWeekStart(), value: value }));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IFactorGaugeControllerMainchain.sol";
import "../interfaces/IVotingEscrow.sol";

import "./FactorScaleBase.sol";
import "../crosschain/FactorMsgSenderUpgradeable.sol";

/**
 * @notice FactorScale.sol is a modified version of Pendle's VotingController:
 * https://github.com/pendle-finance/pendle-core-v2-public/blob/main/contracts
   /LiquidityMining/VotingController/PendleVotingControllerUpg.sol
 * 
 *
 * @dev Voting accounting:
    - For gauge controller, it will consider each message from factor scale
    as a pack of money to incentivize it during the very next WEEK (block.timestamp -> block.timestamp + WEEK)
    - If the reward duration for the last pack of money has not ended, it will combine
    the leftover reward with the current reward to distribute.

    - In the very extreme case where no one broadcast the result of week x, and at week x+1,
    the results for both are now broadcasted, then the WEEK of (block.timestamp -> WEEK)
    will receive both of the reward pack
    - Each pack of money will has it own id as timestamp, a gauge controller does not
    receive a pack of money with the same id twice, this allow governance to rebroadcast
    in case the last message was corrupted by LayerZero

 Pros:
    - If governance does not forget broadcasting the reward on the early of the week,
    the mechanism works just the same as the epoch-based one
    - If governance forget to broadcast the reward, the whole system still works normally,
    the reward is still incentivized, but only approximately fair
 Cons:
    - Does not guarantee the reward will be distributed on epoch start and end
*/

contract FactorScale is FactorMsgSenderUpgradeable, FactorScaleBase {
    using VeBalanceLib for VeBalance;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address _veFctr,
        address _fctrMsgSendEndpoint,
        uint256 initialApproxDestinationGas
    ) public initializer {
        __Ownable_init(msg.sender);
        __FactorMsgSender_init(_fctrMsgSendEndpoint, initialApproxDestinationGas);
        _getFactorScaleStorage().veFctr = _veFctr;
        _getFactorScaleStorage().deployedWTime = Helpers.getCurrentWeekStart();
    }

    /*///////////////////////////////////////////////////////////////
                FUNCTIONS CAN BE CALLED BY ANYONE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice updates a user's vote weights, also allowing user to divide their voting power
     * across different vaults
     * @param vaults vaults to change vote weights, if not listed then existing weight won't change
     * @param weights voting weight on each vault in `vaults`, must be same length as `vaults`
     * @dev A user's max voting weights is equal to `USER_VOTE_MAX_WEIGHT` (1e18). If their total
     * voted weights is less than such, then the excess weight is not counted. For such reason, a
     * user's voting power will only be fully utilized if their total voted weight is exactly 1e18.
     * @dev Reverts if, after all vote changes, the total voted weight is more than 1e18.
     * @dev A removed vault can be included, but the new weight must be 0, otherwise will revert.
     * @dev See {`FactorScaleBase - getUserData()`} for current user data.
     */
    function vote(address[] calldata vaults, uint64[] calldata weights) external {
        address user = msg.sender;

        FactorScaleStorage storage $ = _getFactorScaleStorage();

        if (vaults.length != weights.length) revert ArrayLengthMismatch();

        if (user != owner() && IVotingEscrow($.veFctr).balanceOf(user) == 0) 
            revert FSZeroVeFctr(user);

        LockedPosition memory userPosition = _getUserVeFctrPosition(user);

        for (uint256 i = 0; i < vaults.length; ++i) {
            if (_isVaultActive(vaults[i])) applyVaultSlopeChanges(vaults[i]);
            VeBalance memory newVote = _modifyVoteWeight(user, vaults[i], userPosition, weights[i]);
            emit Vote(user, vaults[i], weights[i], newVote);
        }

        uint256 totalVotedWeight = $.userData[user].totalVotedWeight;
        if (totalVotedWeight > VeBalanceLib.USER_VOTE_MAX_WEIGHT)
            revert FSExceededMaxWeight(totalVotedWeight, VeBalanceLib.USER_VOTE_MAX_WEIGHT);
    }

    /**
     * @notice Process all the slopeChanges that haven't been processed & update these data into
     * vaultData
     * @dev reverts if vault is not active
     * @dev if vault is already up-to-date, the function will succeed without any state updates
     */
    function applyVaultSlopeChanges(address vault) public {
        if (!_isVaultActive(vault)) revert FSInactiveVault(vault);

        FactorScaleStorage storage $ = _getFactorScaleStorage();

        uint128 wTime = $.vaultData[vault].lastSlopeChangeAppliedAt;
        uint128 currentWeekStart = Helpers.getCurrentWeekStart();

        // no state changes are expected
        if (wTime >= currentWeekStart) return;

        VeBalance memory currentVote = $.vaultData[vault].totalVote;
        while (wTime < currentWeekStart) {
            wTime += WEEK;
            currentVote = currentVote.sub($.vaultData[vault].slopeChanges[wTime], wTime);
            _setFinalVaultVoteForWeek(vault, wTime, currentVote.getValueAt(wTime));
        }

        _setNewVoteVaultData(vault, currentVote, wTime);
    }

    /**
     * @notice finalize the voting results of all vaults, up to the current epoch
     * @dev See `applyVaultSlopeChanges()` for more details
     * @dev This function might be gas-costly if there are a lot of active vaults, but this can be
     * mitigated by calling `applyVaultSlopeChanges()` for each vault separately, spreading the gas
     * cost across multiple txs (although the total gas cost will be higher).
     * This is because `applyVaultSlopeChanges()` will not update anything if already up-to-date.
     */
    function finalizeEpoch() public {
        uint256 length = _getFactorScaleStorage().allActiveVaults.length();
        for (uint256 i = 0; i < length; ++i) {
            applyVaultSlopeChanges(_getFactorScaleStorage().allActiveVaults.at(i));
        }
        _setAllPastEpochsAsFinalized();
    }

    /**
     * @notice broadcast the voting results of the current week to the chain with chainId. Can be
     * called by anyone.
     * @dev It's intentional to allow the same results to be broadcasted multiple
     * times. The receiver should be able to filter these duplicated messages
     * @dev The epoch must have already been finalized by `finalizeEpoch()`, otherwise will revert.
     */
    function broadcastResults(uint64 chainId) external payable refundUnusedEth {
        uint128 wTime = Helpers.getCurrentWeekStart();
        FactorScaleStorage storage $ = _getFactorScaleStorage();
        if (!$.weekData[wTime].isEpochFinalized) revert FSEpochNotFinalized(wTime);
        if ($.fctrPerSec == 0) revert FSNotSetFctrPerSec();
        _broadcastResults(chainId, wTime, $.fctrPerSec);
    }

    /*///////////////////////////////////////////////////////////////
                    GOVERNANCE-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice add a vault to allow users to vote. Can only be done by governance
     * @custom:gov NOTE TO GOV:
     * - Previous week's results should have been broadcasted prior to calling this function.
     * - `vault` must not have been added before (even if has been removed).
     * - `chainId` must be valid.
     */
    function addVault(uint64 chainId, address vault) external onlyOwner {
        if (_isVaultActive(vault)) revert FSVaultAlreadyActive(vault);

        if (_getFactorScaleStorage().allRemovedVaults.contains(vault)) 
            revert FSVaultAlreadyAddAndRemoved(vault);

        _addVault(chainId, vault);

        emit AddVault(chainId, vault);
    }

    /**
     * @notice remove a vault from voting. Can only be done by governance
     * @custom:gov NOTE TO GOV:
     * - Previous week's results should have been broadcasted prior to calling this function.
     * - `vault` must be currently active.
     */
    function removeVault(address vault) external onlyOwner {
        if (!_isVaultActive(vault)) revert FSInactiveVault(vault);

        uint64 chainId = _getFactorScaleStorage().vaultData[vault].chainId;

        applyVaultSlopeChanges(vault);

        _removeVault(vault);

        emit RemoveVault(chainId, vault);
    }

    /**
     * @notice use the gov-privilege to force broadcast a message in case there are issues with LayerZero
     * @custom:gov NOTE TO GOV: gov should always call finalizeEpoch beforehand
     */
    function forceBroadcastResults(
        uint64 chainId,
        uint128 wTime,
        uint128 forcedFctrPerSec
    ) external payable onlyOwner refundUnusedEth {
        _broadcastResults(chainId, wTime, forcedFctrPerSec);
    }

    /**
     * @notice sets new fctrPerSec
     * @dev no zero checks because gov may want to stop liquidity mining
     * @custom:gov NOTE TO GOV: Should be done mid-week, well before the next broadcast to avoid
     * race condition
     */
    function setFctrPerSec(uint128 newFctrPerSec) external onlyOwner {
        _getFactorScaleStorage().fctrPerSec = newFctrPerSec;
        emit SetFctrPerSec(newFctrPerSec);
    }

    function getBroadcastResultFee(uint64 chainId) external view returns (uint256) {
        if (chainId == block.chainid) return 0; // Mainchain broadcast

        uint256 length = _getFactorScaleStorage().activeChainVaults[chainId].length();
        if (length == 0) return 0;

        address[] memory vaults = new address[](length);
        uint256[] memory totalFctrAmounts = new uint256[](length);

        return _getSendMessageFee(
            chainId, abi.encode(uint128(0), vaults, totalFctrAmounts)
        );
    }

    function isVaultActive(address vault) external view returns (bool) {
        return _isVaultActive(vault);
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice broadcast voting results of the timestamp to chainId
    function _broadcastResults(uint64 chainId, uint128 wTime, uint128 totalFctrPerSec) internal {
        FactorScaleStorage storage $ = _getFactorScaleStorage();

        uint256 totalVotes = $.weekData[wTime].totalVotes;
        if (totalVotes == 0) return;

        uint256 length = $.activeChainVaults[chainId].length();
        if (length == 0) return;

        address[] memory vaults = $.activeChainVaults[chainId].values();
        uint256[] memory totalFctrAmounts = new uint256[](length);

        for (uint256 i = 0; i < length; ++i) {
            uint256 vaultVotes = $.weekData[wTime].vaultVotes[vaults[i]];
            totalFctrAmounts[i] = (totalFctrPerSec * vaultVotes * WEEK) / totalVotes;
        }

        if (chainId == block.chainid) {
            address gaugeController = _getMsgSenderStorage().destinationContracts.get(chainId);
            IFactorGaugeControllerMainchain(gaugeController).updateVotingResults(
                wTime,
                vaults,
                totalFctrAmounts
            );
        } else {
            _sendMessage(chainId, abi.encode(wTime, vaults, totalFctrAmounts));
        }

        emit BroadcastResults(chainId, wTime, totalFctrPerSec);
    }

    function _getUserVeFctrPosition(
        address user
    ) internal view returns (LockedPosition memory userPosition) {
        if (user == owner()) {
            (userPosition.amount, userPosition.expiry) = (
                GOVERNANCE_FCTR_VOTE,
                Helpers.getWeekStartTimestamp(uint128(block.timestamp) + MAX_LOCK_TIME)
            );
        } else {
            (userPosition.amount, userPosition.expiry) = 
                IVotingEscrow(_getFactorScaleStorage().veFctr).positionData(user);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import '../interfaces/IFactorScale.sol';

import '../libraries/VeHistoryLib.sol';

/**
 * @notice FactorScaleBase.sol is a modified version of Pendle's VotingControllerStorageUpg.sol:
 * https://github.com/pendle-finance/pendle-core-v2-public/blob/main/contracts/LiquidityMining
   /VotingController/VotingControllerStorageUpg.sol
 * 
 */
abstract contract FactorScaleBase is IFactorScale {
    using VeBalanceLib for VeBalance;
    using VeBalanceLib for LockedPosition;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Checkpoints for Checkpoints.History;
    using Helpers for uint128;

    // =============================================================
    //                          Errors
    // =============================================================

    error FSInvalidWTime(uint256 wTime);
    error FSInactiveVault(address vault);
    error FSZeroVeFctr(address user);
    error FSExceededMaxWeight(uint256 totalWeight, uint256 maxWeight);
    error FSEpochNotFinalized(uint256 wTime);
    error FSVaultAlreadyActive(address vault);
    error FSVaultAlreadyAddAndRemoved(address vault);
    error FSNotSetFctrPerSec();

    // GENERIC MSG
    error ArrayOutOfBounds();
    error ArrayLengthMismatch();

    struct VaultData {
        uint64 chainId;
        uint128 lastSlopeChangeAppliedAt;
        VeBalance totalVote;
        // wTime => slopeChange value
        mapping(uint128 => uint128) slopeChanges;
    }

    struct UserVaultData {
        uint64 weight;
        VeBalance vote;
    }

    struct UserData {
        uint64 totalVotedWeight;
        mapping(address => UserVaultData) voteForVaults;
    }

    struct WeekData {
        bool isEpochFinalized;
        uint128 totalVotes;
        mapping(address => uint128) vaultVotes;
    }

    struct FactorScaleStorage {
        address veFctr;
        uint128 deployedWTime;
        uint128 fctrPerSec;
        // [chainId] => [vault]
        mapping(uint64 => EnumerableSet.AddressSet) activeChainVaults;
        // [vaultAddress] -> VaultData
        mapping(address => VaultData) vaultData;
        // [wTime] => WeekData
        mapping(uint128 => WeekData) weekData;
        // user voting data
        mapping(address => UserData) userData;
        EnumerableSet.AddressSet allActiveVaults;
        EnumerableSet.AddressSet allRemovedVaults;
    }

    bytes32 private constant FACTOR_SCALE_STORAGE = keccak256('factor.scale.storage');

    function _getFactorScaleStorage() internal pure returns (FactorScaleStorage storage ds) {
        bytes32 slot = FACTOR_SCALE_STORAGE;
        assembly {
            ds.slot := slot
        }
    }

    uint128 public constant MAX_LOCK_TIME = 104 weeks;
    uint128 public constant WEEK = 1 weeks;
    uint128 public constant GOVERNANCE_FCTR_VOTE = 10 * (10 ** 6) * (10 ** 18); // 10 mils of FCTR

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function veFctr() external view returns (address) {
        return _getFactorScaleStorage().veFctr;
    }

    function deployedWTime() external view returns (uint128) {
        return _getFactorScaleStorage().deployedWTime;
    }

    function fctrPerSec() external view returns (uint128) {
        return _getFactorScaleStorage().fctrPerSec;
    }

    function getVaultTotalVoteAt(address vault, uint128 wTime) public view returns (uint128) {
        return _getFactorScaleStorage().weekData[wTime].vaultVotes[vault];
    }

    function getVaultData(
        address vault,
        uint128[] calldata wTimes
    )
        public
        view
        returns (
            uint64 chainId,
            uint128 lastSlopeChangeAppliedAt,
            VeBalance memory totalVote,
            uint128[] memory slopeChanges
        )
    {
        VaultData storage data = _getFactorScaleStorage().vaultData[vault];
        (chainId, lastSlopeChangeAppliedAt, totalVote) = (data.chainId, data.lastSlopeChangeAppliedAt, data.totalVote);

        slopeChanges = new uint128[](wTimes.length);
        for (uint256 i = 0; i < wTimes.length; ++i) {
            if (!wTimes[i].isValidWTime()) revert FSInvalidWTime(wTimes[i]);
            slopeChanges[i] = data.slopeChanges[wTimes[i]];
        }
    }

    function getUserData(
        address user,
        address[] calldata vaults
    ) public view returns (uint64 totalVotedWeight, UserVaultData[] memory voteForVaults) {
        UserData storage data = _getFactorScaleStorage().userData[user];

        totalVotedWeight = data.totalVotedWeight;

        voteForVaults = new UserVaultData[](vaults.length);
        for (uint256 i = 0; i < vaults.length; ++i) voteForVaults[i] = data.voteForVaults[vaults[i]];
    }

    function getWeekData(
        uint128 wTime,
        address[] calldata vaults
    ) public view returns (bool isEpochFinalized, uint128 totalVotes, uint128[] memory vaultVotes) {
        if (!wTime.isValidWTime()) revert FSInvalidWTime(wTime);

        WeekData storage data = _getFactorScaleStorage().weekData[wTime];

        (isEpochFinalized, totalVotes) = (data.isEpochFinalized, data.totalVotes);

        vaultVotes = new uint128[](vaults.length);
        for (uint256 i = 0; i < vaults.length; ++i) vaultVotes[i] = data.vaultVotes[vaults[i]];
    }

    function getAllActiveVaults() external view returns (address[] memory) {
        return _getFactorScaleStorage().allActiveVaults.values();
    }

    function getAllRemovedVaults(
        uint256 start,
        uint256 end
    ) external view returns (uint256 lengthOfRemovedVaults, address[] memory arr) {
        FactorScaleStorage storage $ = _getFactorScaleStorage();

        lengthOfRemovedVaults = $.allRemovedVaults.length();

        if (end >= lengthOfRemovedVaults) revert ArrayOutOfBounds();

        arr = new address[](end - start + 1);
        for (uint256 i = start; i <= end; ++i) arr[i - start] = $.allRemovedVaults.at(i);
    }

    function getActiveChainVaults(uint64 chainId) external view returns (address[] memory) {
        return _getFactorScaleStorage().activeChainVaults[chainId].values();
    }

    function getUserVaultVote(address user, address vault) external view returns (UserVaultData memory) {
        return _getFactorScaleStorage().userData[user].voteForVaults[vault];
    }

    /*///////////////////////////////////////////////////////////////
                INTERNAL DATA MANIPULATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _addVault(uint64 chainId, address vault) internal {
        FactorScaleStorage storage $ = _getFactorScaleStorage();

        if (!$.activeChainVaults[chainId].add(vault)) assert(false);
        if (!$.allActiveVaults.add(vault)) assert(false);

        $.vaultData[vault].chainId = chainId;
        $.vaultData[vault].lastSlopeChangeAppliedAt = Helpers.getCurrentWeekStart();
    }

    function _removeVault(address vault) internal {
        FactorScaleStorage storage $ = _getFactorScaleStorage();

        uint64 chainId = $.vaultData[vault].chainId;
        if (!$.activeChainVaults[chainId].remove(vault)) assert(false);
        if (!$.allActiveVaults.remove(vault)) assert(false);
        if (!$.allRemovedVaults.add(vault)) assert(false);

        delete $.vaultData[vault];
    }

    function _setFinalVaultVoteForWeek(address vault, uint128 wTime, uint128 vote) internal {
        FactorScaleStorage storage $ = _getFactorScaleStorage();

        $.weekData[wTime].totalVotes += vote;
        $.weekData[wTime].vaultVotes[vault] = vote;
    }

    function _setNewVoteVaultData(address vault, VeBalance memory vote, uint128 wTime) internal {
        FactorScaleStorage storage $ = _getFactorScaleStorage();

        $.vaultData[vault].totalVote = vote;
        $.vaultData[vault].lastSlopeChangeAppliedAt = wTime;
        emit VaultVoteChange(vault, vote);
    }

    /**
     * @notice modifies `user`'s vote weight on `vault`
     * @dev works by simply removing the old vote position, then adds in a fresh vote
     */
    function _modifyVoteWeight(
        address user,
        address vault,
        LockedPosition memory userPosition,
        uint64 weight
    ) internal returns (VeBalance memory newVote) {
        FactorScaleStorage storage $ = _getFactorScaleStorage();

        UserData storage uData = $.userData[user];
        VaultData storage vData = $.vaultData[vault];

        VeBalance memory oldVote = uData.voteForVaults[vault].vote;

        // REMOVE OLD VOTE
        if (oldVote.bias != 0) {
            if (_isVaultActive(vault) && _isVoteActive(oldVote)) {
                vData.totalVote = vData.totalVote.sub(oldVote);
                vData.slopeChanges[oldVote.getExpiry()] -= oldVote.slope;
            }
            uData.totalVotedWeight -= uData.voteForVaults[vault].weight;
            delete uData.voteForVaults[vault];
        }

        // ADD NEW VOTE
        if (weight != 0) {
            if (!_isVaultActive(vault)) revert FSInactiveVault(vault);

            newVote = userPosition.convertToVeBalance(weight);

            vData.totalVote = vData.totalVote.add(newVote);
            vData.slopeChanges[newVote.getExpiry()] += newVote.slope;

            uData.voteForVaults[vault] = UserVaultData(weight, newVote);
            uData.totalVotedWeight += weight;
        }

        emit VaultVoteChange(vault, vData.totalVote);
    }

    function _setAllPastEpochsAsFinalized() internal {
        FactorScaleStorage storage $ = _getFactorScaleStorage();

        uint128 wTime = Helpers.getCurrentWeekStart();
        while (wTime > $.deployedWTime && $.weekData[wTime].isEpochFinalized == false) {
            $.weekData[wTime].isEpochFinalized = true;
            wTime -= WEEK;
        }
    }

    function _isVaultActive(address vault) internal view returns (bool) {
        return _getFactorScaleStorage().allActiveVaults.contains(vault);
    }

    /// @notice check if a vote still counts by checking if the vote is not (x,0) (in case the
    /// weight of the vote is too small) & the expiry is after the current time
    function _isVoteActive(VeBalance memory vote) internal view returns (bool) {
        return vote.slope != 0 && !Helpers.isCurrentlyExpired(vote.getExpiry());
    }
}