pragma solidity 0.8.21;

import {SignerProxy} from "./SignerProxy.sol";
import {Signer} from "./Signer.sol";
import {DeploymentRouter} from "./DeploymentRouter.sol";
import {SafeProxyFactory} from "@safe-contracts/proxies/SafeProxyFactory.sol";
import {Initializable} from "@openzeppelin/proxy/utils/Initializable.sol";
import {Safe} from "@safe-contracts/Safe.sol";

library FactoryErrors {
    error SaltDoesNotMatchSafe();
    error ImplementationNotDeployed();
}

contract Factory is Initializable {
    event NewSignerCreated(address indexed proxy, bytes32 indexed recoveryId, uint256 x, uint256 y, address implementation);
    event NewFactorySetup(address implementation, address deploymentRouter);

    address public DEPLOYMENT_ROUTER;
    address public IMPLEMENTATION;
    address internal constant SAFE_FACTORY = 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2;
    address internal constant SAFE_SINGLETON = 0x29fcB43b46531BcA003ddC8FCB67FFE91900C762;
    address internal constant SAFE_4337_MODULE = 0xa581c4A4DB7175302464fF3C06380BC3270b4037;

    bytes4 internal constant SAFE_SETUP = 0xb63e800d;

    function initialize(address _implementation, address _deploymentRouter) external initializer {
        IMPLEMENTATION = _implementation;
        DEPLOYMENT_ROUTER = _deploymentRouter;
        emit NewFactorySetup(_implementation, _deploymentRouter);
    }

    function deploy(bytes32 _recoveryId, uint256 _x, uint256 _y, address[] memory _modules) external returns (bool) {
        _deploy(IMPLEMENTATION, _recoveryId, _x, _y, _modules);
        return true;
    }

    function _deploy(address _implementation, bytes32 _recoveryId, uint256 _x, uint256 _y, address[] memory _modules)
        internal
        returns (address signer)
    {
        bytes32 salt = checkCaller(_implementation, _recoveryId, _x, _y, _modules);

        signer = address(_deploySigner(_implementation, salt));
        Signer(signer).initialize(_x, _y);

        emit NewSignerCreated(signer, _recoveryId, _x, _y, _implementation);
    }

    /**
     * @dev Deploys a new SignerProxy contract using the specified implementation and salt.
     * @param _implementation The address of the implementation contract.
     * @param salt The salt value used for contract deployment.
     * @return proxy The deployed SignerProxy contract.
     */
    function _deploySigner(address _implementation, bytes32 salt) internal returns (SignerProxy proxy) {
        if (!isContract(_implementation)) revert FactoryErrors.ImplementationNotDeployed();

        bytes memory deploymentData =
            abi.encodePacked(type(SignerProxy).creationCode, uint256(uint160(_implementation)));

        // Deploy the account determinstically based on the salt
        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(address(proxy) != address(0), "Create2 call failed");
    }

    /**
     * @dev Checks if the given address is a contract.
     * @param account The address to check.
     * @return A boolean value indicating whether the address is a contract or not.
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            size := extcodesize(account)
        }
        /* solhint-enable no-inline-assembly */
        return size > 0;
    }

    function checkCaller(address _implementation, bytes32 _hash, uint256 _x, uint256 _y, address[] memory _modules)
        internal
        view
        returns (bytes32)
    {
        bytes32 salt = keccak256(abi.encodePacked(_hash, _x, _y, _modules));
        address signer = _getAddress(_implementation, address(this), type(SignerProxy).creationCode, salt);
        address safe = _getSafeAddress(signer, _hash, _x, _y, _modules);

        if (msg.sender == safe) {
            return salt;
        } else {
            revert FactoryErrors.SaltDoesNotMatchSafe();
        }
    }

    function getSignerAddress(bytes32 _recoveryId, uint256 _x, uint256 _y, address[] memory _modules) external view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_recoveryId, _x, _y, _modules));
        return _getAddress(IMPLEMENTATION, address(this), type(SignerProxy).creationCode, salt);
    }

    function getSafeAddress(address _signer, bytes32 _recoveryId, uint256 _x, uint256 _y, address[] memory _modules) external view returns (address) {
        return _getSafeAddress(_signer, _recoveryId, _x, _y, _modules);
    }

    function _getSafeAddress(address _signer, bytes32 _hash, uint256 _x, uint256 _y, address[] memory _modules) internal view returns (address) {
        bytes memory data =
            abi.encodeWithSelector(DeploymentRouter(DEPLOYMENT_ROUTER).setupSafe.selector, _hash, _x, _y, _modules);
        bytes memory safeSetup = _safeSetup(_signer, DEPLOYMENT_ROUTER, data, SAFE_4337_MODULE, address(0), 0, payable(0));

        bytes memory creationCode = SafeProxyFactory(SAFE_FACTORY).proxyCreationCode();
        bytes32 salt = keccak256(abi.encodePacked(keccak256(safeSetup), uint256(uint160(_signer))));

        return _getAddress(SAFE_SINGLETON, SAFE_FACTORY, creationCode, salt);
    }

    /**
     * @dev Retrieves the address of a deployed contract instance based on the implementation address,
     * deployer address, bytecode, and salt.
     *
     * @param _implementation The address of the contract implementation.
     * @param _deployer The address of the contract deployer.
     * @param _byteCode The bytecode of the contract.
     * @param _salt The salt used for contract deployment.
     *
     * @return The address of the deployed contract instance.
     */
    function _getAddress(address _implementation, address _deployer, bytes memory _byteCode, bytes32 _salt)
        internal
        pure
        returns (address)
    {
        bytes memory deploymentData = abi.encodePacked(_byteCode, uint256(uint160(_implementation)));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), _deployer, _salt, keccak256(deploymentData)));
        return address(uint160(uint256(hash)));
    }

    /**
     * @dev Function to safely set up the contract.
     */
    function _safeSetup(
        address _owner,
        address _target,
        bytes memory _data,
        address _fallbackHandler,
        address _paymentToken,
        uint256 _payment,
        address payable _paymentReceiver
    ) internal view returns (bytes memory) {
        address[] memory signers = new address[](1);
        signers[0] = _owner;
        return abi.encodeWithSelector(
            SAFE_SETUP,
            signers,
            1,
            _target,
            _data,
            _fallbackHandler,
            _paymentToken,
            _payment,
            _paymentReceiver
        );
    }
}

pragma solidity 0.8.21;

library proxyErrors {
    error IncorrectImplementationAddress();
}

contract SignerProxy {
    // Internal variable to store the implementation contract's address.
    address internal __implementation__;

    // Constructor sets the implementation contract's address.
    // @param _implementation: Address of the implementation contract.
    // Reverts if the provided implementation address is zero.
    constructor(address _implementation) {
        if (_implementation != address(0)) {
            __implementation__ = _implementation;
        } else {
            revert proxyErrors.IncorrectImplementationAddress();
        }
    }

    fallback() external payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load the address of the implementation contract.
            let _implementation := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            // Special handling for specific function signature 0x5c60da1b keccak("implementation()").
            // If this signature is detected, return the implementation address.
            if eq(calldataload(0), 0x5c60da1b00000000000000000000000000000000000000000000000000000000) {
                mstore(0, _implementation)
                return(0, 0x20)
            }

            // Forward all other calls to the implementation contract.
            // Copy calldata to memory and perform a delegatecall.
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            // Revert if the delegatecall failed, otherwise return the data.
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}

pragma solidity 0.8.21;

import {FCL_WebAuthn} from "@FreshCryptoLib/FCL_Webauthn.sol";
import {Initializable} from "@openzeppelin/proxy/utils/Initializable.sol";
import {EIP1271} from "./EIP1271.sol";

library SignerErrors {
    error InvalidSignature();
}

/**
 * @title Signer
 * @dev A contract that implements the EIP1271 interface and is initialized using Initializable.
 */
