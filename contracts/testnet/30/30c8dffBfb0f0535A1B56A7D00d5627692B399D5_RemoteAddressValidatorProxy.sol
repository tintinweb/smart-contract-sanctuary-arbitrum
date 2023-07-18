// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IOwnable Interface
 * @notice IOwnable is an interface that abstracts the implementation of a
 * contract with ownership control features. It's commonly used in upgradable
 * contracts and includes the functionality to get current owner, transfer
 * ownership, and propose and accept ownership.
 */
interface IOwnable {
    error NotOwner();
    error InvalidOwner();

    event OwnershipTransferStarted(address indexed newOwner);
    event OwnershipTransferred(address indexed newOwner);

    /**
     * @notice Returns the current owner of the contract.
     * @return address The address of the current owner
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the address of the pending owner of the contract.
     * @return address The address of the pending owner
     */
    function pendingOwner() external view returns (address);

    /**
     * @notice Transfers ownership of the contract to a new address
     * @param newOwner The address to transfer ownership to
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice Proposes to transfer the contract's ownership to a new address.
     * The new owner needs to accept the ownership explicitly.
     * @param newOwner The address to transfer ownership to
     */
    function proposeOwnership(address newOwner) external;

    /**
     * @notice Transfers ownership to the pending owner.
     * @dev Can only be called by the pending owner
     */
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// General interface for upgradable contracts
interface IProxy {
    error InvalidOwner();
    error InvalidImplementation();
    error SetupFailed();
    error NotOwner();
    error AlreadyInitialized();

    function implementation() external view returns (address);

    function setup(bytes calldata setupParams) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from './IOwnable.sol';

// General interface for upgradable contracts
interface IUpgradable is IOwnable {
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();
    error NotProxy();

    event Upgraded(address indexed newImplementation);

    function implementation() external view returns (address);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;

    function setup(bytes calldata data) external;

    function contractId() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from '../interfaces/IProxy.sol';

/**
 * @title BaseProxy Contract
 * @dev This abstract contract implements a basic proxy that stores an implementation address. Fallback function
 * calls are delegated to the implementation. This contract is meant to be inherited by other proxy contracts.
 */
abstract contract BaseProxy is IProxy {
    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    // keccak256('owner')
    bytes32 internal constant _OWNER_SLOT = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;

    /**
     * @dev Returns the current implementation address.
     * @return implementation_ The address of the current implementation contract
     */
    function implementation() public view virtual returns (address implementation_) {
        assembly {
            implementation_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /**
     * @dev Shadows the setup function of the implementation contract so it can't be called directly via the proxy.
     * @param params The setup parameters for the implementation contract.
     */
    function setup(bytes calldata params) external {}

    /**
     * @dev Returns the contract ID. It can be used as a check during upgrades.
     * Meant to be overridden in derived contracts.
     * @return bytes32 The contract ID
     */
    function contractId() internal pure virtual returns (bytes32) {
        return bytes32(0);
    }

    /**
     * @dev Fallback function. Delegates the call to the current implementation contract.
     */
    fallback() external payable virtual {
        address implementation_ = implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation_, 0, calldatasize(), 0, 0)
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

    /**
     * @dev Payable fallback function. Can be overridden in derived contracts.
     */
    receive() external payable virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from '../interfaces/IProxy.sol';
import { IUpgradable } from '../interfaces/IUpgradable.sol';
import { BaseProxy } from './BaseProxy.sol';

/**
 * @title Proxy Contract
 * @notice A proxy contract that delegates calls to a designated implementation contract. Inherits from BaseProxy.
 * @dev The constructor takes in the address of the implementation contract, the owner address, and any optional setup
 * parameters for the implementation contract.
 */
contract Proxy is BaseProxy {
    /**
     * @notice Constructs the proxy contract with a the implementation address, owner address, and optional setup parameters.
     * @param implementationAddress The address of the implementation contract
     * @param owner The owner address
     * @param setupParams Optional parameters to setup the implementation contract
     * @dev The constructor verifies that the owner address is not the zero address and that the contract ID of the implementation is valid.
     * It then stores the implementation address and owner address in their designated storage slots and calls the setup function on the
     * implementation (if setup params exist).
     */
    constructor(
        address implementationAddress,
        address owner,
        bytes memory setupParams
    ) {
        if (owner == address(0)) revert InvalidOwner();

        bytes32 id = contractId();
        if (id != bytes32(0) && IUpgradable(implementationAddress).contractId() != id) revert InvalidImplementation();

        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementationAddress)
            sstore(_OWNER_SLOT, owner)
        }

        if (setupParams.length != 0) {
            (bool success, ) = implementationAddress.delegatecall(
                abi.encodeWithSelector(IUpgradable.setup.selector, setupParams)
            );
            if (!success) revert SetupFailed();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Proxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Proxy.sol';

/**
 * @title RemoteAddressValidatorProxy
 * @dev Proxy contract for the RemoteAddressValidator contract. Inherits from the Proxy contract.
 */
contract RemoteAddressValidatorProxy is Proxy {
    bytes32 private constant CONTRACT_ID = keccak256('remote-address-validator');

    /**
     * @dev Constructs the RemoteAddressValidatorProxy contract.
     * @param implementationAddress Address of the RemoteAddressValidator implementation
     * @param owner Address of the owner of the proxy
     * @param params The params to be passed to the _setup function of the implementation.
     */
    constructor(address implementationAddress, address owner, bytes memory params) Proxy(implementationAddress, owner, params) {}

    /**
     * @dev Override for the `contractId` function in Proxy. Returns a unique identifier for this contract.
     * @return bytes32 Identifier for this contract.
     */
    function contractId() internal pure override returns (bytes32) {
        return CONTRACT_ID;
    }
}