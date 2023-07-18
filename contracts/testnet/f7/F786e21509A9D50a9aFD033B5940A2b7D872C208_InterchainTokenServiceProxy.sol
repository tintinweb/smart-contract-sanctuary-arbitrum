// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ContractAddress } from '../utils/ContractAddress.sol';

error AlreadyDeployed();
error EmptyBytecode();
error DeployFailed();

/**
 * @title CreateDeployer Contract
 * @notice This contract deploys new contracts using the `CREATE` opcode and is used as part of
 * the `Create3` deployment method.
 */
contract CreateDeployer {
    /**
     * @dev Deploys a new contract with the specified bytecode using the CREATE opcode.
     * @param bytecode The bytecode of the contract to be deployed
     */
    function deploy(bytes memory bytecode) external {
        address deployed;

        assembly {
            deployed := create(0, add(bytecode, 32), mload(bytecode))
            if iszero(deployed) {
                revert(0, 0)
            }
        }
    }
}

/**
 * @title Create3 Library
 * @notice This library can be used to deploy a contract with a deterministic address that only
 * depends on the sender and salt, not the contract bytecode.
 */
library Create3 {
    using ContractAddress for address;

    bytes32 internal constant DEPLOYER_BYTECODE_HASH = keccak256(type(CreateDeployer).creationCode);

    /**
     * @dev Deploys a new contract using the CREATE3 method. This function first deploys the
     * CreateDeployer contract using the CREATE2 opcode and then utilizes the CreateDeployer
     * to deploy the new contract with the CREATE opcode.
     * @param salt A salt to further randomize the contract address
     * @param bytecode The bytecode of the contract to be deployed
     * @return deployed The address of the deployed contract
     */
    function deploy(bytes32 salt, bytes memory bytecode) internal returns (address deployed) {
        deployed = deployedAddress(address(this), salt);

        if (deployed.isContract()) revert AlreadyDeployed();
        if (bytecode.length == 0) revert EmptyBytecode();

        // Deploy using create2
        CreateDeployer deployer = new CreateDeployer{ salt: salt }();

        if (address(deployer) == address(0)) revert DeployFailed();

        deployer.deploy(bytecode);
    }

    /**
     * @dev Compute the deployed address that will result from the CREATE3 method.
     * @param salt A salt to further randomize the contract address
     * @param sender The sender address which would deploy the contract
     * @return deployed The deterministic contract address if it was deployed
     */
    function deployedAddress(address sender, bytes32 salt) internal pure returns (address deployed) {
        address deployer = address(
            uint160(uint256(keccak256(abi.encodePacked(hex'ff', sender, salt, DEPLOYER_BYTECODE_HASH))))
        );

        deployed = address(uint160(uint256(keccak256(abi.encodePacked(hex'd6_94', deployer, hex'01')))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from './IProxy.sol';

// General interface for upgradable contracts
interface IFinalProxy is IProxy {
    function isFinal() external view returns (bool);

    function finalUpgrade(bytes memory bytecode, bytes calldata setupParams) external returns (address);
}

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
import { IFinalProxy } from '../interfaces/IFinalProxy.sol';
import { Create3 } from '../deploy/Create3.sol';
import { BaseProxy } from './BaseProxy.sol';
import { Proxy } from './Proxy.sol';

/**
 * @title FinalProxy Contract
 * @notice The FinalProxy contract is a proxy that can be upgraded to a final implementation
 * that uses less gas than regular proxy calls. It inherits from the Proxy contract and implements
 * the IFinalProxy interface.
 */
contract FinalProxy is Proxy, IFinalProxy {
    bytes32 internal constant FINAL_IMPLEMENTATION_SALT = keccak256('final-implementation');

    /**
     * @dev Constructs a FinalProxy contract with a given implementation address, owner, and setup parameters.
     * @param implementationAddress The address of the implementation contract
     * @param owner The owner of the proxy contract
     * @param setupParams Parameters to setup the implementation contract
     */
    constructor(
        address implementationAddress,
        address owner,
        bytes memory setupParams
    ) Proxy(implementationAddress, owner, setupParams) {}

    /**
     * @dev The final implementation address takes less gas to compute than reading an address from storage. That makes FinalProxy
     * more efficient when making delegatecalls to the implementation (assuming it is the final implementation).
     * @return implementation_ The address of the final implementation if it exists, otherwise the current implementation
     */
    function implementation() public view override(BaseProxy, IProxy) returns (address implementation_) {
        implementation_ = _finalImplementation();
        if (implementation_ == address(0)) {
            implementation_ = super.implementation();
        }
    }

    /**
     * @dev Checks if the final implementation has been deployed.
     * @return bool True if the final implementation exists, false otherwise
     */
    function isFinal() public view returns (bool) {
        return _finalImplementation() != address(0);
    }

    /**
     * @dev Computes the final implementation address.
     * @return implementation_ The address of the final implementation, or the zero address if the final implementation
     * has not yet been deployed
     */
    function _finalImplementation() internal view virtual returns (address implementation_) {
        /**
         * @dev Computing the address is cheaper than using storage
         */
        implementation_ = Create3.deployedAddress(address(this), FINAL_IMPLEMENTATION_SALT);

        if (implementation_.code.length == 0) implementation_ = address(0);
    }

    /**
     * @dev Upgrades the proxy to a final implementation.
     * @param bytecode The bytecode of the final implementation contract
     * @param setupParams The parameters to setup the final implementation contract
     * @return finalImplementation_ The address of the final implementation contract
     */
    function finalUpgrade(bytes memory bytecode, bytes calldata setupParams)
        public
        returns (address finalImplementation_)
    {
        address owner;
        assembly {
            owner := sload(_OWNER_SLOT)
        }
        if (msg.sender != owner) revert NotOwner();

        finalImplementation_ = Create3.deploy(FINAL_IMPLEMENTATION_SALT, bytecode);
        if (setupParams.length != 0) {
            (bool success, ) = finalImplementation_.delegatecall(
                abi.encodeWithSelector(BaseProxy.setup.selector, setupParams)
            );
            if (!success) revert SetupFailed();
        }
    }
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

library ContractAddress {
    function isContract(address _address) internal view returns (bool) {
        bytes32 existingCodeHash = _address.codehash;

        // https://eips.ethereum.org/EIPS/eip-1052
        // keccak256('') == 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
        return
            existingCodeHash != bytes32(0) &&
            existingCodeHash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { FinalProxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/FinalProxy.sol';

/**
 * @title InterchainTokenServiceProxy
 * @dev Proxy contract for interchain token service contracts. Inherits from the FinalProxy contract.
 */
contract InterchainTokenServiceProxy is FinalProxy {
    bytes32 private constant CONTRACT_ID = keccak256('interchain-token-service');

    /**
     * @dev Constructs the InterchainTokenServiceProxy contract.
     * @param implementationAddress Address of the interchain token service implementation
     * @param owner Address of the owner of the proxy
     */
    constructor(
        address implementationAddress,
        address owner,
        address operator
    ) FinalProxy(implementationAddress, owner, abi.encodePacked(operator)) {}

    /**
     * @dev Override for the 'contractId' function in FinalProxy. Returns a unique identifier for this contract.
     * @return bytes32 identifier for this contract
     */
    function contractId() internal pure override returns (bytes32) {
        return CONTRACT_ID;
    }
}