contract Signer is EIP1271, Initializable {
    address private _empty_slot_ = address(0);
    uint256 public x;
    uint256 public y;

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the signer contract with the given x and y coordinates.
     * @param _x The x coordinate of the signer's public key.
     * @param _y The y coordinate of the signer's public key.
     */
    function initialize(uint256 _x, uint256 _y) external initializer {
        x = _x;
        y = _y;
    }

    // Returns the public key coordinates.
    // @return uint256[2] memory: Array containing the x and y coordinates.
    function getPublicKey() internal view returns (uint256[2] memory key) {
        return [x, y];
    }

    // @inheritdoc EIP1271
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view override returns (bytes4) {
        _validate(abi.encode(_hash), _signature);
        return EIP1271_MAGICVALUE_BYTES32;
    }

    // @inheritdoc EIP1271
    function isValidSignature(bytes memory _hash, bytes memory _signature) external view override returns (bytes4) {
        _validate(_hash, _signature);
        return EIP1271_MAGICVALUE_BYTES;
    }

    function checkSignature(
        bytes calldata authenticatorData,
        bytes1 authenticatorDataFlagMask,
        bytes calldata clientData,
        bytes32 clientChallenge,
        uint256 clientChallengeDataOffset,
        uint256[2] calldata rs,
        uint256[2] calldata Q
    ) external view returns (bool) {
        return FCL_WebAuthn.checkSignature(
            authenticatorData, authenticatorDataFlagMask, clientData, clientChallenge, clientChallengeDataOffset, rs, Q
        );
    }

    // Internal function to validate a signature.
    // @param _hash: The hash to validate against.
    // @param _signature: The signature to validate.
    // Throws InvalidSignature if the signature is invalid.
    function _validate(bytes memory _hash, bytes memory _signature) private view {
        (bytes memory authenticatorData, bytes memory clientData, uint256 challengeOffset, uint256[2] memory rs) =
            abi.decode(_signature, (bytes, bytes, uint256, uint256[2]));
        if (
            !this.checkSignature(
                authenticatorData, 0x01, clientData, keccak256(_hash), challengeOffset, rs, getPublicKey()
            )
        ) revert SignerErrors.InvalidSignature();
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;


interface ISafe {
    function enableModule(address _module) external;
}

// Interface for the Factory contract.
interface IFactory {
    // Declares a function to deploy a new signer instance.
    // @param _hash: A unique identifier for the signer.
    // @param _x: X-coordinate of the public key.
    // @param _y: Y-coordinate of the public key.
    // @param _modules: An array of module addresses to enable for the safe.
    // @return bool: Returns true if deployment is successful.
    function deploy(bytes32 _hash, uint256 _x, uint256 _y, address[] calldata _modules) external returns (bool);
}

/// @title AddModulesLib
contract DeploymentRouter{
    // Immutable address of the Factory contract.
    address public immutable factoryProxy;

    // Constructor to set the Factory contract's address.
    // @param _factory: The address of the Factory contract.
    constructor(address _factoryProxy) {
        factoryProxy = _factoryProxy;
    }
    
    function setupSafe(bytes32 _hash, uint256 _x, uint256 _y, address[] calldata _modules) public returns (bool) {
        // Deploys a new signer instance.
        return _deploySigner(_hash, _x, _y, _modules);
    }

    // Function to deploy a signer through the Factory contract.
    // This allows external contracts or addresses to request signer deployments.
    // @param _hash: A unique identifier for the signer.
    // @param _x: X-coordinate of the public key.
    // @param _y: Y-coordinate of the public key.
    // @param _modules: An array of module addresses to enable for the safe.
    // @return bool: Returns true if deployment is successful.
    function _deploySigner(bytes32 _hash, uint256 _x, uint256 _y, address[] memory _modules) internal returns (bool) {
        // Calls the deploy function of the Factory contract.
        // Enables the modules.
        _enableModules(_modules);
        return IFactory(factoryProxy).deploy(_hash, _x, _y, _modules);
    }

    function _enableModules(address[] memory _modules) internal { 
        for (uint256 i = _modules.length; i > 0; i--) {
            // This call will only work properly if used via a delegatecall
            // from the Safe contract.
            ISafe(address(this)).enableModule(_modules[i - 1]);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./SafeProxy.sol";
import "./IProxyCreationCallback.sol";

/**
 * @title Proxy Factory - Allows to create a new proxy contract and execute a message call to the new proxy within one transaction.
 * @author Stefan George - @Georgi87
 */
contract SafeProxyFactory {
    event ProxyCreation(SafeProxy indexed proxy, address singleton);

    /// @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(SafeProxy).creationCode;
    }

    /**
     * @notice Internal method to create a new proxy contract using CREATE2. Optionally executes an initializer call to a new proxy.
     * @param _singleton Address of singleton contract. Must be deployed at the time of execution.
     * @param initializer (Optional) Payload for a message call to be sent to a new proxy contract.
     * @param salt Create2 salt to use for calculating the address of the new proxy contract.
     * @return proxy Address of the new proxy contract.
     */
    function deployProxy(address _singleton, bytes memory initializer, bytes32 salt) internal returns (SafeProxy proxy) {
        require(isContract(_singleton), "Singleton contract not deployed");

        bytes memory deploymentData = abi.encodePacked(type(SafeProxy).creationCode, uint256(uint160(_singleton)));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(address(proxy) != address(0), "Create2 call failed");

        if (initializer.length > 0) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(call(gas(), proxy, 0, add(initializer, 0x20), mload(initializer), 0, 0), 0) {
                    revert(0, 0)
                }
            }
        }
    }

    /**
     * @notice Deploys a new proxy with `_singleton` singleton and `saltNonce` salt. Optionally executes an initializer call to a new proxy.
     * @param _singleton Address of singleton contract. Must be deployed at the time of execution.
     * @param initializer Payload for a message call to be sent to a new proxy contract.
     * @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
     */
    function createProxyWithNonce(address _singleton, bytes memory initializer, uint256 saltNonce) public returns (SafeProxy proxy) {
        // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));
        proxy = deployProxy(_singleton, initializer, salt);
        emit ProxyCreation(proxy, _singleton);
    }

    /**
     * @notice Deploys a new chain-specific proxy with `_singleton` singleton and `saltNonce` salt. Optionally executes an initializer call to a new proxy.
     * @dev Allows to create a new proxy contract that should exist only on 1 network (e.g. specific governance or admin accounts)
     *      by including the chain id in the create2 salt. Such proxies cannot be created on other networks by replaying the transaction.
     * @param _singleton Address of singleton contract. Must be deployed at the time of execution.
     * @param initializer Payload for a message call to be sent to a new proxy contract.
     * @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
     */
    function createChainSpecificProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) public returns (SafeProxy proxy) {
        // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce, getChainId()));
        proxy = deployProxy(_singleton, initializer, salt);
        emit ProxyCreation(proxy, _singleton);
    }

    /**
     * @notice Deploy a new proxy with `_singleton` singleton and `saltNonce` salt.
     *         Optionally executes an initializer call to a new proxy and calls a specified callback address `callback`.
     * @param _singleton Address of singleton contract. Must be deployed at the time of execution.
     * @param initializer Payload for a message call to be sent to a new proxy contract.
     * @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
     * @param callback Callback that will be invoked after the new proxy contract has been successfully deployed and initialized.
     */
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) public returns (SafeProxy proxy) {
        uint256 saltNonceWithCallback = uint256(keccak256(abi.encodePacked(saltNonce, callback)));
        proxy = createProxyWithNonce(_singleton, initializer, saltNonceWithCallback);
        if (address(callback) != address(0)) callback.proxyCreated(proxy, _singleton, initializer, saltNonce);
    }

    /**
     * @notice Returns true if `account` is a contract.
     * @dev This function will return false if invoked during the constructor of a contract,
     *      as the code is not actually created until after the constructor finishes.
     * @param account The address being queried
     * @return True if `account` is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @notice Returns the ID of the chain the contract is currently deployed on.
     * @return The ID of the current chain as a uint256.
     */
    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./base/ModuleManager.sol";
import "./base/OwnerManager.sol";
import "./base/FallbackManager.sol";
import "./base/GuardManager.sol";
import "./common/NativeCurrencyPaymentFallback.sol";
import "./common/Singleton.sol";
import "./common/SignatureDecoder.sol";
import "./common/SecuredTokenTransfer.sol";
import "./common/StorageAccessible.sol";
import "./interfaces/ISignatureValidator.sol";
import "./external/SafeMath.sol";

/**
 * @title Safe - A multisignature wallet with support for confirmations using signed messages based on EIP-712.
 * @dev Most important concepts:
 *      - Threshold: Number of required confirmations for a Safe transaction.
 *      - Owners: List of addresses that control the Safe. They are the only ones that can add/remove owners, change the threshold and
 *        approve transactions. Managed in `OwnerManager`.
 *      - Transaction Hash: Hash of a transaction is calculated using the EIP-712 typed structured data hashing scheme.
 *      - Nonce: Each transaction should have a different nonce to prevent replay attacks.
 *      - Signature: A valid signature of an owner of the Safe for a transaction hash.
 *      - Guard: Guard is a contract that can execute pre- and post- transaction checks. Managed in `GuardManager`.
 *      - Modules: Modules are contracts that can be used to extend the write functionality of a Safe. Managed in `ModuleManager`.
 *      - Fallback: Fallback handler is a contract that can provide additional read-only functional for Safe. Managed in `FallbackManager`.
 *      Note: This version of the implementation contract doesn't emit events for the sake of gas efficiency and therefore requires a tracing node for indexing/
 *      For the events-based implementation see `SafeL2.sol`.
 * @author Stefan George - @Georgi87
 * @author Richard Meissner - @rmeissner
 */
contract Safe is
    Singleton,
    NativeCurrencyPaymentFallback,
    ModuleManager,
    OwnerManager,
    SignatureDecoder,
    SecuredTokenTransfer,
    ISignatureValidatorConstants,
    FallbackManager,
    StorageAccessible,
    GuardManager
{
    using SafeMath for uint256;

    string public constant VERSION = "1.4.1";

    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    // keccak256(
    //     "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
    // );
    bytes32 private constant SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;

    event SafeSetup(address indexed initiator, address[] owners, uint256 threshold, address initializer, address fallbackHandler);
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
    event SignMsg(bytes32 indexed msgHash);
    event ExecutionFailure(bytes32 indexed txHash, uint256 payment);
    event ExecutionSuccess(bytes32 indexed txHash, uint256 payment);

    uint256 public nonce;
    bytes32 private _deprecatedDomainSeparator;
    // Mapping to keep track of all message hashes that have been approved by ALL REQUIRED owners
    mapping(bytes32 => uint256) public signedMessages;
    // Mapping to keep track of all hashes (message or transaction) that have been approved by ANY owners
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

    // This constructor ensures that this contract can only be used as a singleton for Proxy contracts
    constructor() {
        /**
         * By setting the threshold it is not possible to call setup anymore,
         * so we create a Safe with 0 owners and threshold 1.
         * This is an unusable Safe, perfect for the singleton
         */
        threshold = 1;
    }

    /**
     * @notice Sets an initial storage of the Safe contract.
     * @dev This method can only be called once.
     *      If a proxy was created without setting up, anyone can call setup and claim the proxy.
     * @param _owners List of Safe owners.
     * @param _threshold Number of required confirmations for a Safe transaction.
     * @param to Contract address for optional delegate call.
     * @param data Data payload for optional delegate call.
     * @param fallbackHandler Handler for fallback calls to this contract
     * @param paymentToken Token that should be used for the payment (0 is ETH)
     * @param payment Value that should be paid
     * @param paymentReceiver Address that should receive the payment (or 0 if tx.origin)
     */
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external {
        // setupOwners checks if the Threshold is already set, therefore preventing that this method is called twice
        setupOwners(_owners, _threshold);
        if (fallbackHandler != address(0)) internalSetFallbackHandler(fallbackHandler);
        // As setupOwners can only be called if the contract has not been initialized we don't need a check for setupModules
        setupModules(to, data);

        if (payment > 0) {
            // To avoid running into issues with EIP-170 we reuse the handlePayment function (to avoid adjusting code of that has been verified we do not adjust the method itself)
            // baseGas = 0, gasPrice = 1 and gas = payment => amount = (payment + 0) * 1 = payment
            handlePayment(payment, 0, 1, paymentToken, paymentReceiver);
        }
        emit SafeSetup(msg.sender, _owners, _threshold, to, fallbackHandler);
    }

    /** @notice Executes a `operation` {0: Call, 1: DelegateCall}} transaction to `to` with `value` (Native Currency)
     *          and pays `gasPrice` * `gasLimit` in `gasToken` token to `refundReceiver`.
     * @dev The fees are always transferred, even if the user transaction fails.
     *      This method doesn't perform any sanity check of the transaction, such as:
     *      - if the contract at `to` address has code or not
     *      - if the `gasToken` is a contract or not
     *      It is the responsibility of the caller to perform such checks.
     * @param to Destination address of Safe transaction.
     * @param value Ether value of Safe transaction.
     * @param data Data payload of Safe transaction.
     * @param operation Operation type of Safe transaction.
     * @param safeTxGas Gas that should be used for the Safe transaction.
     * @param baseGas Gas costs that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
     * @param gasPrice Gas price that should be used for the payment calculation.
     * @param gasToken Token address (or 0 if ETH) that is used for the payment.
     * @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
     * @param signatures Signature data that should be verified.
     *                   Can be packed ECDSA signature ({bytes32 r}{bytes32 s}{uint8 v}), contract signature (EIP-1271) or approved hash.
     * @return success Boolean indicating transaction's success.
     */
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        bytes32 txHash;
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            bytes memory txHashData = encodeTransactionData(
                // Transaction info
                to,
                value,
                data,
                operation,
                safeTxGas,
                // Payment info
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                // Signature info
                nonce
            );
            // Increase nonce and execute transaction.
            nonce++;
            txHash = keccak256(txHashData);
            checkSignatures(txHash, txHashData, signatures);
        }
        address guard = getGuard();
        {
            if (guard != address(0)) {
                Guard(guard).checkTransaction(
                    // Transaction info
                    to,
                    value,
                    data,
                    operation,
                    safeTxGas,
                    // Payment info
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    // Signature info
                    signatures,
                    msg.sender
                );
            }
        }
        // We require some gas to emit the events (at least 2500) after the execution and some to perform code until the execution (500)
        // We also include the 1/64 in the check that is not send along with a call to counteract potential shortings because of EIP-150
        require(gasleft() >= ((safeTxGas * 64) / 63).max(safeTxGas + 2500) + 500, "GS010");
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            uint256 gasUsed = gasleft();
            // If the gasPrice is 0 we assume that nearly all available gas can be used (it is always more than safeTxGas)
            // We only substract 2500 (compared to the 3000 before) to ensure that the amount passed is still higher than safeTxGas
            success = execute(to, value, data, operation, gasPrice == 0 ? (gasleft() - 2500) : safeTxGas);
            gasUsed = gasUsed.sub(gasleft());
            // If no safeTxGas and no gasPrice was set (e.g. both are 0), then the internal tx is required to be successful
            // This makes it possible to use `estimateGas` without issues, as it searches for the minimum gas where the tx doesn't revert
            require(success || safeTxGas != 0 || gasPrice != 0, "GS013");
            // We transfer the calculated tx costs to the tx.origin to avoid sending it to intermediate contracts that have made calls
            uint256 payment = 0;
            if (gasPrice > 0) {
                payment = handlePayment(gasUsed, baseGas, gasPrice, gasToken, refundReceiver);
            }
            if (success) emit ExecutionSuccess(txHash, payment);
            else emit ExecutionFailure(txHash, payment);
        }
        {
            if (guard != address(0)) {
                Guard(guard).checkAfterExecution(txHash, success);
            }
        }
    }

    /**
     * @notice Handles the payment for a Safe transaction.
     * @param gasUsed Gas used by the Safe transaction.
     * @param baseGas Gas costs that are independent of the transaction execution (e.g. base transaction fee, signature check, payment of the refund).
     * @param gasPrice Gas price that should be used for the payment calculation.
     * @param gasToken Token address (or 0 if ETH) that is used for the payment.
     * @return payment The amount of payment made in the specified token.
     */
    function handlePayment(
        uint256 gasUsed,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver
    ) private returns (uint256 payment) {
        // solhint-disable-next-line avoid-tx-origin
        address payable receiver = refundReceiver == address(0) ? payable(tx.origin) : refundReceiver;
        if (gasToken == address(0)) {
            // For ETH we will only adjust the gas price to not be higher than the actual used gas price
            payment = gasUsed.add(baseGas).mul(gasPrice < tx.gasprice ? gasPrice : tx.gasprice);
            require(receiver.send(payment), "GS011");
        } else {
            payment = gasUsed.add(baseGas).mul(gasPrice);
            require(transferToken(gasToken, receiver, payment), "GS012");
        }
    }

    /**
     * @notice Checks whether the signature provided is valid for the provided data and hash. Reverts otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param data That should be signed (this is passed to an external validator contract)
     * @param signatures Signature data that should be verified.
     *                   Can be packed ECDSA signature ({bytes32 r}{bytes32 s}{uint8 v}), contract signature (EIP-1271) or approved hash.
     */
    function checkSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures) public view {
        // Load threshold to avoid multiple storage loads
        uint256 _threshold = threshold;
        // Check that a threshold is set
        require(_threshold > 0, "GS001");
        checkNSignatures(dataHash, data, signatures, _threshold);
    }

    /**
     * @notice Checks whether the signature provided is valid for the provided data and hash. Reverts otherwise.
     * @dev Since the EIP-1271 does an external call, be mindful of reentrancy attacks.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param data That should be signed (this is passed to an external validator contract)
     * @param signatures Signature data that should be verified.
     *                   Can be packed ECDSA signature ({bytes32 r}{bytes32 s}{uint8 v}), contract signature (EIP-1271) or approved hash.
     * @param requiredSignatures Amount of required valid signatures.
     */
    function checkNSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures, uint256 requiredSignatures) public view {
        // Check that the provided signature data is not too short
        require(signatures.length >= requiredSignatures.mul(65), "GS020");
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < requiredSignatures; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            if (v == 0) {
                require(keccak256(data) == dataHash, "GS027");
                // If v is 0 then it is a contract signature
                // When handling contract signatures the address of the contract is encoded into r
                currentOwner = address(uint160(uint256(r)));

                // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
                // This check is not completely accurate, since it is possible that more signatures than the threshold are send.
                // Here we only check that the pointer is not pointing inside the part that is being processed
                require(uint256(s) >= requiredSignatures.mul(65), "GS021");

                // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
                require(uint256(s).add(32) <= signatures.length, "GS022");

                // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
                uint256 contractSignatureLen;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    contractSignatureLen := mload(add(add(signatures, s), 0x20))
                }
                require(uint256(s).add(32).add(contractSignatureLen) <= signatures.length, "GS023");

                // Check signature
                bytes memory contractSignature;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
                    contractSignature := add(add(signatures, s), 0x20)
                }
                require(ISignatureValidator(currentOwner).isValidSignature(data, contractSignature) == EIP1271_MAGIC_VALUE, "GS024");
            } else if (v == 1) {
                // If v is 1 then it is an approved hash
                // When handling approved hashes the address of the approver is encoded into r
                currentOwner = address(uint160(uint256(r)));
                // Hashes are automatically approved by the sender of the message or when they have been pre-approved via a separate transaction
                require(msg.sender == currentOwner || approvedHashes[currentOwner][dataHash] != 0, "GS025");
            } else if (v > 30) {
                // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
                // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
                currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            } else {
                // Default is the ecrecover flow with the provided data hash
                // Use ecrecover with the messageHash for EOA signatures
                currentOwner = ecrecover(dataHash, v, r, s);
            }
            require(currentOwner > lastOwner && owners[currentOwner] != address(0) && currentOwner != SENTINEL_OWNERS, "GS026");
            lastOwner = currentOwner;
        }
    }

    /**
     * @notice Marks hash `hashToApprove` as approved.
     * @dev This can be used with a pre-approved hash transaction signature.
     *      IMPORTANT: The approved hash stays approved forever. There's no revocation mechanism, so it behaves similarly to ECDSA signatures
     * @param hashToApprove The hash to mark as approved for signatures that are verified by this contract.
     */
    function approveHash(bytes32 hashToApprove) external {
        require(owners[msg.sender] != address(0), "GS030");
        approvedHashes[msg.sender][hashToApprove] = 1;
        emit ApproveHash(hashToApprove, msg.sender);
    }

    /**
     * @notice Returns the ID of the chain the contract is currently deployed on.
     * @return The ID of the current chain as a uint256.
     */
    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @dev Returns the domain separator for this contract, as defined in the EIP-712 standard.
     * @return bytes32 The domain separator hash.
     */
    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), this));
    }

    /**
     * @notice Returns the pre-image of the transaction hash (see getTransactionHash).
     * @param to Destination address.
     * @param value Ether value.
     * @param data Data payload.
     * @param operation Operation type.
     * @param safeTxGas Gas that should be used for the safe transaction.
     * @param baseGas Gas costs for that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
     * @param gasPrice Maximum gas price that should be used for this transaction.
     * @param gasToken Token address (or 0 if ETH) that is used for the payment.
     * @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
     * @param _nonce Transaction nonce.
     * @return Transaction hash bytes.
     */
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes memory) {
        bytes32 safeTxHash = keccak256(
            abi.encode(
                SAFE_TX_TYPEHASH,
                to,
                value,
                keccak256(data),
                operation,
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                _nonce
            )
        );
        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), safeTxHash);
    }

    /**
     * @notice Returns transaction hash to be signed by owners.
     * @param to Destination address.
     * @param value Ether value.
     * @param data Data payload.
     * @param operation Operation type.
     * @param safeTxGas Fas that should be used for the safe transaction.
     * @param baseGas Gas costs for data used to trigger the safe transaction.
     * @param gasPrice Maximum gas price that should be used for this transaction.
     * @param gasToken Token address (or 0 if ETH) that is used for the payment.
     * @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
     * @param _nonce Transaction nonce.
     * @return Transaction hash.
     */
    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes32) {
        return keccak256(encodeTransactionData(to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, _nonce));
    }
}

