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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOracle {
    struct Value {
        bytes data;
        uint64 timestamp;
    }

    event StateUpdated(address indexed sender, bytes data, bytes32 indexed key);

    function updateState(bytes calldata data) external;

    function updateStateByKey(bytes calldata data, bytes32 key) external;

    function updateStateBulk(
        bytes[] calldata data,
        bytes32[] calldata keys
    ) external;

    function readAsString(address sender) external view returns (string memory);

    function readAsUint256(address sender) external view returns (uint256);

    function readAsUint128(address sender) external view returns (uint128);

    function readAsUint64(address sender) external view returns (uint64);

    function readAsInt256(address sender) external view returns (int256);

    function readAsInt128(address sender) external view returns (int128);

    function readAsInt64(address sender) external view returns (int64);

    function readAsStringByKey(
        address sender,
        bytes32 key
    ) external view returns (string memory);

    function readAsUint256ByKey(
        address sender,
        bytes32 key
    ) external view returns (uint256);

    function readAsUint128ByKey(
        address sender,
        bytes32 key
    ) external view returns (uint128);

    function readAsUint64ByKey(
        address sender,
        bytes32 key
    ) external view returns (uint64);

    function readAsInt256ByKey(
        address sender,
        bytes32 key
    ) external view returns (int256);

    function readAsInt128ByKey(
        address sender,
        bytes32 key
    ) external view returns (int128);

    function readAsInt64ByKey(
        address sender,
        bytes32 key
    ) external view returns (int64);

    function readAsStringWithTimestamp(
        address sender,
        bytes32 key
    ) external view returns (string memory, uint64);

    function readAsUint256WithTimestamp(
        address sender,
        bytes32 key
    ) external view returns (uint256, uint64);

    function readAsUint128WithTimestamp(
        address sender,
        bytes32 key
    ) external view returns (uint128, uint64);

    function readAsUint64WithTimestamp(
        address sender,
        bytes32 key
    ) external view returns (uint64, uint64);

    function readAsInt256WithTimestamp(
        address sender,
        bytes32 key
    ) external view returns (int256, uint64);

    function readAsInt128WithTimestamp(
        address sender,
        bytes32 key
    ) external view returns (int128, uint64);

    function readAsInt64WithTimestamp(
        address sender,
        bytes32 key
    ) external view returns (int64, uint64);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/IOracle.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Oracle is IOracle, Initializable {
    uint64 public version;
    bytes32 public constant DEFAULT_KEY = 0x0;

    string public constant E_LENGTH_MISMATCH = "data and keys length mismatch";

    mapping(address => mapping(bytes32 => Value)) public data;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() external initializer {
        version = 1;
    }

    function updateStateBulk(
        bytes[] calldata _data,
        bytes32[] calldata keys
    ) external override {
        require(_data.length == keys.length, E_LENGTH_MISMATCH);
        uint64 timestamp = _blockTimestamp();
        for (uint256 i = 0; i < _data.length; i++) {
            _updateState(_data[i], keys[i], timestamp);
        }
    }

    function updateStateByKey(
        bytes calldata _data,
        bytes32 key
    ) external override {
        _updateState(_data, key);
    }

    function updateState(bytes calldata _data) external override {
        _updateState(_data, DEFAULT_KEY);
    }

    function readAsStringWithTimestamp(
        address sender,
        bytes32 key
    ) external view override returns (string memory, uint64) {
        return _readAsString(sender, key);
    }

    function readAsUint256WithTimestamp(
        address sender,
        bytes32 key
    ) external view override returns (uint256, uint64) {
        return _readAsUint256(sender, key);
    }

    function readAsUint128WithTimestamp(
        address sender,
        bytes32 key
    ) external view override returns (uint128, uint64) {
        return _readAsUint128(sender, key);
    }

    function readAsUint64WithTimestamp(
        address sender,
        bytes32 key
    ) external view override returns (uint64, uint64) {
        return _readAsUint64(sender, key);
    }

    function readAsInt256WithTimestamp(
        address sender,
        bytes32 key
    ) external view override returns (int256, uint64) {
        return _readAsInt256(sender, key);
    }

    function readAsInt128WithTimestamp(
        address sender,
        bytes32 key
    ) external view override returns (int128, uint64) {
        return _readAsInt128(sender, key);
    }

    function readAsInt64WithTimestamp(
        address sender,
        bytes32 key
    ) external view override returns (int64, uint64) {
        return _readAsInt64(sender, key);
    }

    function readAsStringByKey(
        address sender,
        bytes32 key
    ) external view override returns (string memory) {
        (string memory value, ) = _readAsString(sender, key);
        return value;
    }

    function readAsUint256ByKey(
        address sender,
        bytes32 key
    ) external view override returns (uint256) {
        (uint256 value, ) = _readAsUint256(sender, key);
        return value;
    }

    function readAsUint128ByKey(
        address sender,
        bytes32 key
    ) external view override returns (uint128) {
        (uint128 value, ) = _readAsUint128(sender, key);
        return value;
    }

    function readAsUint64ByKey(
        address sender,
        bytes32 key
    ) external view override returns (uint64) {
        (uint64 value, ) = _readAsUint64(sender, key);
        return value;
    }

    function readAsInt256ByKey(
        address sender,
        bytes32 key
    ) external view override returns (int256) {
        (int256 value, ) = _readAsInt256(sender, key);
        return value;
    }

    function readAsInt128ByKey(
        address sender,
        bytes32 key
    ) external view override returns (int128) {
        (int128 value, ) = _readAsInt128(sender, key);
        return value;
    }

    function readAsInt64ByKey(
        address sender,
        bytes32 key
    ) external view override returns (int64) {
        (int64 value, ) = _readAsInt64(sender, key);
        return value;
    }

    function readAsString(
        address sender
    ) external view override returns (string memory) {
        (string memory value, ) = _readAsString(sender, DEFAULT_KEY);
        return value;
    }

    function readAsUint256(
        address sender
    ) external view override returns (uint256) {
        (uint256 value, ) = _readAsUint256(sender, DEFAULT_KEY);
        return value;
    }

    function readAsUint128(
        address sender
    ) external view override returns (uint128) {
        (uint128 value, ) = _readAsUint128(sender, DEFAULT_KEY);
        return value;
    }

    function readAsUint64(
        address sender
    ) external view override returns (uint64) {
        (uint64 value, ) = _readAsUint64(sender, DEFAULT_KEY);
        return value;
    }

    function readAsInt256(
        address sender
    ) external view override returns (int256) {
        (int256 value, ) = _readAsInt256(sender, DEFAULT_KEY);
        return value;
    }

    function readAsInt128(
        address sender
    ) external view override returns (int128) {
        (int128 value, ) = _readAsInt128(sender, DEFAULT_KEY);
        return value;
    }

    function readAsInt64(
        address sender
    ) external view override returns (int64) {
        (int64 value, ) = _readAsInt64(sender, DEFAULT_KEY);
        return value;
    }

    function _updateState(bytes calldata _data, bytes32 key) internal {
        _updateState(_data, key, _blockTimestamp());
    }

    function _updateState(
        bytes calldata _data,
        bytes32 key,
        uint64 timestamp
    ) internal {
        data[msg.sender][key] = Value(_data, timestamp);
        emit StateUpdated(msg.sender, _data, key);
    }

    function _readAsString(
        address sender,
        bytes32 key
    ) internal view returns (string memory, uint64) {
        Value memory value = data[sender][key];
        return (abi.decode(value.data, (string)), value.timestamp);
    }

    function _readAsUint256(
        address sender,
        bytes32 key
    ) internal view returns (uint256, uint64) {
        Value memory value = data[sender][key];
        return (abi.decode(value.data, (uint256)), value.timestamp);
    }

    function _readAsUint128(
        address sender,
        bytes32 key
    ) internal view returns (uint128, uint64) {
        Value memory value = data[sender][key];
        return (abi.decode(value.data, (uint128)), value.timestamp);
    }

    function _readAsUint64(
        address sender,
        bytes32 key
    ) internal view returns (uint64, uint64) {
        Value memory value = data[sender][key];
        return (abi.decode(value.data, (uint64)), value.timestamp);
    }

    function _readAsInt256(
        address sender,
        bytes32 key
    ) internal view returns (int256, uint64) {
        Value memory value = data[sender][key];
        return (abi.decode(value.data, (int256)), value.timestamp);
    }

    function _readAsInt128(
        address sender,
        bytes32 key
    ) internal view returns (int128, uint64) {
        Value memory value = data[sender][key];
        return (abi.decode(value.data, (int128)), value.timestamp);
    }

    function _readAsInt64(
        address sender,
        bytes32 key
    ) internal view returns (int64, uint64) {
        Value memory value = data[sender][key];
        return (abi.decode(value.data, (int64)), value.timestamp);
    }

    function _blockTimestamp() internal view returns (uint64) {
        return uint64(block.timestamp);
    }
}