// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibContractOwner} from '../libraries/LibContractOwner.sol';
import {LibProxyImplementation} from '../libraries/LibProxyImplementation.sol';

/// @title LG partial implementation of ERC-1967 Proxy Implementation
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @author [email protected]
contract DiamondProxyFacet {
    /// @notice Sets the "implementation" contract address
    /// @param _implementation The new implementation contract
    /// @custom:emits Upgraded
    function setImplementation(address _implementation) external {
        LibContractOwner.enforceIsContractOwner();
        LibProxyImplementation.setImplementation(_implementation);
    }

    /// @notice Get the dummy "implementation" contract address
    /// @return The dummy "implementation" contract address
    function implementation() external view returns (address) {
        return LibProxyImplementation.getImplementation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Library for the common LG implementation of ERC-173 Contract Ownership Standard
/// @author [email protected]
/// @custom:storage-location erc1967:eip1967.proxy.admin
library LibContractOwner {
    error CallerIsNotContractOwner();

    /// @notice This emits when ownership of a contract changes.
    /// @dev ERC-173
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Emitted when the admin account has changed.
    /// @dev ERC-1967
    event AdminChanged(address previousAdmin, address newAdmin);

    //  @dev Standard storage slot for the ERC-1967 admin address
    //  @dev bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 private constant ADMIN_SLOT_POSITION = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    struct LibOwnerStorage {
        address contractOwner;
    }

    /// @notice Storage slot for Contract Owner state data
    function ownerStorage() internal pure returns (LibOwnerStorage storage storageSlot) {
        bytes32 position = ADMIN_SLOT_POSITION;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            storageSlot.slot := position
        }
    }

    /// @notice Sets the contract owner
    /// @param newOwner The new owner
    /// @custom:emits OwnershipTransferred
    function setContractOwner(address newOwner) internal {
        LibOwnerStorage storage ls = ownerStorage();
        address previousOwner = ls.contractOwner;
        ls.contractOwner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
        emit AdminChanged(previousOwner, newOwner);
    }

    /// @notice Gets the contract owner wallet
    /// @return owner The contract owner
    function contractOwner() internal view returns (address owner) {
        owner = ownerStorage().contractOwner;
    }

    /// @notice Ensures that the caller is the contract owner, or throws an error.
    /// @custom:throws LibAccess: Must be contract owner
    function enforceIsContractOwner() internal view {
        if (msg.sender != ownerStorage().contractOwner) revert CallerIsNotContractOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Library for the common LG implementation of the "Implementation" Proxy contract.
/// @title For compatibility, we support both ERC-1967 and ERC-1822
/// @author [email protected]
/// @notice The "implementation" here is a dummy contract to expose the diamond interface to block explorers.
/// @notice https://github.com/zdenham/diamond-etherscan/tree/main
/// @custom:storage-location erc1967:eip1967.proxy.implementation
/// @custom:storage-location erc1822:PROXIABLE
library LibProxyImplementation {
    /// @notice Emitted when the implementation is upgraded.
    /// @dev ERC-1967
    event Upgraded(address indexed implementation);

    //  @dev Standard storage slot for the ERC-1967 logic implementation address
    //  @dev bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant ERC_1967_SLOT_POSITION =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    //  @dev Standard storage slot for the ERC-1822 logic implementation address
    //  @dev keccak256("PROXIABLE")
    bytes32 internal constant ERC_1822_SLOT_POSITION =
        0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    struct AddressStorageStruct {
        address value;
    }

    /// @notice Storage slot for Contract Owner state data on ERC-1967
    function proxyImplementationStorage1967() internal pure returns (AddressStorageStruct storage storageSlot) {
        bytes32 position = ERC_1967_SLOT_POSITION;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            storageSlot.slot := position
        }
    }

    /// @notice Storage slot for Contract Owner state data on ERC-1822
    function proxyImplementationStorage1822() internal pure returns (AddressStorageStruct storage storageSlot) {
        bytes32 position = ERC_1822_SLOT_POSITION;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            storageSlot.slot := position
        }
    }

    /// @notice Sets the "implementation" contract address
    /// @param newImplementation The new implementation contract
    /// @custom:emits Upgraded
    function setImplementation(address newImplementation) internal {
        //  NOTE: Save the data in known storage slots for both ERC-1967 and ERC-1822
        proxyImplementationStorage1967().value = newImplementation;
        proxyImplementationStorage1822().value = newImplementation; //  This is stored in case a 3rd party reads the storage slot directly
        emit Upgraded(newImplementation);
    }

    /// @notice Gets the "implementation" contract address
    /// @return implementation The implementation contract
    function getImplementation() internal view returns (address implementation) {
        implementation = proxyImplementationStorage1967().value;
    }
}