//********************************************************************************************/
//  ___           _       ___               _         _    _ _
// | __| _ ___ __| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__
// | _| '_/ -_|_-< ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
// |_||_| \___/__/_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
///* Copyright (C) 2022 - Renaud Dubois - This file is part of FCL (Fresh CryptoLib) project
///* License: This software is licensed under MIT License
///* This Code may be reused including license and copyright notice.
///* See LICENSE file at the root folder of the project.
///* FILE: FCL_elliptic.sol
///*
///*
///* DESCRIPTION: Implementation of the WebAuthn Authentication mechanism
///* https://www.w3.org/TR/webauthn-2/#sctn-intro
///* Original code extracted from https://github.com/btchip/Webauthn.sol
//**************************************************************************************/
//* WARNING: this code SHALL not be used for non prime order curves for security reasons.
// Code is optimized for a=-3 only curves with prime order, constant like -1, -2 shall be replaced
// if ever used for other curve than sec256R1
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import {Base64Url} from "./utils/Base64Url.sol";
import {FCL_Elliptic_ZZ} from "./FCL_elliptic.sol";
import {FCL_ecdsa} from "./FCL_ecdsa.sol";

import {FCL_ecdsa_utils} from "./FCL_ecdsa_utils.sol";

library FCL_WebAuthn {
    error InvalidAuthenticatorData();
    error InvalidClientData();
    error InvalidSignature();

    function WebAuthn_format(
        bytes calldata authenticatorData,
        bytes1 authenticatorDataFlagMask,
        bytes calldata clientData,
        bytes32 clientChallenge,
        uint256 clientChallengeDataOffset,
        uint256[2] calldata // rs
    ) internal pure returns (bytes32 result) {
        // Let the caller check if User Presence (0x01) or User Verification (0x04) are set
        {
            if ((authenticatorData[32] & authenticatorDataFlagMask) != authenticatorDataFlagMask) {
                revert InvalidAuthenticatorData();
            }
            // Verify that clientData commits to the expected client challenge
            // Use the Base64Url encoding which omits padding characters to match WebAuthn Specification
            string memory challengeEncoded = Base64Url.encode(abi.encodePacked(clientChallenge));
            bytes memory challengeExtracted = new bytes(
            bytes(challengeEncoded).length
        );

            assembly {
                calldatacopy(
                    add(challengeExtracted, 32),
                    add(clientData.offset, clientChallengeDataOffset),
                    mload(challengeExtracted)
                )
            }

            bytes32 moreData; //=keccak256(abi.encodePacked(challengeExtracted));
            assembly {
                moreData := keccak256(add(challengeExtracted, 32), mload(challengeExtracted))
            }

            if (keccak256(abi.encodePacked(bytes(challengeEncoded))) != moreData) {
                revert InvalidClientData();
            }
        } //avoid stack full

        // Verify the signature over sha256(authenticatorData || sha256(clientData))
        bytes memory verifyData = new bytes(authenticatorData.length + 32);

        assembly {
            calldatacopy(add(verifyData, 32), authenticatorData.offset, authenticatorData.length)
        }

        bytes32 more = sha256(clientData);
        assembly {
            mstore(add(verifyData, add(authenticatorData.length, 32)), more)
        }

        return sha256(verifyData);
    }

    function  checkSignature (
        bytes calldata authenticatorData,
        bytes1 authenticatorDataFlagMask,
        bytes calldata clientData,
        bytes32 clientChallenge,
        uint256 clientChallengeDataOffset,
        uint256[2] calldata rs,
        uint256[2] calldata Q
    ) internal view returns (bool) {
        return checkSignature(authenticatorData, authenticatorDataFlagMask, clientData, clientChallenge, clientChallengeDataOffset, rs, Q[0], Q[1]);
    }

    function  checkSignature (
        bytes calldata authenticatorData,
        bytes1 authenticatorDataFlagMask,
        bytes calldata clientData,
        bytes32 clientChallenge,
        uint256 clientChallengeDataOffset,
        uint256[2] calldata rs,
        uint256 Qx,
        uint256 Qy
    ) internal view returns (bool) {
        // Let the caller check if User Presence (0x01) or User Verification (0x04) are set

        bytes32 message = FCL_WebAuthn.WebAuthn_format(
            authenticatorData, authenticatorDataFlagMask, clientData, clientChallenge, clientChallengeDataOffset, rs
        );

        bool result = FCL_ecdsa_utils.ecdsa_verify(message, rs, Qx, Qy);

        return result;
    }

    function checkSignature_prec(
        bytes calldata authenticatorData,
        bytes1 authenticatorDataFlagMask,
        bytes calldata clientData,
        bytes32 clientChallenge,
        uint256 clientChallengeDataOffset,
        uint256[2] calldata rs,
        address dataPointer
    ) internal view returns (bool) {
        // Let the caller check if User Presence (0x01) or User Verification (0x04) are set

        bytes32 message = FCL_WebAuthn.WebAuthn_format(
            authenticatorData, authenticatorDataFlagMask, clientData, clientChallenge, clientChallengeDataOffset, rs
        );

        bool result = FCL_ecdsa.ecdsa_precomputed_verify(message, rs, dataPointer);

        return result;
    }

    //beware that this implementation will not be compliant with EOF
    function checkSignature_hackmem(
        bytes calldata authenticatorData,
        bytes1 authenticatorDataFlagMask,
        bytes calldata clientData,
        bytes32 clientChallenge,
        uint256 clientChallengeDataOffset,
        uint256[2] calldata rs,
        uint256 dataPointer
    ) internal view returns (bool) {
        // Let the caller check if User Presence (0x01) or User Verification (0x04) are set

        bytes32 message = FCL_WebAuthn.WebAuthn_format(
            authenticatorData, authenticatorDataFlagMask, clientData, clientChallenge, clientChallengeDataOffset, rs
        );

        bool result = FCL_Elliptic_ZZ.ecdsa_precomputed_hackmem(message, rs, dataPointer);

        return result;
    }
}

pragma solidity 0.8.21;

/**
 * @title EIP1271
 * @dev Abstract contract for the EIP1271 standard.
 */
