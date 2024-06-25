// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DiamondFragment} from '../implementation/DiamondFragment.sol';
import {DiamondCutFragment} from '../implementation/DiamondCutFragment.sol';
import {DiamondLoupeFragment} from '../implementation/DiamondLoupeFragment.sol';
import {DiamondOwnerFragment} from '../implementation/DiamondOwnerFragment.sol';
import {DiamondProxyFragment} from '../implementation/DiamondProxyFragment.sol';
import {SupportsInterfaceFragment} from '../implementation/SupportsInterfaceFragment.sol';

/// @title Cut Diamond
/// @notice This is a dummy "implementation" contract for ERC-1967 compatibility,
/// @notice this interface is used by block explorers to generate the UI interface.
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
contract CutDiamond is
    DiamondFragment,
    DiamondCutFragment,
    DiamondLoupeFragment,
    DiamondOwnerFragment,
    DiamondProxyFragment,
    SupportsInterfaceFragment
{

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Diamond Interface Fragment
/// @dev Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
contract DiamondFragment {
    error FunctionDoesNotExist(bytes4 methodSelector);
    error DiamondAlreadyInitialized();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDiamondCut} from '../interfaces/IDiamondCut.sol';

/// @title DiamondCutFacet Interface Fragment
/// @dev Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
contract DiamondCutFragment {
    error InvalidFacetCutAction(IDiamondCut.FacetCutAction action);

    /// @notice Emitted when facets are added or removed
    /// @dev ERC-2535
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @dev The LG implementation DOES NOT SUPPORT initializers!
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    /// @custom:selector 0x1f931c1c == bytes4(keccak256("diamondCut((address,uint8,bytes4[])[],address,bytes)"))
    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external {}

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @dev This is a convenience implementation of the above
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @custom:selector 0xe57e69c6 == bytes4(keccak256("diamondCut((address,uint8,bytes4[])[])"))
    function diamondCut(IDiamondCut.FacetCut[] calldata _diamondCut) external {}

    /// @notice Removes one selector from the Diamond, using DiamondCut
    /// @param selector - The byte4 signature for a method selector to remove
    /// @custom:emits DiamondCut
    function cutSelector(bytes4 selector) external {}

    /// @notice Removes one selector from the Diamond, using removeFunction()
    /// @param selector - The byte4 signature for a method selector to remove
    function deleteSelector(bytes4 selector) external {}

    /// @notice Removes many selectors from the Diamond, using DiamondCut
    /// @param selectors - Array of byte4 signatures for method selectors to remove
    /// @custom:emits DiamondCut
    function cutSelectors(bytes4[] memory selectors) external {}

    /// @notice Removes many selectors from the Diamond, using removeFunctions()
    /// @param selectors - Array of byte4 signatures for method selectors to remove
    function deleteSelectors(bytes4[] memory selectors) external {}

    /// @notice Removes any selectors from the Diamond that come from a target
    /// @notice contract address, using DiamondCut.
    /// @param facet - The address of the Facet smart contract to remove
    /// @custom:emits DiamondCut
    function cutFacet(address facet) external {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDiamondLoupe} from '../interfaces/IDiamondLoupe.sol';

/// @title DiamondLoupe Facet Interface Fragment
/// @dev Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
contract DiamondLoupeFragment {
    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view returns (IDiamondLoupe.Facet[] memory facets_) {}

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_) {}

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_) {}

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC173} from '../interfaces/IERC173.sol';

/// @title DiamondOwner Facet Interface Fragment
/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
contract DiamondOwnerFragment is IERC173 {
    error CallerIsNotContractOwner();

    // /// @notice This emits when ownership of a contract changes.
    // /// @dev ERC-173
    // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Emitted when the admin account has changed.
    /// @dev ERC-1967
    event AdminChanged(address previousAdmin, address newAdmin);

    /// @notice Get the address of the owner
    /// @return The address of the owner.
    function owner() external view returns (address) {}

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    /// @custom:emits OwnershipTransferred
    /// @custom:emits AdminChanged
    function transferOwnership(address _newOwner) external {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title DiamondProxy Facet Interface Fragment
/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
contract DiamondProxyFragment {
    /// @notice Emitted when the implementation is upgraded.
    /// @dev ERC-1967
    event Upgraded(address indexed implementation);

    /// @notice Sets the "implementation" contract address
    /// @param _implementation The new implementation contract
    /// @custom:emits Upgraded
    function setImplementation(address _implementation) external {}

    /// @notice Get the dummy "implementation" contract address
    /// @return The dummy "implementation" contract address
    function implementation() external view returns (address) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibSupportsInterface} from '../libraries/LibSupportsInterface.sol';
import {IERC165} from '../interfaces/IERC165.sol';

/// @title SupportsInterface Facet Interface Fragment
/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
contract SupportsInterfaceFragment is IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {}

    /// @notice Set whether an interface is implemented
    /// @dev Only the contract owner can call this function
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @param implemented `true` if the contract implements `interfaceID`
    function setSupportsInterface(bytes4 interfaceID, bool implemented) external {}

    /// @notice Set a list of interfaces as implemented or not
    /// @dev Only the contract owner can call this function
    /// @param interfaceIDs The interface identifiers, as specified in ERC-165
    /// @param allImplemented `true` if the contract implements all interfaces
    function setSupportsInterfaces(bytes4[] calldata interfaceIDs, bool allImplemented) external {}

    /// @notice Returns a list of interfaces that have (ever) been supported
    /// @return The list of interfaces
    function interfaces() external view returns (LibSupportsInterface.KnownInterface[] memory) {}
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Adapted from the Diamond 3 reference implementation by Nick Mudge:
// https://github.com/mudgen/diamond-3-hardhat

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title ERC-173 Contract Ownership Standard
/// @dev The ERC-165 identifier for this interface is 0x7f5828d0
/// @dev https://eips.ethereum.org/EIPS/eip-173
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return The address of the owner.
    function owner() external view returns (address);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
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