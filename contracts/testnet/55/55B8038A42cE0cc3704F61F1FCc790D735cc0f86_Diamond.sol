// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * \
 * Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 *
 * Implementation of a diamond.
 * /*****************************************************************************
 */

import { LibDiamond } from "./LibDiamond.sol";
import { IDiamondCut } from "./IDiamondCut.sol";

contract Diamond {
    struct Initialization {
        address initContract;
        bytes initData;
    }

    /// @notice This construct a diamond contract
    /// @param _contractOwner the owner of the contract. With default DiamondCutFacet, this is the sole address allowed to make further cuts.
    /// @param _diamondCut the list of facet to add
    /// @param _initializations the list of initialization pair to execute. This allow to setup a contract with multiple level of independent initialization.
    constructor(
        address _contractOwner,
        IDiamondCut.FacetCut[] memory _diamondCut,
        Initialization[] memory _initializations
    ) payable {
        if (_contractOwner != address(0)) {
            LibDiamond.setContractOwner(_contractOwner);
        }

        LibDiamond.diamondCut(_diamondCut, address(0), "");

        for (uint256 i = 0; i < _initializations.length; i++) {
            LibDiamond.initializeDiamondCut(_initializations[i].initContract, _initializations[i].initData);
        }
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    /* solhint-disable no-complex-fallback */
    fallback() external payable {
        LibDiamond.DiamondStorage storage _ds;
        bytes32 _position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            _ds.slot := _position
        }
        // get facet from function selector
        address _facet = _ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(_facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), _facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable { }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 * /*****************************************************************************
 */

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

    event DiamondCut(FacetCut[] diamondCut, address init, bytes data);
}

/* solhint-disable reason-string, avoid-low-level-calls */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * \
 * Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 * /*****************************************************************************
 */
import { IDiamondCut } from "./IDiamondCut.sol";

library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds_) {
        bytes32 _position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds_.slot := _position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage _ds = diamondStorage();
        address _previousOwner = _ds.contractOwner;
        _ds.contractOwner = _newOwner;
        emit OwnershipTransferred(_previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] diamondCut, address init, bytes data);

    // Internal function version of diamondCut
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 _facetIndex; _facetIndex < _diamondCut.length; _facetIndex++) {
            IDiamondCut.FacetCutAction _action = _diamondCut[_facetIndex].action;
            if (_action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[_facetIndex].facetAddress, _diamondCut[_facetIndex].functionSelectors);
            } else if (_action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[_facetIndex].facetAddress, _diamondCut[_facetIndex].functionSelectors);
            } else if (_action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[_facetIndex].facetAddress, _diamondCut[_facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage _ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 _selectorPosition = uint96(_ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (_selectorPosition == 0) {
            addFacet(_ds, _facetAddress);
        }
        for (uint256 _selectorIndex; _selectorIndex < _functionSelectors.length; _selectorIndex++) {
            bytes4 _selector = _functionSelectors[_selectorIndex];
            address _oldFacetAddress = _ds.selectorToFacetAndPosition[_selector].facetAddress;
            require(_oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(_ds, _selector, _selectorPosition, _facetAddress);
            _selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage _ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 _selectorPosition = uint96(_ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (_selectorPosition == 0) {
            addFacet(_ds, _facetAddress);
        }
        for (uint256 _selectorIndex; _selectorIndex < _functionSelectors.length; _selectorIndex++) {
            bytes4 _selector = _functionSelectors[_selectorIndex];
            address _oldFacetAddress = _ds.selectorToFacetAndPosition[_selector].facetAddress;
            require(_oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(_ds, _oldFacetAddress, _selector);
            addFunction(_ds, _selector, _selectorPosition, _facetAddress);
            _selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage _ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 _selectorIndex; _selectorIndex < _functionSelectors.length; _selectorIndex++) {
            bytes4 _selector = _functionSelectors[_selectorIndex];
            address _oldFacetAddress = _ds.selectorToFacetAndPosition[_selector].facetAddress;
            removeFunction(_ds, _oldFacetAddress, _selector);
        }
    }

    function addFacet(DiamondStorage storage _ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        _ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(_ds.facetAddresses.length);
        _ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage _ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        _ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        _ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = uint16(_selectorPosition);
        _ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage _ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 _selectorPosition = _ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 _lastSelectorPosition = _ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with _lastSelector
        if (_selectorPosition != _lastSelectorPosition) {
            bytes4 _lastSelector = _ds.facetFunctionSelectors[_facetAddress].functionSelectors[_lastSelectorPosition];
            _ds.facetFunctionSelectors[_facetAddress].functionSelectors[_selectorPosition] = _lastSelector;
            _ds.selectorToFacetAndPosition[_lastSelector].functionSelectorPosition = uint16(_selectorPosition);
        }
        // delete the last selector
        _ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete _ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (_lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 _lastFacetAddressPosition = _ds.facetAddresses.length - 1;
            uint256 _facetAddressPosition = _ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (_facetAddressPosition != _lastFacetAddressPosition) {
                address _lastFacetAddress = _ds.facetAddresses[_lastFacetAddressPosition];
                _ds.facetAddresses[_facetAddressPosition] = _lastFacetAddress;
                _ds.facetFunctionSelectors[_lastFacetAddress].facetAddressPosition = uint16(_facetAddressPosition);
            }
            _ds.facetAddresses.pop();
            delete _ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool _success, bytes memory _error) = _init.delegatecall(_calldata);
            if (!_success) {
                if (_error.length > 0) {
                    // bubble up the _error
                    assembly {
                        revert(add(32, _error), mload(_error))
                    }
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 _contractSize;
        assembly {
            _contractSize := extcodesize(_contract)
        }
        require(_contractSize > 0, _errorMessage);
    }
}