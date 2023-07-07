// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.
pragma solidity ^0.8.10;

import {LibDiamond} from "src/libraries/diamond/LibDiamond.sol";
import {IDiamondCut} from "src/interfaces/diamond/IDiamondCut.sol";
import {IDiamondLoupe} from "src/interfaces/diamond/IDiamondLoupe.sol";
import {IERC173} from "src/interfaces/diamond/IERC173.sol";
import {IERC165} from "src/interfaces/diamond/IERC165.sol";

// When no function exists for function called
error FunctionNotFound(bytes4 _functionSelector);

// This is used in diamond constructor
// more arguments are added to this struct
// this avoids stack too deep errors
struct DiamondArgs {
    address init;
    bytes initCalldata;
    address owner;
}

contract BeaconDiamond {
    constructor(IDiamondCut.BeaconCut[] memory _diamondCut, DiamondArgs memory _args) payable {
        LibDiamond.setContractOwner(_args.owner);
        LibDiamond.diamondCut(_diamondCut, _args.init, _args.initCalldata);

        // Code can be added here to perform actions and set state variables.
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Internal                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}

    function _fallback() internal virtual {
        _beforeFallback();
        address impl = LibDiamond._implementation();
        if (impl == address(0)) {
            revert FunctionNotFound(msg.sig);
        }
        _delegate(impl);
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IDiamond} from "src/interfaces/diamond/IDiamond.sol";
import {IBeacon} from "openzeppelin-contracts/proxy/beacon/IBeacon.sol";
import {IDiamondCut} from "src/interfaces/diamond/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeBeacon to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error NoSelectorsGivenToAdd();
error NotContractOwner(address _user, address _contractOwner);
error NoSelectorsProvidedForBeaconForCut(address _beaconAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectBeaconCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromBeaconWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameBeacon(bytes4 _selector);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveBeaconAddressMustBeZeroAddress(address _beaconAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    /**
     * @notice Diamond storage position.
     */
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    /**
     * @notice Beacon and Selector position struct.
     */
    struct BeaconAddressAndSelectorPosition {
        address beaconAddress;
        uint16 selectorPosition;
    }

    /**
     * @notice Diamond storage.
     */
    struct DiamondStorage {
        // function selector => beacon address and selector position in selectors array
        mapping(bytes4 => BeaconAddressAndSelectorPosition) beaconAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    /**
     * @notice Get diamond storage.
     */
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SetBeacon(address indexed oldBeacon, address indexed newBeacon);

    /**
     * @notice Set owner.
     */
    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    /**
     * @notice Get owner.
     */
    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    /**
     * @notice If msg.sender not owner revert.
     */
    function enforceIsContractOwner() internal view {
        if (msg.sender != diamondStorage().contractOwner) {
            revert NotContractOwner(msg.sender, diamondStorage().contractOwner);
        }
    }

    event DiamondCut(IDiamondCut.BeaconCut[] _diamondCut, address _init, bytes _calldata);

    /**
     * @notice Procces to Add, replace or Remove Facets.
     */
    function diamondCut(IDiamondCut.BeaconCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        uint256 length = _diamondCut.length;
        for (uint256 beaconIndex; beaconIndex < length;) {
            bytes4[] memory functionSelectors = _diamondCut[beaconIndex].functionSelectors;
            address beaconAddress = _diamondCut[beaconIndex].beaconAddress;
            if (functionSelectors.length == 0) {
                revert NoSelectorsProvidedForBeaconForCut(beaconAddress);
            }
            IDiamondCut.BeaconCutAction action = _diamondCut[beaconIndex].action;
            if (action == IDiamond.BeaconCutAction.Add) {
                addFunctions(beaconAddress, functionSelectors);
            } else if (action == IDiamond.BeaconCutAction.Replace) {
                replaceFunctions(beaconAddress, functionSelectors);
            } else if (action == IDiamond.BeaconCutAction.Remove) {
                removeFunctions(beaconAddress, functionSelectors);
            } else {
                revert IncorrectBeaconCutAction(uint8(action));
            }
            unchecked {
                ++beaconIndex;
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    /**
     * @notice Procces to Add Facets.
     */
    function addFunctions(address _beaconAddress, bytes4[] memory _functionSelectors) internal {
        if (_beaconAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        enforceHasContractCode(_beaconAddress, "LibDiamondCut: Add beacon has no code");
        uint256 length = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < length;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldBeaconAddress = ds.beaconAddressAndSelectorPosition[selector].beaconAddress;
            if (oldBeaconAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            ds.beaconAddressAndSelectorPosition[selector] =
                BeaconAddressAndSelectorPosition(_beaconAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
            unchecked {
                ++selectorIndex;
            }
        }
    }

    /**
     * @notice Procces to Replace Facets.
     */
    function replaceFunctions(address _beaconAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        if (_beaconAddress == address(0)) {
            revert CannotReplaceFunctionsFromBeaconWithZeroAddress(_functionSelectors);
        }
        enforceHasContractCode(_beaconAddress, "LibDiamondCut: Replace beacont has no code");
        uint256 length = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < length;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldBeaconAddress = ds.beaconAddressAndSelectorPosition[selector].beaconAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if (oldBeaconAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if (oldBeaconAddress == _beaconAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameBeacon(selector);
            }
            if (oldBeaconAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old beacon address
            ds.beaconAddressAndSelectorPosition[selector].beaconAddress = _beaconAddress;
            unchecked {
                ++selectorIndex;
            }
        }
    }

    /**
     * @notice Procces to Remove Facets.
     */
    function removeFunctions(address _beaconAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if (_beaconAddress != address(0)) {
            revert RemoveBeaconAddressMustBeZeroAddress(_beaconAddress);
        }
        uint256 length = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < length;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            BeaconAddressAndSelectorPosition memory oldBeaconAddressAndSelectorPosition =
                ds.beaconAddressAndSelectorPosition[selector];
            if (oldBeaconAddressAndSelectorPosition.beaconAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }

            // can't remove immutable functions -- functions defined directly in the diamond
            if (oldBeaconAddressAndSelectorPosition.beaconAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (oldBeaconAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldBeaconAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.beaconAddressAndSelectorPosition[lastSelector].selectorPosition =
                    oldBeaconAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.beaconAddressAndSelectorPosition[selector];

            unchecked {
                ++selectorIndex;
            }
        }
    }

    /**
     * @notice Procces to initialize Diamond contract.
     */
    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    /**
     * @notice Enforce contract.
     */
    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }
    }

    /**
     * @notice get beacon implementation.
     */
    function _implementation() internal view returns (address) {
        return IBeacon(diamondStorage().beaconAddressAndSelectorPosition[msg.sig].beaconAddress).implementation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
// EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535

import {IDiamond} from "src/interfaces/diamond/IDiamond.sol";

interface IDiamondCut is IDiamond {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(IDiamond.BeaconCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
// EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Beacon {
        address beaconAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all beacon addresses and their four byte function selectors.
    /// @return beacons_ Beacon
    function beacons() external view returns (Beacon[] memory beacons_);

    /// @notice Gets all the function selectors supported by a specific beacon.
    /// @param _beacon The beacon address.
    /// @return beaconFunctionSelectors_
    function beaconFunctionSelectors(address _beacon)
        external
        view
        returns (bytes4[] memory beaconFunctionSelectors_);

    /// @notice Get all the beacon addresses used by a diamond.
    /// @return beaconAddresses_
    function beaconAddresses() external view returns (address[] memory beaconAddresses_);

    /// @notice Gets the beacon that supports the given selector.
    /// @dev If beacon is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return beaconAddress_ The beacon address.
    function beaconAddress(bytes4 _functionSelector) external view returns (address beaconAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
// EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535

interface IDiamond {
    enum BeaconCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct BeaconCut {
        address beaconAddress;
        BeaconCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(BeaconCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}