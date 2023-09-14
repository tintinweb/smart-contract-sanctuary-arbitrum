// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {IVaultFactory} from "@src/interfaces/IVaultFactory.sol";
import {ISafe} from "@src/interfaces/ISafe.sol";

import "@safe-contracts/proxies/SafeProxyFactory.sol";

// ! This contract is heavily inspired by Alec DiFederico's (@alecdifederico on twitter) work at reNFT.

contract VaultFactory is IVaultFactory {
    // storage slot for the factory
    // This enables safe delegate calls to the factory
    bytes32 public constant STORAGE_SLOT = keccak256("DAMM.VaultFactory.storage.slot");

    modifier isOwner() {
        require(msg.sender == _getStorageSlot().owner, "Unauthorized: Only owner");
        _;
    }

    mapping(address vault => uint256 nonce) public deployedVaults;

    constructor(address _safeFactory, address _fallbackHandler, address _singleton, address _owner) {
        StorageSlot storage slot = _getStorageSlot();

        slot.safeFactory = _safeFactory;
        slot.fallbackHandler = _fallbackHandler;
        slot.singleton = _singleton;
        slot.nonce = 0;
        slot.owner = _owner;
    }

    function deployVault(address[] memory _owners, uint256 _threshold, address _tradingModule, address _vaultGuard)
        public
        isOwner
        returns (address vault)
    {
        require(_owners.length > 0, "VaultFactory: No owners");
        require(_threshold > 0 && _threshold <= _owners.length, "VaultFactory: Invalid threshold");

        StorageSlot storage slot = _getStorageSlot();

        // an incremental salt nonce to add with the safe deployment
        uint256 saltNonce = slot.nonce + 1;

        // Delegate call from the vault so that the trading module module can be enabled right after the vault is deployed
        // and the guard is set.
        bytes memory data = abi.encodeCall(VaultFactory.vaultDeploymentCallback, (_tradingModule, _vaultGuard));

        // create gnosis safe initializer payload
        bytes memory initializerPayload = abi.encodeCall(
            ISafe.setup,
            (
                _owners, // owners
                _threshold, // multisig signer threshold
                address(this), // to
                data, // data
                slot.fallbackHandler, // fallback manager
                address(0), // payment token
                0, // payment amount
                payable(address(0)) // payment receiver, TODO: check this is correct
            )
        );

        // deploy a safe proxy using initializer values for the Safe.setup() call
        // with a salt nonce that is unique to each chain to guarantee cross-chain unique safe addresses
        vault = address(
            SafeProxyFactory(slot.safeFactory).createProxyWithNonce(
                slot.singleton, initializerPayload, uint256(keccak256(abi.encode(saltNonce, block.chainid)))
            )
        );

        // register the vault with the factory
        deployedVaults[vault] = saltNonce;

        // increment nonce
        slot.nonce = saltNonce;

        emit VaultDeployed(vault, _owners, _vaultGuard, _tradingModule, saltNonce);
    }

    // INVARIANT: This function assumes the invariant that delegate call will be disabled on safe contracts
    // via the vault guard. If delegate call were to be allowed, then a safe could call this function after
    // deployment and change the module/guard contracts which would allow transfering of tokens out of the vault
    function vaultDeploymentCallback(address _tradingModule, address _vaultGuard) external {
        ISafe(address(this)).enableModule(_tradingModule);

        ISafe(address(this)).setGuard(_vaultGuard);
    }

    function _getStorageSlot() internal pure returns (StorageSlot storage s) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            s.slot := slot
        }
    }

    function getSafeFactory() public view returns (address) {
        return _getStorageSlot().safeFactory;
    }

    function getFallbackHandler() public view returns (address) {
        return _getStorageSlot().fallbackHandler;
    }

    function getSingleton() public view returns (address) {
        return _getStorageSlot().singleton;
    }

    function getNonce() public view returns (uint256) {
        return _getStorageSlot().nonce;
    }

    function getOwner() public view returns (address) {
        return _getStorageSlot().owner;
    }

    function getDeployedVaultNonce(address vault) public view returns (uint256) {
        return deployedVaults[vault];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVaultFactory {
    event VaultDeployed(
        address indexed vault, address[] owners, address vaultGuard, address tradingModule, uint256 nonce
    );

    struct StorageSlot {
        address safeFactory; // Gnosis Safe Factory address
        address fallbackHandler; // Handler for fallback calls to this contract
        address singleton; // Address of the Gnosis Safe singleton contract
        address owner; // Vault Factory owner
        uint256 nonce; // Vault Factory nonce
    }

    function vaultDeploymentCallback(address _tradingModule, address _vaultGuard) external;

    function getDeployedVaultNonce(address _vault) external view returns (uint256);

    function getOwner() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Enum} from "@safe-contracts/common/Enum.sol";

interface ISafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);

    /**
     * @notice Execute `operation` (0: Call, 1: DelegateCall) to `to` with `value` (Native Token) and return data
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction.
     * @return success Boolean flag indicating if the call succeeded.
     * @return returnData Data returned by the call.
     */
    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Enum.Operation operation)
        external
        returns (bool success, bytes memory returnData);

    // @dev Allows to swap/replace an owner from the Safe with another address.
    ///      This can only be done via a Safe transaction.
    /// @notice Replaces the owner `oldOwner` in the Safe with `newOwner`.
    /// @param prevOwner Owner that pointed to the owner to be replaced in the linked list
    /// @param oldOwner Owner address to be replaced.
    /// @param newOwner New owner address.
    function swapOwner(address prevOwner, address oldOwner, address newOwner) external;

    // @dev Returns array of owners.
    /// @return Array of Safe owners.
    function getOwners() external view returns (address[] memory);

    /// @dev Allows to add a module to the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Enables the module `module` for the Safe.
    /// @param module Module to be whitelisted.
    function enableModule(address module) external;

    /// @dev Set a guard that checks transactions before execution
    /// @param guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address guard) external;

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param to Contract address for optional delegate call.
    /// @param data Data payload for optional delegate call.
    /// @param fallbackHandler Handler for fallback calls to this contract
    /// @param paymentToken Token that should be used for the payment (0 is ETH)
    /// @param payment Value that should be paid
    /// @param paymentReceiver Address that should receive the payment (or 0 if tx.origin)
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);

    /// @return True if address is owner of the Safe
    function isOwner(address owner) external view returns (bool);
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