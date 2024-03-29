// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "LibStorage.sol";
import "LibDiamond.sol";
import {InvalidConfig} from "GenericErrors.sol";

/// @title Dex Manager Facet
/// @notice Facet contract for managing approved DEXs to be used in swaps.
contract DexManagerFacet {
    /// Events ///

    event DexAdded(address indexed dexAddress);
    event DexRemoved(address indexed dexAddress);
    event FunctionSignatureApprovalChanged(
        bytes32 indexed functionSignature,
        bool indexed approved
    );
    event GatewaySoFeeSelectorsChanged(
        address indexed gatewayAddress,
        address indexed soFeeAddress
    );
    event CorrectSwapRouterSelectorsChanged(address indexed correctSwap);

    /// Storage ///

    LibStorage internal appStorage;

    /// External Methods ///

    /// @notice  Register the soFee address for facet.
    /// @param gateway The address of the gateway facet address.
    /// @param soFee The address of soFee address.
    function addFee(address gateway, address soFee) external {
        LibDiamond.enforceIsContractOwner();
        mapping(address => address) storage gatewaySoFeeSelectors = appStorage
            .gatewaySoFeeSelectors;
        gatewaySoFeeSelectors[gateway] = soFee;
        emit GatewaySoFeeSelectorsChanged(gateway, soFee);
    }

    /// @notice Register the correct swap impl address for different swap router
    /// @param correctSwap address that implement the modification of this swap
    function addCorrectSwap(address correctSwap) external {
        LibDiamond.enforceIsContractOwner();
        appStorage.correctSwapRouterSelectors = correctSwap;
        emit CorrectSwapRouterSelectorsChanged(correctSwap);
    }

    /// @notice Register the address of a DEX contract to be approved for swapping.
    /// @param dex The address of the DEX contract to be approved.
    function addDex(address dex) external {
        LibDiamond.enforceIsContractOwner();
        _checkAddress(dex);

        mapping(address => bool) storage dexAllowlist = appStorage.dexAllowlist;
        if (dexAllowlist[dex]) return;

        dexAllowlist[dex] = true;
        appStorage.dexs.push(dex);
        emit DexAdded(dex);
    }

    /// @notice Batch register the addresss of DEX contracts to be approved for swapping.
    /// @param dexs The addresses of the DEX contracts to be approved.
    function batchAddDex(address[] calldata dexs) external {
        LibDiamond.enforceIsContractOwner();
        mapping(address => bool) storage dexAllowlist = appStorage.dexAllowlist;
        uint256 length = dexs.length;

        for (uint256 i = 0; i < length; i++) {
            _checkAddress(dexs[i]);
            if (dexAllowlist[dexs[i]]) continue;
            dexAllowlist[dexs[i]] = true;
            appStorage.dexs.push(dexs[i]);
            emit DexAdded(dexs[i]);
        }
    }

    /// @notice Unregister the address of a DEX contract approved for swapping.
    /// @param dex The address of the DEX contract to be unregistered.
    function removeDex(address dex) external {
        LibDiamond.enforceIsContractOwner();
        _checkAddress(dex);

        mapping(address => bool) storage dexAllowlist = appStorage.dexAllowlist;
        address[] storage storageDexes = appStorage.dexs;

        if (!dexAllowlist[dex]) {
            return;
        }
        dexAllowlist[dex] = false;

        uint256 length = storageDexes.length;
        for (uint256 i = 0; i < length; i++) {
            if (storageDexes[i] == dex) {
                _removeDex(i);
                return;
            }
        }
    }

    /// @notice Batch unregister the addresses of DEX contracts approved for swapping.
    /// @param dexs The addresses of the DEX contracts to be unregistered.
    function batchRemoveDex(address[] calldata dexs) external {
        LibDiamond.enforceIsContractOwner();
        mapping(address => bool) storage dexAllowlist = appStorage.dexAllowlist;
        address[] storage storageDexes = appStorage.dexs;

        uint256 ilength = dexs.length;
        uint256 jlength = storageDexes.length;
        for (uint256 i = 0; i < ilength; i++) {
            _checkAddress(dexs[i]);
            if (!dexAllowlist[dexs[i]]) {
                continue;
            }
            dexAllowlist[dexs[i]] = false;
            for (uint256 j = 0; j < jlength; j++) {
                if (storageDexes[j] == dexs[i]) {
                    _removeDex(j);
                    jlength = storageDexes.length;
                    break;
                }
            }
        }
    }

    /// @notice Adds/removes a specific function signature to/from the allowlist
    /// @param signature the function signature to allow/disallow
    /// @param approval whether the function signature should be allowed
    function setFunctionApprovalBySignature(bytes32 signature, bool approval)
        external
    {
        LibDiamond.enforceIsContractOwner();
        appStorage.dexFuncSignatureAllowList[signature] = approval;
        emit FunctionSignatureApprovalChanged(signature, approval);
    }

    /// @notice Batch Adds/removes a specific function signature to/from the allowlist
    /// @param signatures the function signatures to allow/disallow
    /// @param approval whether the function signatures should be allowed
    function batchSetFunctionApprovalBySignature(
        bytes32[] calldata signatures,
        bool approval
    ) external {
        LibDiamond.enforceIsContractOwner();
        mapping(bytes32 => bool) storage dexFuncSignatureAllowList = appStorage
            .dexFuncSignatureAllowList;
        uint256 length = signatures.length;
        for (uint256 i = 0; i < length; i++) {
            bytes32 signature = signatures[i];
            dexFuncSignatureAllowList[signature] = approval;
            emit FunctionSignatureApprovalChanged(signature, approval);
        }
    }

    /// @notice Returns whether a function signature is approved
    /// @param signature the function signature to query
    /// @return approved Approved or not
    function isFunctionApproved(bytes32 signature)
        public
        view
        returns (bool approved)
    {
        return appStorage.dexFuncSignatureAllowList[signature];
    }

    /// @notice Returns a list of all approved DEX addresses.
    /// @return addresses List of approved DEX addresses
    function approvedDexs() external view returns (address[] memory addresses) {
        return appStorage.dexs;
    }

    /// Private Methods ///

    /// @dev Contains business logic for removing a DEX address.
    /// @param index index of the dex to remove
    function _removeDex(uint256 index) private {
        address[] storage storageDexes = appStorage.dexs;
        address toRemove = storageDexes[index];
        // Move the last element into the place to delete
        storageDexes[index] = storageDexes[storageDexes.length - 1];
        // Remove the last element
        storageDexes.pop();
        emit DexRemoved(toRemove);
    }

    /// @dev Contains business logic for validating a DEX address.
    /// @param dex address of the dex to check
    function _checkAddress(address dex) private pure {
        if (dex == 0x0000000000000000000000000000000000000000) {
            revert InvalidConfig();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct LibStorage {
    mapping(address => bool) dexAllowlist;
    mapping(bytes32 => bool) dexFuncSignatureAllowList;
    address[] dexs;
    // maps gateway facet addresses to sofee address
    mapping(address => address) gatewaySoFeeSelectors;
    // Storage correct swap address
    address correctSwapRouterSelectors;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IDiamondCut} from "IDiamondCut.sol";

library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

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
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

error InvalidAmount(); // 0x2c5211c6
error TokenAddressIsZero(); // 0xdc2e5e8d
error CannotBridgeToSameNetwork(); // 0x4ac09ad3
error ZeroPostSwapBalance(); // 0xf74e8909
error InvalidBridgeConfigLength(); // 0x10502ef9
error NoSwapDataProvided(); // 0x0503c3ed
error NotSupportedSwapRouter(); // 0xe986f686
error NativeValueWithERC(); // 0x003f45b5
error ContractCallNotAllowed(); // 0x94539804
error NullAddrIsNotAValidSpender(); // 0x63ba9bff
error NullAddrIsNotAnERC20Token(); // 0xd1bebf0c
error NoTransferToNullAddress(); // 0x21f74345
error NativeAssetTransferFailed(); // 0x5a046737
error InvalidContract(); // 0x6eefed20
error InvalidConfig(); // 0x35be3ac8