abstract contract EIP1271 {
    bytes4 internal constant EIP1271_MAGICVALUE_BYTES32 = 0x1626ba7e;
    bytes4 internal constant EIP1271_MAGICVALUE_BYTES = 0x20c13b0b;

    /**
     * @dev Verifies the validity of a signature for a given hash.
     * @param _hash The hash to be verified.
     * @param _signature The signature to be checked.
     * @return magicValue A boolean indicating whether the signature is valid or not.
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        view
        virtual
        returns (bytes4 magicValue);

    /**
     * @dev Verifies the validity of a signature.
     * @param _data The data to be verified.
     * @param _signature The signature to be verified.
     * @return magicValue A boolean indicating whether the signature is valid or not.
     */
    function isValidSignature(bytes memory _data, bytes memory _signature)
        external
        view
        virtual
        returns (bytes4 magicValue);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title IProxy - Helper interface to access the singleton address of the Proxy on-chain.
 * @author Richard Meissner - @rmeissner
 */
interface IProxy {
    function masterCopy() external view returns (address);
}

/**
 * @title SafeProxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
 * @author Stefan George - <[email protected]>
 * @author Richard Meissner - <[email protected]>
 */
contract SafeProxy {
    // Singleton always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
    address internal singleton;

    /**
     * @notice Constructor function sets address of singleton contract.
     * @param _singleton Singleton address.
     */
    constructor(address _singleton) {
        require(_singleton != address(0), "Invalid singleton address provided");
        singleton = _singleton;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    fallback() external payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let _singleton := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, _singleton)
                return(0, 0x20)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "./SafeProxy.sol";

/**
 * @title IProxyCreationCallback
 * @dev An interface for a contract that implements a callback function to be executed after the creation of a proxy instance.
 */
interface IProxyCreationCallback {
    /**
     * @dev Function to be called after the creation of a SafeProxy instance.
     * @param proxy The newly created SafeProxy instance.
     * @param _singleton The address of the singleton contract used to create the proxy.
     * @param initializer The initializer function call data.
     * @param saltNonce The nonce used to generate the salt for the proxy deployment.
     */
    function proxyCreated(SafeProxy proxy, address _singleton, bytes calldata initializer, uint256 saltNonce) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "./Executor.sol";

/**
 * @title Module Manager - A contract managing Safe modules
 * @notice Modules are extensions with unlimited access to a Safe that can be added to a Safe by its owners.
           ⚠️ WARNING: Modules are a security risk since they can execute arbitrary transactions, 
           so only trusted and audited modules should be added to a Safe. A malicious module can
           completely takeover a Safe.
 * @author Stefan George - @Georgi87
 * @author Richard Meissner - @rmeissner
 */
abstract contract ModuleManager is SelfAuthorized, Executor {
    event EnabledModule(address indexed module);
    event DisabledModule(address indexed module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    address internal constant SENTINEL_MODULES = address(0x1);

    mapping(address => address) internal modules;

    /**
     * @notice Setup function sets the initial storage of the contract.
     *         Optionally executes a delegate call to another contract to setup the modules.
     * @param to Optional destination address of call to execute.
     * @param data Optional data of call to execute.
     */
    function setupModules(address to, bytes memory data) internal {
        require(modules[SENTINEL_MODULES] == address(0), "GS100");
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
        if (to != address(0)) {
            require(isContract(to), "GS002");
            // Setup has to complete successfully or transaction fails.
            require(execute(to, 0, data, Enum.Operation.DelegateCall, type(uint256).max), "GS000");
        }
    }

    /**
     * @notice Enables the module `module` for the Safe.
     * @dev This can only be done via a Safe transaction.
     * @param module Module to be whitelisted.
     */
    function enableModule(address module) public authorized {
        // Module address cannot be null or sentinel.
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        // Module cannot be added twice.
        require(modules[module] == address(0), "GS102");
        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }

    /**
     * @notice Disables the module `module` for the Safe.
     * @dev This can only be done via a Safe transaction.
     * @param prevModule Previous module in the modules linked list.
     * @param module Module to be removed.
     */
    function disableModule(address prevModule, address module) public authorized {
        // Validate module address and check that it corresponds to module index.
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        require(modules[prevModule] == module, "GS103");
        modules[prevModule] = modules[module];
        modules[module] = address(0);
        emit DisabledModule(module);
    }

    /**
     * @notice Execute `operation` (0: Call, 1: DelegateCall) to `to` with `value` (Native Token)
     * @dev Function is virtual to allow overriding for L2 singleton to emit an event for indexing.
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction.
     * @return success Boolean flag indicating if the call succeeded.
     */
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public virtual returns (bool success) {
        // Only whitelisted modules are allowed.
        require(msg.sender != SENTINEL_MODULES && modules[msg.sender] != address(0), "GS104");
        // Execute transaction without further confirmations.
        success = execute(to, value, data, operation, type(uint256).max);
        if (success) emit ExecutionFromModuleSuccess(msg.sender);
        else emit ExecutionFromModuleFailure(msg.sender);
    }

    /**
     * @notice Execute `operation` (0: Call, 1: DelegateCall) to `to` with `value` (Native Token) and return data
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction.
     * @return success Boolean flag indicating if the call succeeded.
     * @return returnData Data returned by the call.
     */
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public returns (bool success, bytes memory returnData) {
        success = execTransactionFromModule(to, value, data, operation);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load free memory location
            let ptr := mload(0x40)
            // We allocate memory for the return data by setting the free memory location to
            // current free memory location + data size + 32 bytes for data size value
            mstore(0x40, add(ptr, add(returndatasize(), 0x20)))
            // Store the size
            mstore(ptr, returndatasize())
            // Store the data
            returndatacopy(add(ptr, 0x20), 0, returndatasize())
            // Point the return data to the correct memory location
            returnData := ptr
        }
    }

    /**
     * @notice Returns if an module is enabled
     * @return True if the module is enabled
     */
    function isModuleEnabled(address module) public view returns (bool) {
        return SENTINEL_MODULES != module && modules[module] != address(0);
    }

    /**
     * @notice Returns an array of modules.
     *         If all entries fit into a single page, the next pointer will be 0x1.
     *         If another page is present, next will be the last element of the returned array.
     * @param start Start of the page. Has to be a module or start pointer (0x1 address)
     * @param pageSize Maximum number of modules that should be returned. Has to be > 0
     * @return array Array of modules.
     * @return next Start of the next page.
     */
    function getModulesPaginated(address start, uint256 pageSize) external view returns (address[] memory array, address next) {
        require(start == SENTINEL_MODULES || isModuleEnabled(start), "GS105");
        require(pageSize > 0, "GS106");
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 moduleCount = 0;
        next = modules[start];
        while (next != address(0) && next != SENTINEL_MODULES && moduleCount < pageSize) {
            array[moduleCount] = next;
            next = modules[next];
            moduleCount++;
        }

        /**
          Because of the argument validation, we can assume that the loop will always iterate over the valid module list values
          and the `next` variable will either be an enabled module or a sentinel address (signalling the end). 
          
          If we haven't reached the end inside the loop, we need to set the next pointer to the last element of the modules array
          because the `next` variable (which is a module by itself) acting as a pointer to the start of the next page is neither 
          included to the current page, nor will it be included in the next one if you pass it as a start.
        */
        if (next != SENTINEL_MODULES) {
            next = array[moduleCount - 1];
        }
        // Set correct size of returned array
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(array, moduleCount)
        }
    }

    /**
     * @notice Returns true if `account` is a contract.
     * @dev This function will return false if invoked during the constructor of a contract,
     *      as the code is not actually created until after the constructor finishes.
     * @param account The address being queried
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/SelfAuthorized.sol";

/**
 * @title OwnerManager - Manages Safe owners and a threshold to authorize transactions.
 * @dev Uses a linked list to store the owners because the code generate by the solidity compiler
 *      is more efficient than using a dynamic array.
 * @author Stefan George - @Georgi87
 * @author Richard Meissner - @rmeissner
 */
abstract contract OwnerManager is SelfAuthorized {
    event AddedOwner(address indexed owner);
    event RemovedOwner(address indexed owner);
    event ChangedThreshold(uint256 threshold);

    address internal constant SENTINEL_OWNERS = address(0x1);

    mapping(address => address) internal owners;
    uint256 internal ownerCount;
    uint256 internal threshold;

    /**
     * @notice Sets the initial storage of the contract.
     * @param _owners List of Safe owners.
     * @param _threshold Number of required confirmations for a Safe transaction.
     */
    function setupOwners(address[] memory _owners, uint256 _threshold) internal {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function can only be called once.
        require(threshold == 0, "GS200");
        // Validate that threshold is smaller than number of added owners.
        require(_threshold <= _owners.length, "GS201");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "GS202");
        // Initializing Safe owners.
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < _owners.length; i++) {
            // Owner address cannot be null.
            address owner = _owners[i];
            require(owner != address(0) && owner != SENTINEL_OWNERS && owner != address(this) && currentOwner != owner, "GS203");
            // No duplicate owners allowed.
            require(owners[owner] == address(0), "GS204");
            owners[currentOwner] = owner;
            currentOwner = owner;
        }
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    /**
     * @notice Adds the owner `owner` to the Safe and updates the threshold to `_threshold`.
     * @dev This can only be done via a Safe transaction.
     * @param owner New owner address.
     * @param _threshold New threshold.
     */
    function addOwnerWithThreshold(address owner, uint256 _threshold) public authorized {
        // Owner address cannot be null, the sentinel or the Safe itself.
        require(owner != address(0) && owner != SENTINEL_OWNERS && owner != address(this), "GS203");
        // No duplicate owners allowed.
        require(owners[owner] == address(0), "GS204");
        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /**
     * @notice Removes the owner `owner` from the Safe and updates the threshold to `_threshold`.
     * @dev This can only be done via a Safe transaction.
     * @param prevOwner Owner that pointed to the owner to be removed in the linked list
     * @param owner Owner address to be removed.
     * @param _threshold New threshold.
     */
    function removeOwner(address prevOwner, address owner, uint256 _threshold) public authorized {
        // Only allow to remove an owner, if threshold can still be reached.
        require(ownerCount - 1 >= _threshold, "GS201");
        // Validate owner address and check that it corresponds to owner index.
        require(owner != address(0) && owner != SENTINEL_OWNERS, "GS203");
        require(owners[prevOwner] == owner, "GS205");
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);
        ownerCount--;
        emit RemovedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /**
     * @notice Replaces the owner `oldOwner` in the Safe with `newOwner`.
     * @dev This can only be done via a Safe transaction.
     * @param prevOwner Owner that pointed to the owner to be replaced in the linked list
     * @param oldOwner Owner address to be replaced.
     * @param newOwner New owner address.
     */
    function swapOwner(address prevOwner, address oldOwner, address newOwner) public authorized {
        // Owner address cannot be null, the sentinel or the Safe itself.
        require(newOwner != address(0) && newOwner != SENTINEL_OWNERS && newOwner != address(this), "GS203");
        // No duplicate owners allowed.
        require(owners[newOwner] == address(0), "GS204");
        // Validate oldOwner address and check that it corresponds to owner index.
        require(oldOwner != address(0) && oldOwner != SENTINEL_OWNERS, "GS203");
        require(owners[prevOwner] == oldOwner, "GS205");
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    /**
     * @notice Changes the threshold of the Safe to `_threshold`.
     * @dev This can only be done via a Safe transaction.
     * @param _threshold New threshold.
     */
    function changeThreshold(uint256 _threshold) public authorized {
        // Validate that threshold is smaller than number of owners.
        require(_threshold <= ownerCount, "GS201");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "GS202");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    /**
     * @notice Returns the number of required confirmations for a Safe transaction aka the threshold.
     * @return Threshold number.
     */
    function getThreshold() public view returns (uint256) {
        return threshold;
    }

    /**
     * @notice Returns if `owner` is an owner of the Safe.
     * @return Boolean if owner is an owner of the Safe.
     */
    function isOwner(address owner) public view returns (bool) {
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

    /**
     * @notice Returns a list of Safe owners.
     * @return Array of Safe owners.
     */
    function getOwners() public view returns (address[] memory) {
        address[] memory array = new address[](ownerCount);

        // populate return array
        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while (currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index++;
        }
        return array;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/SelfAuthorized.sol";

/**
 * @title Fallback Manager - A contract managing fallback calls made to this contract
 * @author Richard Meissner - @rmeissner
 */
abstract contract FallbackManager is SelfAuthorized {
    event ChangedFallbackHandler(address indexed handler);

    // keccak256("fallback_manager.handler.address")
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT = 0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;

    /**
     *  @notice Internal function to set the fallback handler.
     *  @param handler contract to handle fallback calls.
     */
    function internalSetFallbackHandler(address handler) internal {
        /*
            If a fallback handler is set to self, then the following attack vector is opened:
            Imagine we have a function like this:
            function withdraw() internal authorized {
                withdrawalAddress.call.value(address(this).balance)("");
            }

            If the fallback method is triggered, the fallback handler appends the msg.sender address to the calldata and calls the fallback handler.
            A potential attacker could call a Safe with the 3 bytes signature of a withdraw function. Since 3 bytes do not create a valid signature,
            the call would end in a fallback handler. Since it appends the msg.sender address to the calldata, the attacker could craft an address 
            where the first 3 bytes of the previous calldata + the first byte of the address make up a valid function signature. The subsequent call would result in unsanctioned access to Safe's internal protected methods.
            For some reason, solidity matches the first 4 bytes of the calldata to a function signature, regardless if more data follow these 4 bytes.
        */
        require(handler != address(this), "GS400");

        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, handler)
        }
    }

    /**
     * @notice Set Fallback Handler to `handler` for the Safe.
     * @dev Only fallback calls without value and with data will be forwarded.
     *      This can only be done via a Safe transaction.
     *      Cannot be set to the Safe itself.
     * @param handler contract to handle fallback calls.
     */
    function setFallbackHandler(address handler) public authorized {
        internalSetFallbackHandler(handler);
        emit ChangedFallbackHandler(handler);
    }

    // @notice Forwards all calls to the fallback handler if set. Returns 0 if no handler is set.
    // @dev Appends the non-padded caller address to the calldata to be optionally used in the handler
    //      The handler can make us of `HandlerContext.sol` to extract the address.
    //      This is done because in the next call frame the `msg.sender` will be FallbackManager's address
    //      and having the original caller address may enable additional verification scenarios.
    // solhint-disable-next-line payable-fallback,no-complex-fallback
    fallback() external {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let handler := sload(slot)
            if iszero(handler) {
                return(0, 0)
            }
            calldatacopy(0, 0, calldatasize())
            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            mstore(calldatasize(), shl(96, caller()))
            // Add 20 bytes for the address appended add the end
            let success := call(gas(), handler, 0, 0, add(calldatasize(), 20), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(success) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "../interfaces/IERC165.sol";

interface Guard is IERC165 {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

abstract contract BaseGuard is Guard {
    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(Guard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }
}

/**
 * @title Guard Manager - A contract managing transaction guards which perform pre and post-checks on Safe transactions.
 * @author Richard Meissner - @rmeissner
 */
abstract contract GuardManager is SelfAuthorized {
    event ChangedGuard(address indexed guard);

    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    /**
     * @dev Set a guard that checks transactions before execution
     *      This can only be done via a Safe transaction.
     *      ⚠️ IMPORTANT: Since a guard has full power to block Safe transaction execution,
     *        a broken guard can cause a denial of service for the Safe. Make sure to carefully
     *        audit the guard code and design recovery mechanisms.
     * @notice Set Transaction Guard `guard` for the Safe. Make sure you trust the guard.
     * @param guard The address of the guard to be used or the 0 address to disable the guard
     */
    function setGuard(address guard) external authorized {
        if (guard != address(0)) {
            require(Guard(guard).supportsInterface(type(Guard).interfaceId), "GS300");
        }
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }

    /**
     * @dev Internal method to retrieve the current guard
     *      We do not have a public method because we're short on bytecode size limit,
     *      to retrieve the guard address, one can use `getStorageAt` from `StorageAccessible` contract
     *      with the slot `GUARD_STORAGE_SLOT`
     * @return guard The address of the guard
     */
    function getGuard() internal view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            guard := sload(slot)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title NativeCurrencyPaymentFallback - A contract that has a fallback to accept native currency payments.
 * @author Richard Meissner - @rmeissner
 */
abstract contract NativeCurrencyPaymentFallback {
    event SafeReceived(address indexed sender, uint256 value);

    /**
     * @notice Receive function accepts native currency transactions.
     * @dev Emits an event with sender and received value.
     */
    receive() external payable {
        emit SafeReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Singleton - Base for singleton contracts (should always be the first super contract)
 *        This contract is tightly coupled to our proxy contract (see `proxies/SafeProxy.sol`)
 * @author Richard Meissner - @rmeissner
 */
abstract contract Singleton {
    // singleton always has to be the first declared variable to ensure the same location as in the Proxy contract.
    // It should also always be ensured the address is stored alone (uses a full word)
    address private singleton;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SignatureDecoder - Decodes signatures encoded as bytes
 * @author Richard Meissner - @rmeissner
 */
abstract contract SignatureDecoder {
    /**
     * @notice Splits signature bytes into `uint8 v, bytes32 r, bytes32 s`.
     * @dev Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
     *      The signature format is a compact form of {bytes32 r}{bytes32 s}{uint8 v}
     *      Compact means uint8 is not padded to 32 bytes.
     * @param pos Which signature to read.
     *            A prior bounds check of this parameter should be performed, to avoid out of bounds access.
     * @param signatures Concatenated {r, s, v} signatures.
     * @return v Recovery ID or Safe signature type.
     * @return r Output value r of the signature.
     * @return s Output value s of the signature.
     */
    function signatureSplit(bytes memory signatures, uint256 pos) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            /**
             * Here we are loading the last 32 bytes, including 31 bytes
             * of 's'. There is no 'mload8' to do this.
             * 'byte' is not working due to the Solidity parser, so lets
             * use the second best option, 'and'
             */
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SecuredTokenTransfer - Secure token transfer.
 * @author Richard Meissner - @rmeissner
 */
abstract contract SecuredTokenTransfer {
    /**
     * @notice Transfers a token and returns a boolean if it was a success
     * @dev It checks the return data of the transfer call and returns true if the transfer was successful.
     *      It doesn't check if the `token` address is a contract or not.
     * @param token Token that should be transferred
     * @param receiver Receiver to whom the token should be transferred
     * @param amount The amount of tokens that should be transferred
     * @return transferred Returns true if the transfer was successful
     */
    function transferToken(address token, address receiver, uint256 amount) internal returns (bool transferred) {
        // 0xa9059cbb - keccack("transfer(address,uint256)")
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, receiver, amount);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // We write the return value to scratch space.
            // See https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory
            let success := call(sub(gas(), 10000), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            switch returndatasize()
            case 0 {
                transferred := success
            }
            case 0x20 {
                transferred := iszero(or(iszero(success), iszero(mload(0))))
            }
            default {
                transferred := 0
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title StorageAccessible - A generic base contract that allows callers to access all internal storage.
 * @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
 *         It removes a method from the original contract not needed for the Safe contracts.
 * @author Gnosis Developers
 */
abstract contract StorageAccessible {
    /**
     * @notice Reads `length` bytes of storage in the currents contract
     * @param offset - the offset in the current contract's storage in words to start reading from
     * @param length - the number of words (32 bytes) of data to read
     * @return the bytes that were read.
     */
    function getStorageAt(uint256 offset, uint256 length) public view returns (bytes memory) {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    /**
     * @dev Performs a delegatecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static).
     *
     * This method reverts with data equal to `abi.encode(bool(success), bytes(response))`.
     * Specifically, the `returndata` after a call to this method will be:
     * `success:bool || response.length:uint256 || response:bytes`.
     *
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulateAndRevert(address targetContract, bytes memory calldataPayload) external {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let success := delegatecall(gas(), targetContract, add(calldataPayload, 0x20), mload(calldataPayload), 0, 0)

            mstore(0x00, success)
            mstore(0x20, returndatasize())
            returndatacopy(0x40, 0, returndatasize())
            revert(0, add(returndatasize(), 0x40))
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

contract ISignatureValidatorConstants {
    // bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x20c13b0b;
}

abstract contract ISignatureValidator is ISignatureValidatorConstants {
    /**
     * @notice Legacy EIP1271 method to validate a signature.
     * @param _data Arbitrary length data signed on the behalf of address(this).
     * @param _signature Signature byte array associated with _data.
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory _data, bytes memory _signature) public view virtual returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SafeMath
 * @notice Math operations with safety checks that revert on error (overflow/underflow)
 */
library SafeMath {
    /**
     * @notice Multiplies two numbers, reverts on overflow.
     * @param a First number
     * @param b Second number
     * @return Product of a and b
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @notice Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     * @param a First number
     * @param b Second number
     * @return Difference of a and b
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @notice Adds two numbers, reverts on overflow.
     * @param a First number
     * @param b Second number
     * @return Sum of a and b
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @notice Returns the largest of two numbers.
     * @param a First number
     * @param b Second number
     * @return Largest of a and b
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @dev Encode (without '=' padding) 
 * @author evmbrahmin, adapted from hiromin's Base64URL libraries
 */
library Base64Url {
    /**
     * @dev Base64Url Encoding Table
     */
    string internal constant ENCODING_TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // Load the table into memory
        string memory table = ENCODING_TABLE;

        string memory result = new string(4 * ((data.length + 2) / 3));

        // @solidity memory-safe-assembly
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // Remove the padding adjustment logic
            switch mod(mload(data), 3)
            case 1 {
                // Adjust for the last byte of data
                resultPtr := sub(resultPtr, 2)
            }
            case 2 {
                // Adjust for the last two bytes of data
                resultPtr := sub(resultPtr, 1)
            }
            
            // Set the correct length of the result string
            mstore(result, sub(resultPtr, add(result, 32)))
        }

        return result;  
    }
}

//********************************************************************************************/
//  ___           _       ___               _         _    _ _
// | __| _ ___ __| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__
// | _| '_/ -_|_-< ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
// |_||_| \___/__/_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
//                                |__/|_|
///* Copyright (C) 2022 - Renaud Dubois - This file is part of FCL (Fresh CryptoLib) project
///* License: This software is licensed under MIT License
///* This Code may be reused including license and copyright notice.
///* See LICENSE file at the root folder of the project.
///* FILE: FCL_elliptic.sol
///*
///*
///* DESCRIPTION: modified XYZZ system coordinates for EVM elliptic point multiplication
///*  optimization
///*
//**************************************************************************************/
//* WARNING: this code SHALL not be used for non prime order curves for security reasons.
// Code is optimized for a=-3 only curves with prime order, constant like -1, -2 shall be replaced
// if ever used for other curve than sec256R1
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

library FCL_Elliptic_ZZ {
    // Set parameters for curve sec256r1.

    // address of the ModExp precompiled contract (Arbitrary-precision exponentiation under modulo)
    address constant MODEXP_PRECOMPILE = 0x0000000000000000000000000000000000000005;
    //curve prime field modulus
    uint256 constant p = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
    //short weierstrass first coefficient
    uint256 constant a = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC;
    //short weierstrass second coefficient
    uint256 constant b = 0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B;
    //generating point affine coordinates
    uint256 constant gx = 0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296;
    uint256 constant gy = 0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5;
    //curve order (number of points)
    uint256 constant n = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;
    /* -2 mod p constant, used to speed up inversion and doubling (avoid negation)*/
    uint256 constant minus_2 = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFD;
    /* -2 mod n constant, used to speed up inversion*/
    uint256 constant minus_2modn = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC63254F;

    uint256 constant minus_1 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    //P+1 div 4
    uint256 constant pp1div4=0x3fffffffc0000000400000000000000000000000400000000000000000000000;
    //arbitrary constant to express no quadratic residuosity
    uint256 constant _NOTSQUARE=0xFFFFFFFF00000002000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 constant _NOTONCURVE=0xFFFFFFFF00000003000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * /* inversion mod n via a^(n-2), use of precompiled using little Fermat theorem
     */
    function FCL_nModInv(uint256 u) internal view returns (uint256 result) {
        assembly {
            let pointer := mload(0x40)
            // Define length of base, exponent and modulus. 0x20 == 32 bytes
            mstore(pointer, 0x20)
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), 0x20)
            // Define variables base, exponent and modulus
            mstore(add(pointer, 0x60), u)
            mstore(add(pointer, 0x80), minus_2modn)
            mstore(add(pointer, 0xa0), n)

            // Call the precompiled contract 0x05 = ModExp
            if iszero(staticcall(not(0), 0x05, pointer, 0xc0, pointer, 0x20)) { revert(0, 0) }
            result := mload(pointer)
        }
    }
    /**
     * /* @dev inversion mod nusing little Fermat theorem via a^(n-2), use of precompiled
     */

    function FCL_pModInv(uint256 u) internal view returns (uint256 result) {
        assembly {
            let pointer := mload(0x40)
            // Define length of base, exponent and modulus. 0x20 == 32 bytes
            mstore(pointer, 0x20)
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), 0x20)
            // Define variables base, exponent and modulus
            mstore(add(pointer, 0x60), u)
            mstore(add(pointer, 0x80), minus_2)
            mstore(add(pointer, 0xa0), p)

            // Call the precompiled contract 0x05 = ModExp
            if iszero(staticcall(not(0), 0x05, pointer, 0xc0, pointer, 0x20)) { revert(0, 0) }
            result := mload(pointer)
        }
    }

    //Coron projective shuffling, take as input alpha as blinding factor
   function ecZZ_Coronize(uint256 alpha, uint256 x, uint256 y,  uint256 zz, uint256 zzz) internal pure  returns (uint256 x3, uint256 y3, uint256 zz3, uint256 zzz3)
   {
       
        uint256 alpha2=mulmod(alpha,alpha,p);
       
        x3=mulmod(alpha2, x,p); //alpha^-2.x
        y3=mulmod(mulmod(alpha, alpha2,p), y,p);

        zz3=mulmod(zz,alpha2,p);//alpha^2 zz
        zzz3=mulmod(zzz,mulmod(alpha, alpha2,p),p);//alpha^3 zzz
        
        return (x3, y3, zz3, zzz3);
   }


 function ecZZ_Add(uint256 x1, uint256 y1, uint256 zz1, uint256 zzz1, uint256 x2, uint256 y2, uint256 zz2, uint256 zzz2) internal pure  returns (uint256 x3, uint256 y3, uint256 zz3, uint256 zzz3)
  {
    uint256 u1=mulmod(x1,zz2,p); // U1 = X1*ZZ2
    uint256 u2=mulmod(x2, zz1,p);               //  U2 = X2*ZZ1
    u2=addmod(u2, p-u1, p);//  P = U2-U1
    x1=mulmod(u2, u2, p);//PP
    x2=mulmod(x1, u2, p);//PPP
    
    zz3=mulmod(x1, mulmod(zz1, zz2, p),p);//ZZ3 = ZZ1*ZZ2*PP  
    zzz3=mulmod(zzz1, mulmod(zzz2, x2, p),p);//ZZZ3 = ZZZ1*ZZZ2*PPP

    zz1=mulmod(y1, zzz2,p);  // S1 = Y1*ZZZ2
    zz2=mulmod(y2, zzz1, p);    // S2 = Y2*ZZZ1 
    zz2=addmod(zz2, p-zz1, p);//R = S2-S1
    zzz1=mulmod(u1, x1,p); //Q = U1*PP
    x3= addmod(addmod(mulmod(zz2, zz2, p), p-x2,p), mulmod(minus_2, zzz1,p),p); //X3 = R2-PPP-2*Q
    y3=addmod( mulmod(zz2, addmod(zzz1, p-x3, p),p), p-mulmod(zz1, x2, p),p);//R*(Q-X3)-S1*PPP

    return (x3, y3, zz3, zzz3);
  }

/// @notice Calculate one modular square root of a given integer. Assume that p=3 mod 4.
/// @dev Uses the ModExp precompiled contract at address 0x05 for fast computation using little Fermat theorem
/// @param self The integer of which to find the modular inverse
/// @return result The modular inverse of the input integer. If the modular inverse doesn't exist, it revert the tx

function SqrtMod(uint256 self) internal view returns (uint256 result){
 assembly ("memory-safe") {
        // load the free memory pointer value
        let pointer := mload(0x40)

        // Define length of base (Bsize)
        mstore(pointer, 0x20)
        // Define the exponent size (Esize)
        mstore(add(pointer, 0x20), 0x20)
        // Define the modulus size (Msize)
        mstore(add(pointer, 0x40), 0x20)
        // Define variables base (B)
        mstore(add(pointer, 0x60), self)
        // Define the exponent (E)
        mstore(add(pointer, 0x80), pp1div4)
        // We save the point of the last argument, it will be override by the result
        // of the precompile call in order to avoid paying for the memory expansion properly
        let _result := add(pointer, 0xa0)
        // Define the modulus (M)
        mstore(_result, p)

        // Call the precompiled ModExp (0x05) https://www.evm.codes/precompiled#0x05
        if iszero(
            staticcall(
                not(0), // amount of gas to send
                MODEXP_PRECOMPILE, // target
                pointer, // argsOffset
                0xc0, // argsSize (6 * 32 bytes)
                _result, // retOffset (we override M to avoid paying for the memory expansion)
                0x20 // retSize (32 bytes)
            )
        ) { revert(0, 0) }

  result := mload(_result)
//  result :=addmod(result,0,p)
 }
   if(mulmod(result,result,p)!=self){
     result=_NOTSQUARE;
   }
  
   return result;
}
    /**
     * /* @dev Convert from affine rep to XYZZ rep
     */
    function ecAff_SetZZ(uint256 x0, uint256 y0) internal pure returns (uint256[4] memory P) {
        unchecked {
            P[2] = 1; //ZZ
            P[3] = 1; //ZZZ
            P[0] = x0;
            P[1] = y0;
        }
    }

    function ec_Decompress(uint256 x, uint256 parity) internal view returns(uint256 y){ 

        uint256 y2=mulmod(x,mulmod(x,x,p),p);//x3
        y2=addmod(b,addmod(y2,mulmod(x,a,p),p),p);//x3+ax+b

        y=SqrtMod(y2);
        if(y==_NOTSQUARE){
           return _NOTONCURVE;
        }
        if((y&1)!=(parity&1)){
            y=p-y;
        }
    }

    /**
     * /* @dev Convert from XYZZ rep to affine rep
     */
    /*    https://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz-3.html#addition-add-2008-s*/
    function ecZZ_SetAff(uint256 x, uint256 y, uint256 zz, uint256 zzz) internal view returns (uint256 x1, uint256 y1) {
        uint256 zzzInv = FCL_pModInv(zzz); //1/zzz
        y1 = mulmod(y, zzzInv, p); //Y/zzz
        uint256 _b = mulmod(zz, zzzInv, p); //1/z
        zzzInv = mulmod(_b, _b, p); //1/zz
        x1 = mulmod(x, zzzInv, p); //X/zz
    }

    /**
     * /* @dev Sutherland2008 doubling
     */
    /* The "dbl-2008-s-1" doubling formulas */

    function ecZZ_Dbl(uint256 x, uint256 y, uint256 zz, uint256 zzz)
        internal
        pure
        returns (uint256 P0, uint256 P1, uint256 P2, uint256 P3)
    {
        unchecked {
            assembly {
                P0 := mulmod(2, y, p) //U = 2*Y1
                P2 := mulmod(P0, P0, p) // V=U^2
                P3 := mulmod(x, P2, p) // S = X1*V
                P1 := mulmod(P0, P2, p) // W=UV
                P2 := mulmod(P2, zz, p) //zz3=V*ZZ1
                zz := mulmod(3, mulmod(addmod(x, sub(p, zz), p), addmod(x, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                P0 := addmod(mulmod(zz, zz, p), mulmod(minus_2, P3, p), p) //X3=M^2-2S
                x := mulmod(zz, addmod(P3, sub(p, P0), p), p) //M(S-X3)
                P3 := mulmod(P1, zzz, p) //zzz3=W*zzz1
                P1 := addmod(x, sub(p, mulmod(P1, y, p)), p) //Y3= M(S-X3)-W*Y1
            }
        }
        return (P0, P1, P2, P3);
    }

    /**
     * @dev Sutherland2008 add a ZZ point with a normalized point and greedy formulae
     * warning: assume that P1(x1,y1)!=P2(x2,y2), true in multiplication loop with prime order (cofactor 1)
     */

    function ecZZ_AddN(uint256 x1, uint256 y1, uint256 zz1, uint256 zzz1, uint256 x2, uint256 y2)
        internal
        pure
        returns (uint256 P0, uint256 P1, uint256 P2, uint256 P3)
    {
        unchecked {
            if (y1 == 0) {
                return (x2, y2, 1, 1);
            }

            assembly {
                y1 := sub(p, y1)
                y2 := addmod(mulmod(y2, zzz1, p), y1, p)
                x2 := addmod(mulmod(x2, zz1, p), sub(p, x1), p)
                P0 := mulmod(x2, x2, p) //PP = P^2
                P1 := mulmod(P0, x2, p) //PPP = P*PP
                P2 := mulmod(zz1, P0, p) ////ZZ3 = ZZ1*PP
                P3 := mulmod(zzz1, P1, p) ////ZZZ3 = ZZZ1*PPP
                zz1 := mulmod(x1, P0, p) //Q = X1*PP
                P0 := addmod(addmod(mulmod(y2, y2, p), sub(p, P1), p), mulmod(minus_2, zz1, p), p) //R^2-PPP-2*Q
                P1 := addmod(mulmod(addmod(zz1, sub(p, P0), p), y2, p), mulmod(y1, P1, p), p) //R*(Q-X3)
            }
            //end assembly
        } //end unchecked
        return (P0, P1, P2, P3);
    }

    /**
     * @dev Return the zero curve in XYZZ coordinates.
     */
    function ecZZ_SetZero() internal pure returns (uint256 x, uint256 y, uint256 zz, uint256 zzz) {
        return (0, 0, 0, 0);
    }
    /**
     * @dev Check if point is the neutral of the curve
     */

    // uint256 x0, uint256 y0, uint256 zz0, uint256 zzz0
    function ecZZ_IsZero(uint256, uint256 y0, uint256, uint256) internal pure returns (bool) {
        return y0 == 0;
    }
    /**
     * @dev Return the zero curve in affine coordinates. Compatible with the double formulae (no special case)
     */

    function ecAff_SetZero() internal pure returns (uint256 x, uint256 y) {
        return (0, 0);
    }

    /**
     * @dev Check if the curve is the zero curve in affine rep.
     */
    // uint256 x, uint256 y)
    function ecAff_IsZero(uint256, uint256 y) internal pure returns (bool flag) {
        return (y == 0);
    }

    /**
     * @dev Check if a point in affine coordinates is on the curve (reject Neutral that is indeed on the curve).
     */
    function ecAff_isOnCurve(uint256 x, uint256 y) internal pure returns (bool) {
        if ( ((0 == x)&&( 0 == y)) || x == p ||   y == p) {
            return false;
        }
        unchecked {
            uint256 LHS = mulmod(y, y, p); // y^2
            uint256 RHS = addmod(mulmod(mulmod(x, x, p), x, p), mulmod(x, a, p), p); // x^3+ax
            RHS = addmod(RHS, b, p); // x^3 + a*x + b

            return LHS == RHS;
        }
    }

    /**
     * @dev Add two elliptic curve points in affine coordinates. Deal with P=Q
     */

    function ecAff_add(uint256 x0, uint256 y0, uint256 x1, uint256 y1) internal view returns (uint256, uint256) {
        uint256 zz0;
        uint256 zzz0;

        if (ecAff_IsZero(x0, y0)) return (x1, y1);
        if (ecAff_IsZero(x1, y1)) return (x0, y0);
        if((x0==x1)&&(y0==y1)) {
            (x0, y0, zz0, zzz0) = ecZZ_Dbl(x0, y0,1,1);
        }
        else{
            (x0, y0, zz0, zzz0) = ecZZ_AddN(x0, y0, 1, 1, x1, y1);
        }

        return ecZZ_SetAff(x0, y0, zz0, zzz0);
    }

    /**
     * @dev Computation of uG+vQ using Strauss-Shamir's trick, G basepoint, Q public key
     *       Returns only x for ECDSA use            
     *      */
    function ecZZ_mulmuladd_S_asm(
        uint256 Q0,
        uint256 Q1, //affine rep for input point Q
        uint256 scalar_u,
        uint256 scalar_v
    ) internal view returns (uint256 X) {
        uint256 zz;
        uint256 zzz;
        uint256 Y;
        uint256 index = 255;
        uint256 H0;
        uint256 H1;

        unchecked {
            if (scalar_u == 0 && scalar_v == 0) return 0;

            (H0, H1) = ecAff_add(gx, gy, Q0, Q1); 
            if((H0==0)&&(H1==0))//handling Q=-G
            {
                scalar_u=addmod(scalar_u, n-scalar_v, n);
                scalar_v=0;

            }
            assembly {
                for { let T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1)) } eq(T4, 0) {
                    index := sub(index, 1)
                    T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))
                } {}
                zz := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))

                if eq(zz, 1) {
                    X := gx
                    Y := gy
                }
                if eq(zz, 2) {
                    X := Q0
                    Y := Q1
                }
                if eq(zz, 3) {
                    X := H0
                    Y := H1
                }

                index := sub(index, 1)
                zz := 1
                zzz := 1

                for {} gt(minus_1, index) { index := sub(index, 1) } {
                    // inlined EcZZ_Dbl
                    let T1 := mulmod(2, Y, p) //U = 2*Y1, y free
                    let T2 := mulmod(T1, T1, p) // V=U^2
                    let T3 := mulmod(X, T2, p) // S = X1*V
                    T1 := mulmod(T1, T2, p) // W=UV
                    let T4 := mulmod(3, mulmod(addmod(X, sub(p, zz), p), addmod(X, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                    zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                    zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                    X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                    T2 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)
                    Y := addmod(mulmod(T1, Y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd

                    {
                        //value of dibit
                        T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))

                        if iszero(T4) {
                            Y := sub(p, Y) //restore the -Y inversion
                            continue
                        } // if T4!=0

                        if eq(T4, 1) {
                            T1 := gx
                            T2 := gy
                        }
                        if eq(T4, 2) {
                            T1 := Q0
                            T2 := Q1
                        }
                        if eq(T4, 3) {
                            T1 := H0
                            T2 := H1
                        }
                        if iszero(zz) {
                            X := T1
                            Y := T2
                            zz := 1
                            zzz := 1
                            continue
                        }
                        // inlined EcZZ_AddN

                        //T3:=sub(p, Y)
                        //T3:=Y
                        let y2 := addmod(mulmod(T2, zzz, p), Y, p) //R
                        T2 := addmod(mulmod(T1, zz, p), sub(p, X), p) //P

                        //special extremely rare case accumulator where EcAdd is replaced by EcDbl, no need to optimize this
                        //todo : construct edge vector case
                        if iszero(y2) {
                            if iszero(T2) {
                                T1 := mulmod(minus_2, Y, p) //U = 2*Y1, y free
                                T2 := mulmod(T1, T1, p) // V=U^2
                                T3 := mulmod(X, T2, p) // S = X1*V

                                T1 := mulmod(T1, T2, p) // W=UV
                                y2 := mulmod(addmod(X, zz, p), addmod(X, sub(p, zz), p), p) //(X-ZZ)(X+ZZ)
                                T4 := mulmod(3, y2, p) //M=3*(X-ZZ)(X+ZZ)

                                zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                                zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                                X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                                T2 := mulmod(T4, addmod(T3, sub(p, X), p), p) //M(S-X3)

                                Y := addmod(T2, mulmod(T1, Y, p), p) //Y3= M(S-X3)-W*Y1

                                continue
                            }
                        }

                        T4 := mulmod(T2, T2, p) //PP
                        let TT1 := mulmod(T4, T2, p) //PPP, this one could be spared, but adding this register spare gas
                        zz := mulmod(zz, T4, p)
                        zzz := mulmod(zzz, TT1, p) //zz3=V*ZZ1
                        let TT2 := mulmod(X, T4, p)
                        T4 := addmod(addmod(mulmod(y2, y2, p), sub(p, TT1), p), mulmod(minus_2, TT2, p), p)
                        Y := addmod(mulmod(addmod(TT2, sub(p, T4), p), y2, p), mulmod(Y, TT1, p), p)

                        X := T4
                    }
                } //end loop
                let T := mload(0x40)
                mstore(add(T, 0x60), zz)
                //(X,Y)=ecZZ_SetAff(X,Y,zz, zzz);
                //T[0] = inverseModp_Hard(T[0], p); //1/zzz, inline modular inversion using precompile:
                // Define length of base, exponent and modulus. 0x20 == 32 bytes
                mstore(T, 0x20)
                mstore(add(T, 0x20), 0x20)
                mstore(add(T, 0x40), 0x20)
                // Define variables base, exponent and modulus
                //mstore(add(pointer, 0x60), u)
                mstore(add(T, 0x80), minus_2)
                mstore(add(T, 0xa0), p)

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, T, 0xc0, T, 0x20)) { revert(0, 0) }

                //Y:=mulmod(Y,zzz,p)//Y/zzz
                //zz :=mulmod(zz, mload(T),p) //1/z
                //zz:= mulmod(zz,zz,p) //1/zz
                X := mulmod(X, mload(T), p) //X/zz
            } //end assembly
        } //end unchecked

        return X;
    }


    /**
     * @dev Computation of uG+vQ using Strauss-Shamir's trick, G basepoint, Q public key
     *       Returns affine representation of point (normalized)       
     *      */
    function ecZZ_mulmuladd(
        uint256 Q0,
        uint256 Q1, //affine rep for input point Q
        uint256 scalar_u,
        uint256 scalar_v
    ) internal view returns (uint256 X, uint256 Y) {
        uint256 zz;
        uint256 zzz;
        uint256 index = 255;
        uint256[6] memory T;
        uint256[2] memory H;
 
        unchecked {
            if (scalar_u == 0 && scalar_v == 0) return (0,0);

            (H[0], H[1]) = ecAff_add(gx, gy, Q0, Q1); //will not work if Q=P, obvious forbidden private key

            assembly {
                for { let T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1)) } eq(T4, 0) {
                    index := sub(index, 1)
                    T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))
                } {}
                zz := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))

                if eq(zz, 1) {
                    X := gx
                    Y := gy
                }
                if eq(zz, 2) {
                    X := Q0
                    Y := Q1
                }
                if eq(zz, 3) {
                    Y := mload(add(H,32))
                    X := mload(H)
                }

                index := sub(index, 1)
                zz := 1
                zzz := 1

                for {} gt(minus_1, index) { index := sub(index, 1) } {
                    // inlined EcZZ_Dbl
                    let T1 := mulmod(2, Y, p) //U = 2*Y1, y free
                    let T2 := mulmod(T1, T1, p) // V=U^2
                    let T3 := mulmod(X, T2, p) // S = X1*V
                    T1 := mulmod(T1, T2, p) // W=UV
                    let T4 := mulmod(3, mulmod(addmod(X, sub(p, zz), p), addmod(X, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                    zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                    zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                    X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                    T2 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)
                    Y := addmod(mulmod(T1, Y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd

                    {
                        //value of dibit
                        T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))

                        if iszero(T4) {
                            Y := sub(p, Y) //restore the -Y inversion
                            continue
                        } // if T4!=0

                        if eq(T4, 1) {
                            T1 := gx
                            T2 := gy
                        }
                        if eq(T4, 2) {
                            T1 := Q0
                            T2 := Q1
                        }
                        if eq(T4, 3) {
                            T1 := mload(H)
                            T2 := mload(add(H,32))
                        }
                        if iszero(zz) {
                            X := T1
                            Y := T2
                            zz := 1
                            zzz := 1
                            continue
                        }
                        // inlined EcZZ_AddN

                        //T3:=sub(p, Y)
                        //T3:=Y
                        let y2 := addmod(mulmod(T2, zzz, p), Y, p) //R
                        T2 := addmod(mulmod(T1, zz, p), sub(p, X), p) //P

                        //special extremely rare case accumulator where EcAdd is replaced by EcDbl, no need to optimize this
                        //todo : construct edge vector case
                        if iszero(y2) {
                            if iszero(T2) {
                                T1 := mulmod(minus_2, Y, p) //U = 2*Y1, y free
                                T2 := mulmod(T1, T1, p) // V=U^2
                                T3 := mulmod(X, T2, p) // S = X1*V

                                T1 := mulmod(T1, T2, p) // W=UV
                                y2 := addmod(X, zz, p) //X+ZZ
                                let TT1 := addmod(X, sub(p, zz), p) //X-ZZ
                                y2 := mulmod(y2, TT1, p) //(X-ZZ)(X+ZZ)
                                T4 := mulmod(3, y2, p) //M

                                zzz := mulmod(TT1, zzz, p) //zzz3=W*zzz1
                                zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                                X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                                T2 := mulmod(T4, addmod(T3, sub(p, X), p), p) //M(S-X3)

                                Y := addmod(T2, mulmod(T1, Y, p), p) //Y3= M(S-X3)-W*Y1

                                continue
                            }
                        }

                        T4 := mulmod(T2, T2, p) //PP
                        let TT1 := mulmod(T4, T2, p) //PPP, this one could be spared, but adding this register spare gas
                        zz := mulmod(zz, T4, p)
                        zzz := mulmod(zzz, TT1, p) //zz3=V*ZZ1
                        let TT2 := mulmod(X, T4, p)
                        T4 := addmod(addmod(mulmod(y2, y2, p), sub(p, TT1), p), mulmod(minus_2, TT2, p), p)
                        Y := addmod(mulmod(addmod(TT2, sub(p, T4), p), y2, p), mulmod(Y, TT1, p), p)

                        X := T4
                    }
                } //end loop
                mstore(add(T, 0x60), zzz)
                //(X,Y)=ecZZ_SetAff(X,Y,zz, zzz);
                //T[0] = inverseModp_Hard(T[0], p); //1/zzz, inline modular inversion using precompile:
                // Define length of base, exponent and modulus. 0x20 == 32 bytes
                mstore(T, 0x20)
                mstore(add(T, 0x20), 0x20)
                mstore(add(T, 0x40), 0x20)
                // Define variables base, exponent and modulus
                //mstore(add(pointer, 0x60), u)
                mstore(add(T, 0x80), minus_2)
                mstore(add(T, 0xa0), p)

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, T, 0xc0, T, 0x20)) { revert(0, 0) }

                Y:=mulmod(Y,mload(T),p)//Y/zzz
                zz :=mulmod(zz, mload(T),p) //1/z
                zz:= mulmod(zz,zz,p) //1/zz
                X := mulmod(X, zz, p) //X/zz
            } //end assembly
        } //end unchecked

        return (X,Y);
    }

    //8 dimensions Shamir's trick, using precomputations stored in Shamir8,  stored as Bytecode of an external
    //contract at given address dataPointer
    //(thx to Lakhdar https://github.com/Kelvyne for EVM storage explanations and tricks)
    // the external tool to generate tables from public key is in the /sage directory
    function ecZZ_mulmuladd_S8_extcode(uint256 scalar_u, uint256 scalar_v, address dataPointer)
        internal view
        returns (uint256 X /*, uint Y*/ )
    {
        unchecked {
            uint256 zz; // third and  coordinates of the point

            uint256[6] memory T;
            zz = 256; //start index

            while (T[0] == 0) {
                zz = zz - 1;
                //tbd case of msb octobit is null
                T[0] = 64
                    * (
                        128 * ((scalar_v >> zz) & 1) + 64 * ((scalar_v >> (zz - 64)) & 1)
                            + 32 * ((scalar_v >> (zz - 128)) & 1) + 16 * ((scalar_v >> (zz - 192)) & 1)
                            + 8 * ((scalar_u >> zz) & 1) + 4 * ((scalar_u >> (zz - 64)) & 1)
                            + 2 * ((scalar_u >> (zz - 128)) & 1) + ((scalar_u >> (zz - 192)) & 1)
                    );
            }
            assembly {
                extcodecopy(dataPointer, T, mload(T), 64)
                let index := sub(zz, 1)
                X := mload(T)
                let Y := mload(add(T, 32))
                let zzz := 1
                zz := 1

                //loop over 1/4 of scalars thx to Shamir's trick over 8 points
                for {} gt(index, 191) { index := add(index, 191) } {
                    //inline Double
                    {
                        let TT1 := mulmod(2, Y, p) //U = 2*Y1, y free
                        let T2 := mulmod(TT1, TT1, p) // V=U^2
                        let T3 := mulmod(X, T2, p) // S = X1*V
                        let T1 := mulmod(TT1, T2, p) // W=UV
                        let T4 := mulmod(3, mulmod(addmod(X, sub(p, zz), p), addmod(X, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                        zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                        zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                        X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                        //T2:=mulmod(T4,addmod(T3, sub(p, X),p),p)//M(S-X3)
                        let T5 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)

                        //Y:= addmod(T2, sub(p, mulmod(T1, Y ,p)),p  )//Y3= M(S-X3)-W*Y1
                        Y := addmod(mulmod(T1, Y, p), T5, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd

                        /* compute element to access in precomputed table */
                    }
                    {
                        let T4 := add(shl(13, and(shr(index, scalar_v), 1)), shl(9, and(shr(index, scalar_u), 1)))
                        let index2 := sub(index, 64)
                        let T3 :=
                            add(T4, add(shl(12, and(shr(index2, scalar_v), 1)), shl(8, and(shr(index2, scalar_u), 1))))
                        let index3 := sub(index2, 64)
                        let T2 :=
                            add(T3, add(shl(11, and(shr(index3, scalar_v), 1)), shl(7, and(shr(index3, scalar_u), 1))))
                        index := sub(index3, 64)
                        let T1 :=
                            add(T2, add(shl(10, and(shr(index, scalar_v), 1)), shl(6, and(shr(index, scalar_u), 1))))

                        //tbd: check validity of formulae with (0,1) to remove conditional jump
                        if iszero(T1) {
                            Y := sub(p, Y)

                            continue
                        }
                        extcodecopy(dataPointer, T, T1, 64)
                    }

                    {
                        /* Access to precomputed table using extcodecopy hack */

                        // inlined EcZZ_AddN
                        if iszero(zz) {
                            X := mload(T)
                            Y := mload(add(T, 32))
                            zz := 1
                            zzz := 1

                            continue
                        }

                        let y2 := addmod(mulmod(mload(add(T, 32)), zzz, p), Y, p)
                        let T2 := addmod(mulmod(mload(T), zz, p), sub(p, X), p)

                        //special case ecAdd(P,P)=EcDbl
                        if iszero(y2) {
                            if iszero(T2) {
                                let T1 := mulmod(minus_2, Y, p) //U = 2*Y1, y free
                                T2 := mulmod(T1, T1, p) // V=U^2
                                let T3 := mulmod(X, T2, p) // S = X1*V

                                T1 := mulmod(T1, T2, p) // W=UV
                                y2 := addmod(X, zz, p) //X+ZZ
                                let TT1 := addmod(X, sub(p, zz), p) //X-ZZ
                                y2 := mulmod(y2, TT1, p) //(X-ZZ)(X+ZZ)
                                let T4 := mulmod(3, y2, p) //M

                                zzz := mulmod(TT1, zzz, p) //zzz3=W*zzz1
                                zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                                X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                                T2 := mulmod(T4, addmod(T3, sub(p, X), p), p) //M(S-X3)

                                Y := addmod(T2, mulmod(T1, Y, p), p) //Y3= M(S-X3)-W*Y1

                                continue
                            }
                        }

                        let T4 := mulmod(T2, T2, p)
                        let T1 := mulmod(T4, T2, p) //
                        zz := mulmod(zz, T4, p)
                        //zzz3=V*ZZ1
                        zzz := mulmod(zzz, T1, p) // W=UV/
                        let zz1 := mulmod(X, T4, p)
                        X := addmod(addmod(mulmod(y2, y2, p), sub(p, T1), p), mulmod(minus_2, zz1, p), p)
                        Y := addmod(mulmod(addmod(zz1, sub(p, X), p), y2, p), mulmod(Y, T1, p), p)
                    }
                } //end loop
                mstore(add(T, 0x60), zz)

                //(X,Y)=ecZZ_SetAff(X,Y,zz, zzz);
                //T[0] = inverseModp_Hard(T[0], p); //1/zzz, inline modular inversion using precompile:
                // Define length of base, exponent and modulus. 0x20 == 32 bytes
                mstore(T, 0x20)
                mstore(add(T, 0x20), 0x20)
                mstore(add(T, 0x40), 0x20)
                // Define variables base, exponent and modulus
                //mstore(add(pointer, 0x60), u)
                mstore(add(T, 0x80), minus_2)
                mstore(add(T, 0xa0), p)

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, T, 0xc0, T, 0x20)) { revert(0, 0) }

                zz := mload(T)
                X := mulmod(X, zz, p) //X/zz
            }
        } //end unchecked
    }

   

    // improving the extcodecopy trick : append array at end of contract
    function ecZZ_mulmuladd_S8_hackmem(uint256 scalar_u, uint256 scalar_v, uint256 dataPointer)
        internal view
        returns (uint256 X /*, uint Y*/ )
    {
        uint256 zz; // third and  coordinates of the point

        uint256[6] memory T;
        zz = 256; //start index

        unchecked {
            while (T[0] == 0) {
                zz = zz - 1;
                //tbd case of msb octobit is null
                T[0] = 64
                    * (
                        128 * ((scalar_v >> zz) & 1) + 64 * ((scalar_v >> (zz - 64)) & 1)
                            + 32 * ((scalar_v >> (zz - 128)) & 1) + 16 * ((scalar_v >> (zz - 192)) & 1)
                            + 8 * ((scalar_u >> zz) & 1) + 4 * ((scalar_u >> (zz - 64)) & 1)
                            + 2 * ((scalar_u >> (zz - 128)) & 1) + ((scalar_u >> (zz - 192)) & 1)
                    );
            }
            assembly {
                codecopy(T, add(mload(T), dataPointer), 64)
                X := mload(T)
                let Y := mload(add(T, 32))
                let zzz := 1
                zz := 1

                //loop over 1/4 of scalars thx to Shamir's trick over 8 points
                for { let index := 254 } gt(index, 191) { index := add(index, 191) } {
                    let T1 := mulmod(2, Y, p) //U = 2*Y1, y free
                    let T2 := mulmod(T1, T1, p) // V=U^2
                    let T3 := mulmod(X, T2, p) // S = X1*V
                    T1 := mulmod(T1, T2, p) // W=UV
                    let T4 := mulmod(3, mulmod(addmod(X, sub(p, zz), p), addmod(X, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                    zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                    zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                    X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                    //T2:=mulmod(T4,addmod(T3, sub(p, X),p),p)//M(S-X3)
                    T2 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)

                    //Y:= addmod(T2, sub(p, mulmod(T1, Y ,p)),p  )//Y3= M(S-X3)-W*Y1
                    Y := addmod(mulmod(T1, Y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd

                    /* compute element to access in precomputed table */
                    T4 := add(shl(13, and(shr(index, scalar_v), 1)), shl(9, and(shr(index, scalar_u), 1)))
                    index := sub(index, 64)
                    T4 := add(T4, add(shl(12, and(shr(index, scalar_v), 1)), shl(8, and(shr(index, scalar_u), 1))))
                    index := sub(index, 64)
                    T4 := add(T4, add(shl(11, and(shr(index, scalar_v), 1)), shl(7, and(shr(index, scalar_u), 1))))
                    index := sub(index, 64)
                    T4 := add(T4, add(shl(10, and(shr(index, scalar_v), 1)), shl(6, and(shr(index, scalar_u), 1))))
                    //index:=add(index,192), restore index, interleaved with loop

                    //tbd: check validity of formulae with (0,1) to remove conditional jump
                    if iszero(T4) {
                        Y := sub(p, Y)

                        continue
                    }
                    {
                        /* Access to precomputed table using extcodecopy hack */
                        codecopy(T, add(T4, dataPointer), 64)

                        // inlined EcZZ_AddN

                        let y2 := addmod(mulmod(mload(add(T, 32)), zzz, p), Y, p)
                        T2 := addmod(mulmod(mload(T), zz, p), sub(p, X), p)
                        T4 := mulmod(T2, T2, p)
                        T1 := mulmod(T4, T2, p)
                        T2 := mulmod(zz, T4, p) // W=UV
                        zzz := mulmod(zzz, T1, p) //zz3=V*ZZ1
                        let zz1 := mulmod(X, T4, p)
                        T4 := addmod(addmod(mulmod(y2, y2, p), sub(p, T1), p), mulmod(minus_2, zz1, p), p)
                        Y := addmod(mulmod(addmod(zz1, sub(p, T4), p), y2, p), mulmod(Y, T1, p), p)
                        zz := T2
                        X := T4
                    }
                } //end loop
                mstore(add(T, 0x60), zz)

                //(X,Y)=ecZZ_SetAff(X,Y,zz, zzz);
                //T[0] = inverseModp_Hard(T[0], p); //1/zzz, inline modular inversion using precompile:
                // Define length of base, exponent and modulus. 0x20 == 32 bytes
                mstore(T, 0x20)
                mstore(add(T, 0x20), 0x20)
                mstore(add(T, 0x40), 0x20)
                // Define variables base, exponent and modulus
                //mstore(add(pointer, 0x60), u)
                mstore(add(T, 0x80), minus_2)
                mstore(add(T, 0xa0), p)

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, T, 0xc0, T, 0x20)) { revert(0, 0) }

                zz := mload(T)
                X := mulmod(X, zz, p) //X/zz
            }
        } //end unchecked
    }


    /**
     * @dev ECDSA verification using a precomputed table of multiples of P and Q stored in contract at address Shamir8
     *     generation of contract bytecode for precomputations is done using sagemath code
     *     (see sage directory, WebAuthn_precompute.sage)
     */

    /**
     * @dev ECDSA verification using a precomputed table of multiples of P and Q appended at end of contract at address endcontract
     *     generation of contract bytecode for precomputations is done using sagemath code
     *     (see sage directory, WebAuthn_precompute.sage)
     */

    function ecdsa_precomputed_hackmem(bytes32 message, uint256[2] calldata rs, uint256 endcontract)
        internal view
        returns (bool)
    {
        uint256 r = rs[0];
        uint256 s = rs[1];
        if (r == 0 || r >= n || s == 0 || s >= n) {
            return false;
        }
        /* Q is pushed via bytecode assumed to be correct
        if (!isOnCurve(Q[0], Q[1])) {
            return false;
        }*/

        uint256 sInv = FCL_nModInv(s);
        uint256 X;

        //Shamir 8 dimensions
        X = ecZZ_mulmuladd_S8_hackmem(mulmod(uint256(message), sInv, n), mulmod(r, sInv, n), endcontract);

        assembly {
            X := addmod(X, sub(n, r), n)
        }
        return X == 0;
    } //end  ecdsa_precomputed_verify()



} //EOF

//********************************************************************************************/
//  ___           _       ___               _         _    _ _
// | __| _ ___ __| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__
// | _| '_/ -_|_-< ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
// |_||_| \___/__/_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
//                                |__/|_|
///* Copyright (C) 2022 - Renaud Dubois - This file is part of FCL (Fresh CryptoLib) project
///* License: This software is licensed under MIT License
///* This Code may be reused including license and copyright notice.
///* See LICENSE file at the root folder of the project.
///* FILE: FCL_ecdsa.sol
///*
///*
///* DESCRIPTION: ecdsa verification implementation
///*
//**************************************************************************************/
//* WARNING: this code SHALL not be used for non prime order curves for security reasons.
// Code is optimized for a=-3 only curves with prime order, constant like -1, -2 shall be replaced
// if ever used for other curve than sec256R1
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


import {FCL_Elliptic_ZZ} from "./FCL_elliptic.sol";



library FCL_ecdsa {
    // Set parameters for curve sec256r1.public
      //curve order (number of points)
    uint256 constant n = FCL_Elliptic_ZZ.n;
  
    /**
     * @dev ECDSA verification, given , signature, and public key.
     */

    /**
     * @dev ECDSA verification, given , signature, and public key, no calldata version
     */
    function ecdsa_verify(bytes32 message, uint256 r, uint256 s, uint256 Qx, uint256 Qy)  internal view returns (bool){

        if (r == 0 || r >= FCL_Elliptic_ZZ.n || s == 0 || s >= FCL_Elliptic_ZZ.n) {
            return false;
        }
        
        if (!FCL_Elliptic_ZZ.ecAff_isOnCurve(Qx, Qy)) {
            return false;
        }

        uint256 sInv = FCL_Elliptic_ZZ.FCL_nModInv(s);

        uint256 scalar_u = mulmod(uint256(message), sInv, FCL_Elliptic_ZZ.n);
        uint256 scalar_v = mulmod(r, sInv, FCL_Elliptic_ZZ.n);
        uint256 x1;

        x1 = FCL_Elliptic_ZZ.ecZZ_mulmuladd_S_asm(Qx, Qy, scalar_u, scalar_v);

        x1= addmod(x1, n-r,n );
    
        return x1 == 0;
    }

    function ec_recover_r1(uint256 h, uint256 v, uint256 r, uint256 s) internal view returns (address)
    {
         if (r == 0 || r >= FCL_Elliptic_ZZ.n || s == 0 || s >= FCL_Elliptic_ZZ.n) {
            return address(0);
        }
        uint256 y=FCL_Elliptic_ZZ.ec_Decompress(r, v-27);
        uint256 rinv=FCL_Elliptic_ZZ.FCL_nModInv(r);
        uint256 u1=mulmod(FCL_Elliptic_ZZ.n-addmod(0,h,FCL_Elliptic_ZZ.n), rinv,FCL_Elliptic_ZZ.n);//-hr^-1
        uint256 u2=mulmod(s, rinv,FCL_Elliptic_ZZ.n);//sr^-1

        uint256 Qx;
        uint256 Qy;
        (Qx,Qy)=FCL_Elliptic_ZZ.ecZZ_mulmuladd(r,y, u1, u2);

        return address(uint160(uint256(keccak256(abi.encodePacked(Qx, Qy)))));
    }

    function ecdsa_precomputed_verify(bytes32 message, uint256 r, uint256 s, address Shamir8)
        internal view
        returns (bool)
    {
       
        if (r == 0 || r >= n || s == 0 || s >= n) {
            return false;
        }
        /* Q is pushed via the contract at address Shamir8 assumed to be correct
        if (!isOnCurve(Q[0], Q[1])) {
            return false;
        }*/

        uint256 sInv = FCL_Elliptic_ZZ.FCL_nModInv(s);

        uint256 X;

        //Shamir 8 dimensions
        X = FCL_Elliptic_ZZ.ecZZ_mulmuladd_S8_extcode(mulmod(uint256(message), sInv, n), mulmod(r, sInv, n), Shamir8);

        X= addmod(X, n-r,n );

        return X == 0;
    } //end  ecdsa_precomputed_verify()

     function ecdsa_precomputed_verify(bytes32 message, uint256[2] calldata rs, address Shamir8)
        internal view
        returns (bool)
    {
        uint256 r = rs[0];
        uint256 s = rs[1];
        if (r == 0 || r >= n || s == 0 || s >= n) {
            return false;
        }
        /* Q is pushed via the contract at address Shamir8 assumed to be correct
        if (!isOnCurve(Q[0], Q[1])) {
            return false;
        }*/

        uint256 sInv = FCL_Elliptic_ZZ.FCL_nModInv(s);

        uint256 X;

        //Shamir 8 dimensions
        X = FCL_Elliptic_ZZ.ecZZ_mulmuladd_S8_extcode(mulmod(uint256(message), sInv, n), mulmod(r, sInv, n), Shamir8);

        X= addmod(X, n-r,n );

        return X == 0;
    } //end  ecdsa_precomputed_verify()

}

//********************************************************************************************/
//  ___           _       ___               _         _    _ _
// | __| _ ___ __| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__
// | _| '_/ -_|_-< ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
// |_||_| \___/__/_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
//                                |__/|_|
///* Copyright (C) 2022 - Renaud Dubois - This file is part of FCL (Fresh CryptoLib) project
///* License: This software is licensed under MIT License
///* This Code may be reused including license and copyright notice.
///* See LICENSE file at the root folder of the project.
///* FILE: FCL_ecdsa.sol
///*
///*
///* DESCRIPTION: ecdsa verification implementation
///*
//**************************************************************************************/
//* WARNING: this code SHALL not be used for non prime order curves for security reasons.
// Code is optimized for a=-3 only curves with prime order, constant like -1, -2 shall be replaced
// if ever used for other curve than sec256R1
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


import {FCL_Elliptic_ZZ} from "./FCL_elliptic.sol";



library FCL_ecdsa_utils {
    // Set parameters for curve sec256r1.public
      //curve order (number of points)
    uint256 constant n = FCL_Elliptic_ZZ.n;
  
    /**
     * @dev ECDSA verification, given , signature, and public key.
     */

    function ecdsa_verify(bytes32 message, uint256[2] calldata rs, uint256 Qx, uint256 Qy) internal view returns (bool) {
        uint256 r = rs[0];
        uint256 s = rs[1];
        if (r == 0 || r >= FCL_Elliptic_ZZ.n || s == 0 || s >= FCL_Elliptic_ZZ.n) {
            return false;
        }
        if (!FCL_Elliptic_ZZ.ecAff_isOnCurve(Qx, Qy)) {
            return false;
        }

        uint256 sInv = FCL_Elliptic_ZZ.FCL_nModInv(s);

        uint256 scalar_u = mulmod(uint256(message), sInv, FCL_Elliptic_ZZ.n);
        uint256 scalar_v = mulmod(r, sInv, FCL_Elliptic_ZZ.n);
        uint256 x1;

        x1 = FCL_Elliptic_ZZ.ecZZ_mulmuladd_S_asm(Qx, Qy, scalar_u, scalar_v);
        x1= addmod(x1, n-r,n );
        
       
        return x1 == 0;
    }

    function ecdsa_verify(bytes32 message, uint256[2] calldata rs, uint256[2] calldata Q) internal view returns (bool) {
        return ecdsa_verify(message, rs, Q[0], Q[1]);
    }

    function ec_recover_r1(uint256 h, uint256 v, uint256 r, uint256 s) internal view returns (address)
    {
         if (r == 0 || r >= FCL_Elliptic_ZZ.n || s == 0 || s >= FCL_Elliptic_ZZ.n) {
            return address(0);
        }
        uint256 y=FCL_Elliptic_ZZ.ec_Decompress(r, v-27);
        uint256 rinv=FCL_Elliptic_ZZ.FCL_nModInv(r);
        uint256 u1=mulmod(FCL_Elliptic_ZZ.n-addmod(0,h,FCL_Elliptic_ZZ.n), rinv,FCL_Elliptic_ZZ.n);//-hr^-1
        uint256 u2=mulmod(s, rinv,FCL_Elliptic_ZZ.n);//sr^-1

        uint256 Qx;
        uint256 Qy;
        (Qx,Qy)=FCL_Elliptic_ZZ.ecZZ_mulmuladd(r,y, u1, u2);

        return address(uint160(uint256(keccak256(abi.encodePacked(Qx, Qy)))));
    }


    //ecdsa signature for test purpose only (who would like to have a private key onchain anyway ?)
    //K is nonce, kpriv is private key
    function ecdsa_sign(bytes32 message, uint256 k , uint256 kpriv) internal view returns(uint256 r, uint256 s)
    {
        r=FCL_Elliptic_ZZ.ecZZ_mulmuladd_S_asm(0,0, k, 0) ;//Calculate the curve point k.G (abuse ecmulmul add with v=0)
        r=addmod(0,r, FCL_Elliptic_ZZ.n); 
        s=mulmod(FCL_Elliptic_ZZ.FCL_nModInv(k), addmod(uint256(message), mulmod(r, kpriv, FCL_Elliptic_ZZ.n),FCL_Elliptic_ZZ.n),FCL_Elliptic_ZZ.n);//s=k^-1.(h+r.kpriv)

        
        if(r==0||s==0){
            revert();
        }


    }

    //ecdsa key derivation
    //kpriv is private key return (x,y) coordinates of associated Pubkey
    function ecdsa_derivKpub(uint256 kpriv) internal view returns(uint256 x, uint256 y)
    {
        
        x=FCL_Elliptic_ZZ.ecZZ_mulmuladd_S_asm(0,0, kpriv, 0) ;//Calculate the curve point k.G (abuse ecmulmul add with v=0)
        y=FCL_Elliptic_ZZ.ec_Decompress(x, 1);
       
        if (FCL_Elliptic_ZZ.ecZZ_mulmuladd_S_asm(x, y, kpriv, FCL_Elliptic_ZZ.n - 1) != 0) //extract correct y value
        {
            y=FCL_Elliptic_ZZ.p-y;
        }        

    }
 
    //precomputations for 8 dimensional trick
    function Precalc_8dim( uint256 Qx, uint256 Qy) internal view returns( uint[2][256] memory Prec)
    {
    
     uint[2][8] memory Pow64_PQ; //store P, 64P, 128P, 192P, Q, 64Q, 128Q, 192Q
     
     //the trivial private keys 1 and -1 are forbidden
     if(Qx==FCL_Elliptic_ZZ.gx)
     {
        revert();
     }
     Pow64_PQ[0][0]=FCL_Elliptic_ZZ.gx;
     Pow64_PQ[0][1]=FCL_Elliptic_ZZ.gy;
    
     Pow64_PQ[4][0]=Qx;
     Pow64_PQ[4][1]=Qy;
     
     /* raise to multiplication by 64 by 6 consecutive doubling*/
     for(uint j=1;j<4;j++){
        uint256 x;
        uint256 y;
        uint256 zz;
        uint256 zzz;
        
      	(x,y,zz,zzz)=FCL_Elliptic_ZZ.ecZZ_Dbl(Pow64_PQ[j-1][0],   Pow64_PQ[j-1][1], 1, 1);
      	(Pow64_PQ[j][0],   Pow64_PQ[j][1])=FCL_Elliptic_ZZ.ecZZ_SetAff(x,y,zz,zzz);
        (x,y,zz,zzz)=FCL_Elliptic_ZZ.ecZZ_Dbl(Pow64_PQ[j+3][0],   Pow64_PQ[j+3][1], 1, 1);
     	(Pow64_PQ[j+4][0],   Pow64_PQ[j+4][1])=FCL_Elliptic_ZZ.ecZZ_SetAff(x,y,zz,zzz);

     	for(uint i=0;i<63;i++){
     	(x,y,zz,zzz)=FCL_Elliptic_ZZ.ecZZ_Dbl(Pow64_PQ[j][0],   Pow64_PQ[j][1],1,1);
        (Pow64_PQ[j][0],   Pow64_PQ[j][1])=FCL_Elliptic_ZZ.ecZZ_SetAff(x,y,zz,zzz);
     	(x,y,zz,zzz)=FCL_Elliptic_ZZ.ecZZ_Dbl(Pow64_PQ[j+4][0],   Pow64_PQ[j+4][1],1,1);
        (Pow64_PQ[j+4][0],   Pow64_PQ[j+4][1])=FCL_Elliptic_ZZ.ecZZ_SetAff(x,y,zz,zzz);
     	}
     }
     
     /* neutral point */
     Prec[0][0]=0;
     Prec[0][1]=0;
     
     	
     for(uint i=1;i<256;i++)
     {       
        Prec[i][0]=0;
        Prec[i][1]=0;
        
        for(uint j=0;j<8;j++)
        {
        	if( (i&(1<<j))!=0){
        		(Prec[i][0], Prec[i][1])=FCL_Elliptic_ZZ.ecAff_add(Pow64_PQ[j][0], Pow64_PQ[j][1], Prec[i][0], Prec[i][1]);
        	}
        }
         
     }
     return Prec;
    }

}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Enum - Collection of enums used in Safe contracts.
 * @author Richard Meissner - @rmeissner
 */
abstract contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SelfAuthorized - Authorizes current contract to perform actions to itself.
 * @author Richard Meissner - @rmeissner
 */
abstract contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "GS031");
    }

    modifier authorized() {
        // Modifiers are copied around during compilation. This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/Enum.sol";

/**
 * @title Executor - A contract that can execute transactions
 * @author Richard Meissner - @rmeissner
 */
abstract contract Executor {
    /**
     * @notice Executes either a delegatecall or a call with provided parameters.
     * @dev This method doesn't perform any sanity check of the transaction, such as:
     *      - if the contract at `to` address has code or not
     *      It is the responsibility of the caller to perform such checks.
     * @param to Destination address.
     * @param value Ether value.
     * @param data Data payload.
     * @param operation Operation type.
     * @return success boolean flag indicating if the call succeeded.
     */
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by `interfaceId`.
     * See the corresponding EIP section
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}