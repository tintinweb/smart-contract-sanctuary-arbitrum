// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

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
    constructor(address initialOwner) {
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
        return _owner;
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
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
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
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Create2.sol)

pragma solidity ^0.8.20;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Not enough balance for performing a CREATE2 deploy.
     */
    error Create2InsufficientBalance(uint256 balance, uint256 needed);

    /**
     * @dev There's no code to deploy.
     */
    error Create2EmptyBytecode();

    /**
     * @dev The deployment failed.
     */
    error Create2FailedDeployment();

    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
        if (address(this).balance < amount) {
            revert Create2InsufficientBalance(address(this).balance, amount);
        }
        if (bytecode.length == 0) {
            revert Create2EmptyBytecode();
        }
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        if (addr == address(0)) {
            revert Create2FailedDeployment();
        }
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for address related errors.
 */
library AddressError {
    /**
     * @dev Thrown when a zero address was passed as a function parameter (0x0000000000000000000000000000000000000000).
     */
    error ZeroAddress();

    /**
     * @dev Thrown when an address representing a contract is expected, but no code is found at the address.
     * @param contr The address that was expected to be a contract.
     */
    error NotAContract(address contr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for change related errors.
 */
library ChangeError {
    /**
     * @dev Thrown when a change is expected but none is detected.
     */
    error NoChange();
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Contract to be used as the implementation of a Universal Upgradeable Proxy Standard (UUPS) proxy.
 *
 * Important: A UUPS proxy requires its upgradeability functions to be in the implementation as opposed to the proxy. This means that if the proxy is upgraded to an implementation that does not support this interface, it will no longer be upgradeable.
 */
interface IUUPSImplementation {
    /**
     * @notice Thrown when an incoming implementation will not be able to receive future upgrades.
     */
    error ImplementationIsSterile(address implementation);

    /**
     * @notice Thrown intentionally when testing future upgradeability of an implementation.
     */
    error UpgradeSimulationFailed();

    /**
     * @notice Emitted when the implementation of the proxy has been upgraded.
     * @param self The address of the proxy whose implementation was upgraded.
     * @param implementation The address of the proxy's new implementation.
     */
    event Upgraded(address indexed self, address implementation);

    /**
     * @notice Allows the proxy to be upgraded to a new implementation.
     * @param newImplementation The address of the proxy's new implementation.
     * @dev Will revert if `newImplementation` is not upgradeable.
     * @dev The implementation of this function needs to be protected by some sort of access control such as `onlyOwner`.
     */
    function upgradeTo(address newImplementation) external;

    /**
     * @notice Function used to determine if a new implementation will be able to receive future upgrades in `upgradeTo`.
     * @param newImplementation The address of the new implementation being tested for future upgradeability.
     * @dev This function will always revert, but will revert with different error messages. The function `upgradeTo` uses this error to determine the future upgradeability of the implementation in question.
     */
    function simulateUpgradeTo(address newImplementation) external;

    /**
     * @notice Retrieves the current implementation of the proxy.
     * @return The address of the current implementation.
     */
    function getImplementation() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

abstract contract AbstractProxy {
    fallback() external payable {
//         gasleft();
        _forward();
//         gasleft();
//         gasAMount = gas1-gas2
//         oracle amount(gasAMount)
// transfer(oracleamount);
    }

    receive() external payable {
        _forward();
    }

    function _forward() internal {
        address implementation = _getImplementation();

        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _getImplementation() internal view virtual returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

contract ProxyStorage {
    bytes32 private constant _SLOT_PROXY_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.Proxy"));

    struct ProxyStore {
        address implementation;
        bool simulatingUpgrade;
    }

    function _proxyStore() internal pure returns (ProxyStore storage store) {
        bytes32 s = _SLOT_PROXY_STORAGE;
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IUUPSImplementation.sol";
import "../errors/AddressError.sol";
import "../errors/ChangeError.sol";
import "../utils/AddressUtil.sol";
import "./ProxyStorage.sol";

abstract contract UUPSImplementation is IUUPSImplementation, ProxyStorage {
    /**
     * @inheritdoc IUUPSImplementation
     */
    function simulateUpgradeTo(address newImplementation) public override {
        ProxyStore storage store = _proxyStore();

        store.simulatingUpgrade = true;

        address currentImplementation = store.implementation;
        store.implementation = newImplementation;

        (bool rollbackSuccessful, ) = newImplementation.delegatecall(
            abi.encodeCall(this.upgradeTo, (currentImplementation))
        );

        if (!rollbackSuccessful || _proxyStore().implementation != currentImplementation) {
            revert UpgradeSimulationFailed();
        }

        store.simulatingUpgrade = false;

        // solhint-disable-next-line reason-string
        revert();
    }

    /**
     * @inheritdoc IUUPSImplementation
     */
    function getImplementation() external view override returns (address) {
        return _proxyStore().implementation;
    }

    function _upgradeTo(address newImplementation) internal virtual {
        if (newImplementation == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (!AddressUtil.isContract(newImplementation)) {
            revert AddressError.NotAContract(newImplementation);
        }

        ProxyStore storage store = _proxyStore();

        if (newImplementation == store.implementation) {
            revert ChangeError.NoChange();
        }

        if (!store.simulatingUpgrade && _implementationIsSterile(newImplementation)) {
            revert ImplementationIsSterile(newImplementation);
        }

        store.implementation = newImplementation;

        emit Upgraded(address(this), newImplementation);
    }

    function _implementationIsSterile(
        address candidateImplementation
    ) internal virtual returns (bool) {
        (bool simulationReverted, bytes memory simulationResponse) = address(this).delegatecall(
            abi.encodeCall(this.simulateUpgradeTo, (candidateImplementation))
        );

        return
            !simulationReverted &&
            keccak256(abi.encodePacked(simulationResponse)) ==
            keccak256(abi.encodePacked(UpgradeSimulationFailed.selector));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./AbstractProxy.sol";
import "./ProxyStorage.sol";
import "../errors/AddressError.sol";
import "../utils/AddressUtil.sol";

contract UUPSProxy is AbstractProxy, ProxyStorage {
    constructor(address firstImplementation) {
        if (firstImplementation == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (!AddressUtil.isContract(firstImplementation)) {
            revert AddressError.NotAContract(firstImplementation);
        }

        _proxyStore().implementation = firstImplementation;
    }

    function _getImplementation() internal view virtual override returns (address) {
        return _proxyStore().implementation;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library AddressUtil {
    function isContract(address account) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account)
        }

        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { UUPSProxy } from "@synthetixio/core-contracts/contracts/proxy/UUPSProxy.sol";
import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

import { InitialProxyImplementation } from "../proxy/InitialProxyImplementation.sol";

import { IAccountFactory } from "src/interfaces/accounts/IAccountFactory.sol";
import { IBaseModule } from "src/interfaces/accounts/IBaseModule.sol";
import { IInfinexProtocolConfigBeacon } from "src/interfaces/beacons/IInfinexProtocolConfigBeacon.sol";

import { Error } from "../libraries/Error.sol";

contract AccountFactory is IAccountFactory, Ownable2Step, Initializable {
    mapping(address => bool) public createdAccounts;
    IInfinexProtocolConfigBeacon public infinexProtocolConfigBeacon;
    bool public canPredictAddress;
    bool public canCreateAccount;

    /**
     * @notice constructor function
     * @param _owner The owner of the contract
     * @dev use msg.sender to guarantee the contract is constructed with the same bytecode on all chains
     */
    constructor(address _owner) Ownable(_owner) { }

    /*///////////////////////////////////////////////////////////////
                                 		INITIALIZER
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializer function
     * @dev All params are put in the initializer instead of the constructor in order to
     * guarantee the contract is constructed with the same bytecode on all chains.
     * Do not move these parameters from the initializer into the constructor.
     * @param _infinexProtocolConfigBeacon The Infinex Information Beacon address
     */
    function initialize(address _infinexProtocolConfigBeacon) external onlyOwner initializer {
        if (_infinexProtocolConfigBeacon == address(0)) revert Error.NullAddress();

        infinexProtocolConfigBeacon = IInfinexProtocolConfigBeacon(_infinexProtocolConfigBeacon);

        canPredictAddress = true;
        canCreateAccount = true;
    }

    /*///////////////////////////////////////////////////////////////
                                        VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the bytecode hash used for the create2 deploy
     * @return bytecodeHash The hash of the bytecode of the initial proxy implementation
     */
    function getPredictAddressBytecodeHash() external view returns (bytes32 bytecodeHash) {
        address initialProxyImplementation = infinexProtocolConfigBeacon.getInitialProxyImplementation();
        bytecodeHash = keccak256(_getProxyBytecode(initialProxyImplementation));
    }

    /**
     * @notice Predicts the address an account would be deployed at based on a given salt
     * @param _salt The unique value used to create a deterministic address
     * @return newAccount The predicted address of the account
     * @return isAvailable True if the predicted address is available
     */
    function predictAddress(bytes32 _salt) external view returns (address newAccount, bool isAvailable) {
        if (!canPredictAddress) revert Error.PredictAddressDisabled();
        address initialProxyImplementation = infinexProtocolConfigBeacon.getInitialProxyImplementation();

        newAccount = Create2.computeAddress(_salt, keccak256(_getProxyBytecode(initialProxyImplementation)));
        isAvailable = !createdAccounts[newAccount];
    }

    /*///////////////////////////////////////////////////////////////
                                            MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new deposit account with a deterministic address based on the provided salt
     * @param _sudoKey The sudo key
     * @return newAccount The address of the newly created deposit account
     */
    function createAccount(address _sudoKey) external returns (address newAccount) {
        if (!canCreateAccount) revert Error.CreateAccountDisabled();
        if (_sudoKey == address(0)) revert Error.NullAddress();
        bytes32 salt = keccak256(abi.encodePacked(_sudoKey));

        address initialProxyImplementation = infinexProtocolConfigBeacon.getInitialProxyImplementation();

        /// @dev A new UUPSProxy is deployed using CREATE2 with a default implementation.
        /// This ensures that both create2 calls for Trading and Deposit accounts are identical,
        /// resulting in both accounts receiving the same address.
        newAccount = Create2.deploy(0, salt, _getProxyBytecode(initialProxyImplementation));

        createdAccounts[newAccount] = true;

        address latestAccountImplementation = infinexProtocolConfigBeacon.getLatestAccountImplementation();

        /// @dev Now that the Proxy is deployed, we can replace the default implementation with the account one.
        InitialProxyImplementation(newAccount).upgradeTo(latestAccountImplementation);

        /// @dev Then, the Account Implementation contract is initialized
        IBaseModule(newAccount).initialize(_sudoKey);

        emit AccountCreated(newAccount, _sudoKey);
    }

    /**
     * @notice @notice Updates the InfinexProtocolBeacon to the latest from the Infinex Protocol Config Beacon.
     * @param _newInfinexProtocolConfigBeacon The address of the new Infinex Protocol Config Beacon
     */
    function updateInfinexProtocolConfigBeacon(address _newInfinexProtocolConfigBeacon) external onlyOwner {
        address latestInfinexProtocolConfigBeacon = infinexProtocolConfigBeacon.getLatestInfinexProtocolConfigBeacon();
        if (latestInfinexProtocolConfigBeacon == address(infinexProtocolConfigBeacon)) revert Error.SameAddress();
        if (latestInfinexProtocolConfigBeacon == address(0)) revert Error.NullAddress();
        if (latestInfinexProtocolConfigBeacon != _newInfinexProtocolConfigBeacon) {
            revert Error.ImplementationMismatch(_newInfinexProtocolConfigBeacon, latestInfinexProtocolConfigBeacon);
        }

        emit FactoryInfinexProtocolBeaconImplementationUpgraded(latestInfinexProtocolConfigBeacon);

        infinexProtocolConfigBeacon = IInfinexProtocolConfigBeacon(latestInfinexProtocolConfigBeacon);
    }

    /**
     * @notice Sets whether or not the factory can predict the address of a new account
     * @param _canPredictAddress A boolean indicating if the factory can predict the address of a new account
     */
    function setCanPredictAddress(bool _canPredictAddress) external onlyOwner {
        _setCanPredictAddress(_canPredictAddress);
    }

    /**
     * @notice Sets whether or not the factory can create a new account
     * @param _canCreateAccount A boolean indicating if the factory can create a new account
     */
    function setCanCreateAccount(bool _canCreateAccount) external onlyOwner {
        _setCanCreateAccount(_canCreateAccount);
    }

    /**
     * @notice Sets whether or not the factory can both predict the address and create a new account
     * @param _canPredictAddress A boolean indicating if the factory can predict the address of a new account
     * @param _canCreateAccount A boolean indicating if the factory can create a new account
     */
    function setCanPredictAddressAndCreateAccount(bool _canPredictAddress, bool _canCreateAccount) external onlyOwner {
        _setCanPredictAddress(_canPredictAddress);
        _setCanCreateAccount(_canCreateAccount);
    }

    /*///////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    function _getProxyBytecode(address _implementation) internal pure returns (bytes memory) {
        return abi.encodePacked(type(UUPSProxy).creationCode, abi.encode(_implementation));
    }

    function _setCanPredictAddress(bool _canPredictAddress) internal {
        emit CanPredictAddressSet(_canPredictAddress);
        canPredictAddress = _canPredictAddress;
    }

    function _setCanCreateAccount(bool _canCreateAccount) internal {
        emit CanCreateAccountSet(_canCreateAccount);
        canCreateAccount = _canCreateAccount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract RequestTypes {
    struct Request {
        address _address;
        address _address2;
        uint256 _uint256;
        bytes32 _nonce;
        uint32 _uint32;
        bool _bool;
        bytes4 _selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IInfinexProtocolConfigBeacon } from "src/interfaces/beacons/IInfinexProtocolConfigBeacon.sol";

interface IAccountFactory {
    /*///////////////////////////////////////////////////////////////
                    			EVENTS / ERRORS
    ///////////////////////////////////////////////////////////////*/

    event FactoryInfinexProtocolBeaconImplementationUpgraded(address infinexProtocolConfigBeacon);
    event AccountCreated(address indexed account, address indexed sudoKey);
    event CanPredictAddressSet(bool canPredictAddress);
    event CanCreateAccountSet(bool canCreateAccount);

    /*///////////////////////////////////////////////////////////////
                    			VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks if an account has been created
     * @return The account address
     */
    function createdAccounts(address _account) external view returns (bool);

    /**
     * @notice Gets the Infinex Protocol Config Beacon address
     * @return The address of the Infinex Protocol Config Beacon address
     */
    function infinexProtocolConfigBeacon() external view returns (IInfinexProtocolConfigBeacon);

    /**
     * @notice Checks if the factory can predict the address of a new account
     * @return True if the factory can predict the address, false otherwise
     */
    function canPredictAddress() external view returns (bool);

    /**
     * @notice Checks if the factory can create a new account
     * @return True if the factory can create an account, false otherwise
     */
    function canCreateAccount() external view returns (bool);

    /**
     * @notice Gets the bytecode hash used for create2 deploy
     * @return bytecodeHash The hash of the bytecode of the initial proxy implementation
     */
    function getPredictAddressBytecodeHash() external view returns (bytes32);

    /**
     * @notice Predicts the future address of a deposit account based on a given salt
     * @param _salt The unique value used to create a deterministic address
     * @return newAccount The predicted future address of the deposit account
     * @return isAvailable True if the predicted address is available
     */
    function predictAddress(bytes32 _salt) external view returns (address, bool);

    /*///////////////////////////////////////////////////////////////
                    			MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializer function
     * @param _infinexProtocolConfigBeacon The Infinex Information Beacon address
     */
    function initialize(address _infinexProtocolConfigBeacon) external;

    /**
     * @notice Creates a new deposit account with a deterministic address based on the provided salt
     * @param _sudoKey The sudo key
     * @return newAccount The address of the newly created deposit account
     */
    function createAccount(address _sudoKey) external returns (address newAccount);

    /**
     * @notice Updates the InfinexProtocolBeacon to the latest from the Infinex Protocol Config Beacon.
     * @param _newInfinexProtocolConfigBeacon The address of the new Infinex Protocol Config Beacon
     */
    function updateInfinexProtocolConfigBeacon(address _newInfinexProtocolConfigBeacon) external;

    /**
     * @notice Sets whether or not the factory can predict the address of a new account
     * @param _canPredictAddress A boolean indicating if the factory can predict the address of a new account
     */
    function setCanPredictAddress(bool _canPredictAddress) external;

    /**
     * @notice Sets whether or not the factory can create a new account
     * @param _canCreateAccount A boolean indicating if the factory can create a new account
     */
    function setCanCreateAccount(bool _canCreateAccount) external;

    /**
     * @notice Sets whether or not the factory can both predict the address and create a new account
     * @param _canPredictAddress A boolean indicating if the factory can predict the address of a new account
     * @param _canCreateAccount A boolean indicating if the factory can create a new account
     */
    function setCanPredictAddressAndCreateAccount(bool _canPredictAddress, bool _canCreateAccount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { RequestTypes } from "src/accounts/utils/RequestTypes.sol";

interface IBaseModule {
    /*///////////////////////////////////////////////////////////////
                    			EVENTS / ERRORS
    ///////////////////////////////////////////////////////////////*/

    event AccountImplementationUpgraded(address accountImplementation);

    /*///////////////////////////////////////////////////////////////
                                 		INITIALIZER
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the account with the sudo key
     */
    function initialize(address _sudoKey) external;

    /*///////////////////////////////////////////////////////////////
                                    VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if the provided nonce is valid
     * @param _nonce The nonce to check
     * @return A boolean indicating if the nonce is valid
     */
    function isValidNonce(bytes32 _nonce) external view returns (bool);

    /**
     * @notice Check if the provided forwarder is trusted
     * @param _forwarder The forwarder to check
     * @return A boolean indicating if the forwarder is trusted
     */
    function isTrustedForwarder(address _forwarder) external view returns (bool);

    /**
     * @notice Get all trusted forwarders
     * @return An array of addresses of all trusted forwarders
     */
    function trustedForwarders() external view returns (address[] memory);

    /*///////////////////////////////////////////////////////////////
                    			MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/
    /**
     * @notice Enables or disables an operation key for the account
     * @param _operationKey The address of the operation key to be set
     * @param _isValid Whether the key is to be set as valid or invalid
     * @dev This function requires the sender to be the sudo key holder
     */
    function setOperationKeyStatus(address _operationKey, bool _isValid) external;

    /**
     * @notice Enables or disables a recovery key for the account
     * @param _recoveryKey The address of the recovery key to be set
     * @param _isValid Whether the key is to be set as valid or invalid
     * @dev This function requires the sender to be the sudo key holder
     */
    function setRecoveryKeyStatus(address _recoveryKey, bool _isValid) external;

    /**
     * @notice Enables or disables a sudo key for the account
     * @param _sudoKey The address of the sudo key to be set
     * @param _isValid Whether the key is to be set as valid or invalid
     * @dev This function requires the sender to be the sudo key holder
     */
    function setSudoKeyStatus(address _sudoKey, bool _isValid) external;

    /**
     * @notice Add a new trusted forwarder
     * @param _request The Request struct containing:
     *  RequestData {
     *  address _address; - The address of the new trusted forwarder.
     *	bytes32 _nonce; - The nonce of the signature
     *  }
     * @param _signature The required signature for executing the transaction
     * Required signature:
     * - sudo key
     */
    function addTrustedForwarder(RequestTypes.Request calldata _request, bytes calldata _signature) external;

    /**
     * @notice Remove a trusted forwarder
     * @param _request The Request struct containing:
     *  RequestData {
     *  address _address; - The address of the trusted forwarder to be removed.
     *	bytes32 _nonce; - The nonce of the signature
     *  }
     * @param _signature The required signature for executing the transaction
     * Required signature:
     * - sudo key
     */
    function removeTrustedForwarder(RequestTypes.Request calldata _request, bytes calldata _signature) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title IInfinexProtocolConfigBeacon
 * @notice Interface for the Infinex Protocol Config Beacon contract.
 */
interface IInfinexProtocolConfigBeacon {
    /*///////////////////////////////////////////////////////////////
    	 										STRUCTS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Struct containing the constructor arguments for the InfinexProtocolConfigBeacon contract
     * @param trustedForwarder Address of the trusted forwarder contract
     * @param latestAccountImplementation Address of the latest account implementation contract
     * @param initialProxyImplementation Address of the initial proxy implementation contract
     * @param revenuePool Address of the revenue pool contract
     * @param USDC Address of the USDC token contract
     * @param minimumUSDCBridgeAmount Minimum amount of USDC required to bridge
     * @param circleBridge Address of the Circle bridge contract
     * @param circleMinter Address of the Circle minter contract, used for checking the maximum bridge amount
     * @param wormholeCircleBridge Address of the Wormhole Circle bridge contract
     * @param defaultDestinationCCTPDomain the CCTP domain of the default destination chain.
     * @param defaultDestinationWormholeChainId the Wormhole chain id of the default destination chain.
     * @param solanaWalletSeed The salt used to generate the Solana account (fixed seed "wallet")
     * @param solanaFixedPDASeed The salt used to generate the PDA (Program Derived Address)
     * @param solanaWalletProgramAddress The Solana Wallet Program Address
     * @param solanaTokenMintAddress The Solana token mint address
     * @param solanaTokenProgramAddress The Solana token program address
     * @param solanaAssociatedTokenProgramAddress The Solana ATA program address
     */
    struct InfinexBeaconConstructorArgs {
        address trustedForwarder;
        address latestAccountImplementation;
        address initialProxyImplementation;
        address revenuePool;
        address USDC;
        uint256 minimumUSDCBridgeAmount;
        address circleBridge;
        address circleMinter;
        address wormholeCircleBridge;
        uint32 defaultDestinationCCTPDomain;
        uint16 defaultDestinationWormholeChainId;
        uint16[] supportedWormholeChainIds;
        uint32 solanaCCTPDestinationDomain;
        bytes solanaWalletSeed;
        bytes solanaFixedPDASeed;
        bytes32 solanaWalletProgramAddress;
        bytes32 solanaTokenMintAddress;
        bytes32 solanaTokenProgramAddress;
        bytes32 solanaAssociatedTokenProgramAddress;
    }

    /**
     * @notice Struct containing both Circle and Wormhole bridge configuration
     * @param minimumUSDCBridgeAmount Minimum amount of USDC required to bridge
     * @param circleBridge Address of the Circle bridge contract
     * @param circleMinter Address of the Circle minter contract, used for checking the maximum bridge amount
     * @param wormholeCircleBridge Address of the Wormhole Circle bridge contract
     * @param defaultDestinationCCTPDomain the CCTP domain of the default destination chain.
     * @param defaultDestinationWormholeChainId the Wormhole chain id of the default destination chain.
     * @dev Chain id is the official chain id for evm chains and documented one for non evm chains.
     */
    struct BridgeConfiguration {
        uint256 minimumUSDCBridgeAmount;
        address circleBridge;
        address circleMinter;
        address wormholeCircleBridge;
        uint32 defaultDestinationCCTPDomain;
        uint16 defaultDestinationWormholeChainId;
    }

    /**
     * @notice The addresses for implementations referenced by the beacon
     * @param initialProxyImplementation The initial proxy implementation address used for account creation to ensure identical cross chain addresses
     * @param latestAccountImplementation The latest account implementation address, used for account upgrades and new accounts
     * @param latestInfinexProtocolConfigBeacon The latest Infinex Protocol config beacon address, used for pointing account updates to the latest beacon
     */
    struct ImplementationAddresses {
        address initialProxyImplementation;
        address latestAccountImplementation;
        address latestInfinexProtocolConfigBeacon;
    }

    /**
     * @notice Struct containing the Solana configuration needed to verify addresses
     * @param walletSeed The salt used to generate the Solana account (fixed seed "wallet")
     * @param fixedPDASeed The salt used to generate the PDA (Program Derived Address)
     * @param walletProgramAddress The Solana Wallet Program Address
     * @param tokenMintAddress The Solana token mint address
     * @param tokenProgramAddress The Solana token address
     * @param associatedTokenProgramAddress The Solana ATA program address
     */
    struct SolanaConfiguration {
        bytes walletSeed;
        bytes fixedPDASeed;
        bytes32 walletProgramAddress;
        bytes32 tokenMintAddress;
        bytes32 tokenProgramAddress;
        bytes32 associatedTokenProgramAddress;
    }

    /*///////////////////////////////////////////////////////////////
    	 										EVENTS
    ///////////////////////////////////////////////////////////////*/

    event LatestAccountImplementationSet(address latestAccountImplementation);
    event InitialProxyImplementationSet(address initialProxyImplementation);
    event RevenuePoolSet(address revenuePool);
    event USDCAddressSet(address USDC);
    event CircleBridgeParamsSet(address circleBridge, address circleMinter, uint32 defaultDestinationCCTPDomain);
    event WormholeCircleBridgeParamsSet(address wormholeCircleBridge, uint16 defaultDestinationWormholeChainId);
    event LatestInfinexProtocolConfigBeaconSet(address latestInfinexProtocolConfigBeacon);
    event WithdrawalFeeUSDCSet(uint256 withdrawalFee);
    event FundsRecoveryStatusSet(bool status);
    event MinimumUSDCBridgeAmountSet(uint256 amount);
    event WormholeDestinationDomainSet(uint256 indexed chainId, uint16 destinationDomain);
    event CircleDestinationDomainSet(uint256 indexed chainId, uint32 destinationDomain);
    event TrustedRecoveryKeeperSet(address indexed trustedRecoveryKeeper, bool isTrusted);
    event SupportedWormholeChainIdSet(uint16 wormholeChainId, bool status);
    event SolanaCCTPDestinationDomainSet(uint32 solanaCCTPDestinationDomain);

    /*///////////////////////////////////////////////////////////////
    	 									VARIABLES
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the timestamp the beacon was deployed
     * @return The timestamp the beacon was deployed
     */
    function CREATED_AT() external view returns (uint256);

    /**
     * @notice Gets the trusted forwarder address
     * @return The address of the trusted forwarder
     */
    function TRUSTED_FORWARDER() external view returns (address);

    /**
     * @notice A platform wide feature flag to enable or disable funds recovery, false by default
     * @return True if funds recovery is active
     */
    function fundsRecoveryActive() external view returns (bool);

    /**
     * @notice Gets the revenue pool address
     * @return The address of the revenue pool
     */
    function revenuePool() external view returns (address);

    /**
     * @notice Gets the USDC amount to charge as withdrawal fee
     * @return The withdrawal fee in USDC's decimals
     */
    function withdrawalFeeUSDC() external view returns (uint256);

    /**
     * @notice Retrieves the USDC address.
     * @return The address of the USDC token
     */
    function USDC() external view returns (address);

    /*///////////////////////////////////////////////////////////////
    	 								VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Retrieves supported wormhole chain ids.
     * @param _wormholeChainId the chain id to check
     * @return bool if the chain is supported or not.
     */
    function isSupportedWormholeChainId(uint16 _wormholeChainId) external view returns (bool);

    /**
     * @notice Retrieves the minimum USDC amount that can be bridged.
     * @return The minimum USDC bridge amount.
     */
    function getMinimumUSDCBridgeAmount() external view returns (uint256);

    /**
     * @notice Retrieves the Circle Bridge parameters.
     * @return circleBridge The address of the Circle Bridge contract.
     * @return circleMinter The address of the TokenMinter contract.
     * @return defaultDestinationCCTPDomain The CCTP domain of the default destination chain.
     */
    function getCircleBridgeParams()
        external
        view
        returns (address circleBridge, address circleMinter, uint32 defaultDestinationCCTPDomain);

    /**
     * @notice Retrieves the Circle Bridge address.
     * @return The address of the Circle Bridge contract.
     */
    function getCircleBridge() external view returns (address);

    /**
     * @notice Retrieves the Circle TokenMinter address.
     * @return The address of the Circle TokenMinter contract.
     */
    function getCircleMinter() external view returns (address);

    /**
     * @notice Retrieves the CCTP domain of the destination chain.
     * @return The CCTP domain of the default destination chain.
     */
    function getDefaultDestinationCCTPDomain() external view returns (uint32);

    /**
     * @notice Retrieves the parameters required for Wormhole bridging.
     * @return The address of the Wormhole Circle Bridge contract.
     * @return The default wormhole destination domain for the circle bridge contract.
     */
    function getWormholeCircleBridgeParams() external view returns (address, uint16);

    /**
     * @notice Retrieves the Wormhole Circle Bridge address.
     * @return The address of the Wormhole Circle Bridge contract.
     */
    function getWormholeCircleBridge() external view returns (address);

    /**
     * @notice Retrieves the Wormhole chain id for Base, or Ethereum Mainnet if deployed on Base.
     * @return The Wormhole chain id of the default destination chain.
     */
    function getDefaultDestinationWormholeChainId() external view returns (uint16);

    /**
     * @notice Retrieves the circle CCTP destination domain for solana.
     * @return The CCTP destination domain for solana.
     */
    function getSolanaCCTPDestinationDomain() external view returns (uint32);

    /**
     * @notice Gets the latest account implementation address.
     * @return The address of the latest account implementation.
     */
    function getLatestAccountImplementation() external view returns (address);

    /**
     * @notice Gets the initial proxy implementation address.
     * @return The address of the initial proxy implementation.
     */
    function getInitialProxyImplementation() external view returns (address);

    /**
     * @notice The latest Infinex Protocol config beacon address, used for pointing account updates to the latest beacon.
     * @return The address of the latest Infinex Protocol config beacon.
     */
    function getLatestInfinexProtocolConfigBeacon() external view returns (address);

    /**
     * @notice Checks if an address is a trusted recovery keeper.
     * @param _address The address to check.
     * @return True if the address is a trusted recovery keeper, false otherwise.
     */
    function isTrustedRecoveryKeeper(address _address) external view returns (bool);

    /**
     * @notice Returns the Solana configuration
     * @param walletSeed The salt used to generate the Solana account (fixed seed "wallet")
     * @param fixedPDASeed The salt used to generate the PDA (Program Derived Address)
     * @param walletProgramAddress The Solana Wallet Program Address
     * @param tokenMintAddress The Solana token mint address
     * @param tokenProgramAddress The Solana token program address
     * @param associatedTokenProgramAddress The Solana ATA program address
     */
    function getSolanaConfiguration()
        external
        view
        returns (
            bytes memory walletSeed,
            bytes memory fixedPDASeed,
            bytes32 walletProgramAddress,
            bytes32 tokenMintAddress,
            bytes32 tokenProgramAddress,
            bytes32 associatedTokenProgramAddress
        );

    /*///////////////////////////////////////////////////////////////
    	 							MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets or unsets a supported wormhole chain id.
     * @param _wormholeChainId the wormhole chain id to add or remove.
     * @param _status the status of the chain id.
     */
    function setSupportedWormholeChainId(uint16 _wormholeChainId, bool _status) external;

    /**
     * @notice Sets the solana CCTP destination domain
     * @param _solanaCCTPDestinationDomain the destination domain for circles CCTP USDC bridge.
     */
    function setSolanaCCTPDestinationDomain(uint32 _solanaCCTPDestinationDomain) external;

    /**
     * @notice Sets or unsets an address as a trusted recovery keeper.
     * @param _address The address to set or unset.
     * @param _isTrusted Boolean indicating whether to set or unset the address as a trusted recovery keeper.
     */
    function setTrustedRecoveryKeeper(address _address, bool _isTrusted) external;

    /**
     * @notice Sets the funds recovery flag to active.
     * @dev Initially only the owner can call this. After 90 days, it can be activated by anyone.
     */
    function setFundsRecoveryActive() external;

    /**
     * @notice Sets the revenue pool address.
     * @param _revenuePool The revenue pool address.
     */
    function setRevenuePool(address _revenuePool) external;

    /**
     * @notice Sets the USDC amount to charge as withdrawal fee.
     * @param _withdrawalFeeUSDC The withdrawal fee in USDC's decimals.
     */
    function setWithdrawalFeeUSDC(uint256 _withdrawalFeeUSDC) external;

    /**
     * @notice Sets the address of the USDC token contract.
     * @param _USDC The address of the USDC token contract.
     * @dev Only the contract owner can call this function.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setUSDCAddress(address _USDC) external;

    /**
     * @notice Sets the minimum USDC amount that can be bridged, in 6 decimals.
     * @param _amount The minimum USDC bridge amount.
     */
    function setMinimumUSDCBridgeAmount(uint256 _amount) external;

    /**
     * @notice Sets the parameters for Circle bridging.
     * @param _circleBridge The address of the Circle Bridge contract.
     * @param _circleMinter The address of the Circle TokenMinter contract.
     * @param _defaultDestinationCCTPDomain The CCTP domain of the default destination chain.
     * @dev Circle Destination Domain can be 0 - Ethereum.
     */
    function setCircleBridgeParams(address _circleBridge, address _circleMinter, uint32 _defaultDestinationCCTPDomain) external;

    /**
     * @notice Sets the parameters for Wormhole bridging.
     * @param _wormholeCircleBridge The address of the Wormhole Circle Bridge contract.
     * @param _defaultDestinationWormholeChainId The wormhole domain of the default destination chain.
     */
    function setWormholeCircleBridgeParams(address _wormholeCircleBridge, uint16 _defaultDestinationWormholeChainId) external;

    /**
     * @notice Sets the initial proxy implementation address.
     * @param _initialProxyImplementation The initial proxy implementation address.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setInitialProxyImplementation(address _initialProxyImplementation) external;

    /**
     * @notice Sets the latest account implementation address.
     * @param _latestAccountImplementation The latest account implementation address.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setLatestAccountImplementation(address _latestAccountImplementation) external;

    /**
     * @notice Sets the latest Infinex Protocol Config Beacon.
     * @param _latestInfinexProtocolConfigBeacon The address of the Infinex Protocol Config Beacon.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setLatestInfinexProtocolConfigBeacon(address _latestInfinexProtocolConfigBeacon) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library Error {
    /*///////////////////////////////////////////////////////////////
                                            GENERIC
    ///////////////////////////////////////////////////////////////*/

    error AlreadyExists();

    error DoesNotExist();

    error Unauthorized();

    error InvalidLength();

    error NotOwner();

    error InvalidWormholeChainId();

    /*///////////////////////////////////////////////////////////////
                                            ADDRESS
    ///////////////////////////////////////////////////////////////*/

    error ImplementationMismatch(address implementation, address latestImplementation);

    error InvalidWithdrawalAddress(address to);

    error NullAddress();

    error SameAddress();

    error InvalidSolanaAddress();

    error AddressAlreadySet();

    /*///////////////////////////////////////////////////////////////
                                    AMOUNT / BALANCE
    ///////////////////////////////////////////////////////////////*/

    error InsufficientBalance();

    error InsufficientWithdrawalAmount(uint256 amount);

    error InsufficientBalanceForFee(uint256 balance, uint256 fee);

    error InvalidNonce(bytes32 nonce);

    error ZeroValue();

    error AmountDeltaZeroValue();

    error DecimalsMoreThan18(uint256 decimals);

    error InsufficientBridgeAmount();

    error BridgeMaxAmountExceeded();

    /*///////////////////////////////////////////////////////////////
                                            ACCOUNT
    ///////////////////////////////////////////////////////////////*/

    error CreateAccountDisabled();

    error InvalidKeysForSalt();

    error PredictAddressDisabled();

    error FundsRecoveryActivationDeadlinePending();

    /*///////////////////////////////////////////////////////////////
                                        KEY MANAGEMENT
    ///////////////////////////////////////////////////////////////*/

    error InvalidRequest();

    error InvalidKeySignature(address from);

    error KeyAlreadyInvalid();

    error KeyAlreadyValid();

    error KeyNotFound();

    error CannotRemoveLastKey();

    /*///////////////////////////////////////////////////////////////
                                     GAS FEE REBATE
    ///////////////////////////////////////////////////////////////*/

    error InvalidDeductGasFunction(bytes4 sig);

    /*///////////////////////////////////////////////////////////////
                                FEATURE FLAGS
    ///////////////////////////////////////////////////////////////*/

    error FundsRecoveryNotActive();
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { UUPSImplementation } from "@synthetixio/core-contracts/contracts/proxy/UUPSImplementation.sol";

/// @dev The below contract is only used as an intermediary implementation contract
/// when initializing the proxy to make sure that, when deployed using CREATE2,
/// we always get the same contract address as the bytecode is deterministic.
contract InitialProxyImplementation is UUPSImplementation {
    function upgradeTo(address newImplementation) public override {
        _upgradeTo(newImplementation);
    }
}