// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC165} from '../interfaces/IERC165.sol';
import {LibContractOwner} from '../libraries/LibContractOwner.sol';
import {LibSupportsInterface} from '../libraries/LibSupportsInterface.sol';

/// @title LG implementation of ERC-165 Standard Interface Detection
/// @author [email protected]
contract SupportsInterfaceFacet is IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return LibSupportsInterface.supportsInterface(interfaceID);
    }

    /// @notice Set whether an interface is implemented
    /// @dev Only the contract owner can call this function
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @param implemented `true` if the contract implements `interfaceID`
    function setSupportsInterface(bytes4 interfaceID, bool implemented) external {
        LibContractOwner.enforceIsContractOwner();
        LibSupportsInterface.setSupportsInterface(interfaceID, implemented);
    }

    /// @notice Set a list of interfaces as implemented or not
    /// @dev Only the contract owner can call this function
    /// @param interfaceIDs The interface identifiers, as specified in ERC-165
    /// @param allImplemented `true` if the contract implements all interfaces
    function setSupportsInterfaces(bytes4[] calldata interfaceIDs, bool allImplemented) external {
        LibContractOwner.enforceIsContractOwner();
        for (uint i = 0; i < interfaceIDs.length; ++i) {
            LibSupportsInterface.setSupportsInterface(interfaceIDs[i], allImplemented);
        }
    }

    /// @notice Returns a list of interfaces that have (ever) been supported
    /// @return The list of interfaces
    function interfaces() external view returns (LibSupportsInterface.KnownInterface[] memory) {
        return LibSupportsInterface.getKnownInterfaces();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title ERC-165 Standard Interface Detection
/// @dev https://eips.ethereum.org/EIPS/eip-165
interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {LibContractOwner} from '../libraries/LibContractOwner.sol';

/// @title Library for the common LG implementation of ERC-165
/// @author [email protected]
/// @custom:storage-location erc7201:games.laguna.LibSupportsInterface
library LibSupportsInterface {
    bytes32 public constant SUPPORTS_INTERFACE_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256('games.laguna.LibSupportsInterface')) - 1)) & ~bytes32(uint256(0xff));

    struct KnownInterface {
        bytes4 selector;
        bool supported;
    }

    struct SupportsInterfaceStorage {
        mapping(bytes4 selector => bool supported) supportedInterfaces;
        bytes4[] interfaces;
    }

    /// @notice Storage slot for SupportsInterface state data
    function supportsInterfaceStorage() internal pure returns (SupportsInterfaceStorage storage storageSlot) {
        bytes32 position = SUPPORTS_INTERFACE_STORAGE_POSITION;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            storageSlot.slot := position
        }
    }

    /// @notice Checks if a contract implements an interface
    /// @param _interfaceId Interface ID to check
    /// @return true if the contract implements the interface
    function supportsInterface(bytes4 _interfaceId) internal view returns (bool) {
        return supportsInterfaceStorage().supportedInterfaces[_interfaceId];
    }

    /// @notice Sets whether a contract implements an interface
    /// @param _interfaceId Interface ID to set
    /// @param _implemented true if the contract implements the interface
    function setSupportsInterface(bytes4 _interfaceId, bool _implemented) internal {
        SupportsInterfaceStorage storage s = supportsInterfaceStorage();

        if (_implemented && !s.supportedInterfaces[_interfaceId]) {
            s.interfaces.push(_interfaceId);
        }

        s.supportedInterfaces[_interfaceId] = _implemented;
    }

    /// @notice Returns the list of interfaces this contract has supported, and whether they are supported currently.
    /// @return The list of interfaces
    function getKnownInterfaces() internal view returns (KnownInterface[] memory) {
        SupportsInterfaceStorage storage s = supportsInterfaceStorage();
        KnownInterface[] memory interfaces = new KnownInterface[](s.interfaces.length);
        for (uint i = 0; i < s.interfaces.length; ++i) {
            interfaces[i] = KnownInterface({
                selector: s.interfaces[i],
                supported: s.supportedInterfaces[s.interfaces[i]]
            });
        }
        return interfaces;
    }

    /// @notice Calculate the interface ID for a list of function selectors
    /// @dev Per ERC-165: "We define the interface identifier as the XOR of all function selectors in the interface"
    /// @param functionSelectors The list of function selectors in the interface
    /// @return interfaceId The ERC-165 interface ID
    function calculateInterfaceId(bytes4[] memory functionSelectors) internal pure returns (bytes4 interfaceId) {
        for (uint256 i = 0; i < functionSelectors.length; ++i) {
            interfaceId ^= functionSelectors[i];
        }
    }
}