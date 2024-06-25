// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDiamondCut} from '../interfaces/IDiamondCut.sol';
import {LibContractOwner} from '../libraries/LibContractOwner.sol';
import {LibDiamond} from '../libraries/LibDiamond.sol';

/// @title LG Diamond
/// @notice Adapted from the Diamond 3 reference implementation by Nick Mudge:
/// @notice https://github.com/mudgen/diamond-3-hardhat
contract Diamond {
    error FunctionDoesNotExist(bytes4 methodSelector);
    error DiamondAlreadyInitialized();

    constructor(address diamondCutFacet) payable {
        initializeDiamond(diamondCutFacet);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        /* solhint-disable no-inline-assembly */
        // get facet from function selector
        address facet = LibDiamond.diamondStorage().selectorToFacetAndPosition[msg.sig].facetAddress;
        if (facet == address(0)) revert FunctionDoesNotExist(msg.sig);
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
        /* solhint-enable no-inline-assembly */
    }

    /// @notice Initializes the diamond, by adding the `diamondCut` method and setting the owner.
    /// @dev This function is automatically called by the constructor.
    /// @dev The code is separated out to facilitate on-chain copying utilities.
    function initializeDiamond(address diamondCutFacet) public {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        if (ds.initialized) revert DiamondAlreadyInitialized();

        // Attach the diamondCut function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: new bytes4[](1)
        });
        cut[0].functionSelectors[0] = IDiamondCut.diamondCut.selector;

        LibDiamond.diamondCut(cut);

        //  When deployed from an EOA this will be the owner wallet,
        //  when deployed from the clone function, the copier contract will be the owner.
        LibContractOwner.setContractOwner(msg.sender);

        ds.initialized = true;
    }

    receive() external payable {}
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

import {IDiamondCut} from '../interfaces/IDiamondCut.sol';
import {LibContractOwner} from './LibContractOwner.sol';

/// @title LibDiamond
/// @notice Library for the common LG implementation of ERC-2535 Diamond Proxy
/// @notice Adapted from the Diamond 3 reference implementation by Nick Mudge:
/// @notice https://github.com/mudgen/diamond-3-hardhat
/// @custom:storage-location erc2535:diamond.standard.diamond.storage
library LibDiamond {
    error InvalidFacetCutAction(IDiamondCut.FacetCutAction action);

    /// @notice Emitted when facets are added or removed
    /// @dev ERC-2535
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    //  @dev Standard storage slot for the ERC-2535 Diamond storage
    //  @dev keccak256('diamond.standard.diamond.storage')
    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        0xc8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131c;

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // true if the diamond has been initialized
        bool initialized; //  THIS IS ONLY SET BY THE DIAMOND CONSTRUCTOR!
    }

    /// @notice Storage slot for Diamond storage
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice Ensures that the caller is the contract owner, or throws an error.
    /// @dev Passthrough to LibContractOwner.enforceIsContractOwner()
    /// @custom:throws LibAccess: Must be contract owner
    function enforceIsContractOwner() internal view {
        LibContractOwner.enforceIsContractOwner();
    }

    // Internal function version of diamondCut
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ++facetIndex) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert InvalidFacetCutAction(action);
            }
        }
        emit DiamondCut(_diamondCut, address(0), '');
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, 'LibDiamondCut: No selectors in facet to cut');
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ++selectorIndex) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            ++selectorPosition;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, 'LibDiamondCut: No selectors in facet to cut');
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ++selectorIndex) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            ++selectorPosition;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, 'LibDiamondCut: No selectors in facet to cut');
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), 'LibDiamondCut: Remove facet address must be address(0)');
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ++selectorIndex) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, 'LibDiamondCut: New facet has no code');
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}